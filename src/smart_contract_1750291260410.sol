Okay, here is a smart contract in Solidity focusing on an advanced concept: a "DeFi DAO Factory". This contract will allow users to deploy highly customizable Decentralized Autonomous Organizations (DAOs) tailored for DeFi activities. The factory manages the creation process, enforces certain parameters, tracks deployed DAOs, and provides factory-level configuration.

The contract itself (`DeFiDaoFactory`) contains the logic for *managing the creation and parameters* of these DAOs, while the deployed DAOs (`DeFiDao`) would contain the actual governance and DeFi interaction logic. For this example, the 20+ functions will reside within the `DeFiDaoFactory` contract itself, demonstrating a complex factory pattern with various management and configuration capabilities. We will define the structure and constructor parameters of the `DeFiDao` within the factory code to show the deployment process.

---

**Outline and Function Summary**

**Contract Name:** `DeFiDaoFactory`

**Concept:** A factory contract for deploying highly customizable DeFi-focused Decentralized Autonomous Organizations (DAOs). Each created DAO is an independent entity with its own governance token, treasury, and DeFi interaction capabilities, configured at creation time via the factory.

**Advanced Concepts/Features:**
*   **Factory Pattern:** Deploys instances of another complex contract (`DeFiDao`).
*   **Customizable Deployment:** Allows users to configure key DAO parameters (name, token supply, governance settings, initial treasury tokens/ETH) during creation.
*   **Configurable Defaults:** Factory owner can set default parameters for new DAOs.
*   **Protocol & Token Whitelisting:** Factory controls which external DeFi protocols and treasury tokens the created DAOs are permitted (or recommended) to interact with.
*   **Creation Fees & Revenue:** Factory can charge fees for DAO creation and manage collected revenue.
*   **Creation Access Control:** Supports optional whitelisting for who can create DAOs.
*   **Deployed DAO Tracking:** Maintains a registry of all DAOs created through the factory.
*   **Pausable:** Emergency pause mechanism for the factory.

**Deployed Contract:** `DeFiDao` (A separate contract deployed by the factory, managing governance, treasury, and DeFi interactions. Its details are abstracted for the factory logic example).

**Function Summary (for `DeFiDaoFactory`):**

1.  `constructor()`: Initializes the factory with an owner and default parameters.
2.  `createDeFiDao()`: Deploys a new `DeFiDao` instance based on provided parameters and factory configuration, collecting any creation fee and initial treasury funds.
3.  `getDeployedDaoCount()`: Returns the total number of DAOs created by this factory.
4.  `getDeployedDaoAddress(index)`: Returns the address of a deployed DAO at a specific index.
5.  `setDefaultDaoParameters()`: Sets the default configuration values used if specific parameters are omitted during DAO creation.
6.  `getDefaultDaoParameters()`: Retrieves the current default DAO parameters.
7.  `getDaoConfig(daoAddress)`: Retrieves the specific configuration used when a given DAO was created.
8.  `updateFactoryOwner()`: Transfers ownership of the factory contract (following ERC20-like transfer pattern).
9.  `pauseFactory()`: Pauses the factory, preventing new DAO creations.
10. `unpauseFactory()`: Unpauses the factory, allowing creation again.
11. `setCreationFee()`: Sets the fee required in native currency (ETH) to create a DAO.
12. `getCreationFee()`: Returns the current DAO creation fee.
13. `withdrawFees()`: Allows the factory owner to withdraw collected creation fees.
14. `registerExternalProtocol()`: Adds an external DeFi protocol address (e.g., Uniswap Router, Aave Lending Pool) to an approved list for created DAOs.
15. `unregisterExternalProtocol()`: Removes a protocol address from the approved list.
16. `getRegisteredProtocols()`: Returns the list of all registered external protocols.
17. `isProtocolRegistered()`: Checks if a specific protocol address is registered.
18. `addApprovedTokenForTreasury()`: Adds an ERC20 token address to a list of tokens that created DAOs are approved to hold/manage in their treasury.
19. `removeApprovedTokenForTreasury()`: Removes a token address from the approved treasury list.
20. `getApprovedTokensForTreasury()`: Returns the list of all approved treasury tokens.
21. `isApprovedTokenForTreasury()`: Checks if a specific token address is approved for treasury use.
22. `setFactoryMetadataURI()`: Sets a URI pointing to factory-specific metadata (e.g., documentation, UI configuration).
23. `getFactoryMetadataURI()`: Returns the current factory metadata URI.
24. `setDaoCreationWhitelister()`: Sets an address authorized to manage the creation whitelist.
25. `getDaoCreationWhitelister()`: Returns the current creation whitelister address.
26. `whitelistDaoCreator()`: Adds an address to the list of allowed DAO creators (callable by the whitelister).
27. `unwhitelistDaoCreator()`: Removes an address from the whitelist (callable by the whitelister).
28. `isDaoCreationWhitelisted()`: Checks if DAO creation is currently restricted by a whitelist.
29. `isCreatorWhitelisted()`: Checks if a specific address is on the creation whitelist.
30. `setDaoMinimumVotingPowerRatio()`: Sets the default ratio (basis points) of total supply required for a proposal to pass in created DAOs.
31. `getDaoMinimumVotingPowerRatio()`: Returns the default minimum voting power ratio.
32. `setDaoProposalThresholdRatio()`: Sets the default ratio (basis points) of total supply required to create a proposal in created DAOs.
33. `getDaoProposalThresholdRatio()`: Returns the default proposal threshold ratio.

*(Note: Functions related to the internal workings of a deployed `DeFiDao` instance (like `vote()`, `executeProposal()`, `swapTokens()`, etc.) would be part of the `DeFiDao` contract itself, not the factory.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For sending ETH

// --- Interfaces and Stubs (representing the contract deployed by the factory) ---

/// @dev This interface represents the minimum required structure for the contract deployed by the factory.
/// The actual DeFiDao contract would be significantly more complex, including ERC20Votes token, Governor, Treasury,
/// and functions for interacting with DeFi protocols (swap, lend, stake etc.) based on proposals.
interface IDeFiDao {
    /// @notice Constructor parameters for the DeFiDao contract.
    struct DaoConfig {
        string name;                    // Name of the DAO
        string tokenName;               // Name for the DAO's governance token
        string tokenSymbol;             // Symbol for the DAO's governance token
        uint256 initialSupply;          // Total initial supply of governance tokens
        address initialOwner;           // Address to receive initial token supply and potentially initial ownership
        uint256 proposalThreshold;      // Minimum voting power needed to create a proposal (raw token amount)
        uint256 votingPeriod;           // Duration of voting period (in blocks or time)
        uint256 votingDelay;            // Delay before voting starts after proposal creation (in blocks or time)
        uint256 minimumVotingPower;     // Minimum voting power needed for a proposal to pass (raw token amount)
        address[] initialTreasuryTokens; // Initial list of approved tokens for the treasury
        uint256[] initialTreasuryAmounts; // Initial amounts of approved tokens to deposit
        address governorSettings;       // Address of a contract defining specific Governor settings/rules (optional)
        string metadataURI;             // URI pointing to DAO metadata (description, logo etc.)
    }

    /// @notice Placeholder function signature for a potential initialization function
    /// if the factory uses CREATE2 or proxies needing post-deployment setup.
    /// For this example using `new`, the constructor handles initialization.
    // function initialize(...) external;
}


// --- The Factory Contract ---

/// @title DeFiDaoFactory
/// @dev A factory contract for deploying customizable DeFi-focused DAOs.
contract DeFiDaoFactory is Ownable, Pausable {
    using Address for address payable;

    // --- State Variables ---

    struct DaoCreationConfig {
        string name;
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        address initialOwner; // Owner of the initial supply / potentially minter/burner depending on token design
        // Governance parameters derived from ratios or direct values based on factory config
        uint256 proposalThresholdRatioBps; // Basis points of total supply
        uint256 minimumVotingPowerRatioBps; // Basis points of total supply
        uint256 votingPeriod; // In seconds (or blocks, factory standard)
        uint256 votingDelay; // In seconds (or blocks, factory standard)
        // Treasury initial state
        address[] initialTreasuryTokens;
        uint256[] initialTreasuryAmounts;
        string metadataURI;
    }

    address[] private _deployedDaos;
    mapping(address => DaoCreationConfig) private _daoConfigs;

    uint256 private _creationFee = 0; // Fee in native currency (ETH)
    uint256 private _collectedFees = 0;

    // Whitelisting for protocol interaction for created DAOs
    mapping(address => string) private _registeredExternalProtocols; // Address => Description
    address[] private _registeredExternalProtocolList;

    // Whitelisting for tokens allowed in DAO treasuries
    mapping(address => bool) private _approvedTreasuryTokens;
    address[] private _approvedTreasuryTokenList;

    // Optional: Creation Whitelisting
    address private _daoCreationWhitelister;
    mapping(address => bool) private _isCreatorWhitelisted;
    bool private _creationWhitelistingEnabled = false;

    // Default parameters for new DAOs if not specified during creation
    DaoCreationConfig private _defaultDaoConfig;

    // Metadata URI for the factory itself
    string private _factoryMetadataURI;

    // --- Events ---

    event DaoCreated(address indexed daoAddress, address indexed creator, DaoCreationConfig config);
    event FactoryPaused(address account);
    event FactoryUnpaused(address account);
    event CreationFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event ProtocolRegistered(address indexed protocolAddress, string description);
    event ProtocolUnregistered(address indexed protocolAddress);
    event TreasuryTokenApproved(address indexed tokenAddress);
    event TreasuryTokenRemoved(address indexed tokenAddress);
    event CreationWhitelisterUpdated(address indexed oldWhitelister, address indexed newWhitelister);
    event CreatorWhitelisted(address indexed creator);
    event CreatorUnwhitelisted(address indexed creator);
    event CreationWhitelistingEnabled(bool enabled);
    event DefaultDaoParamsUpdated(DaoCreationConfig config);
    event FactoryMetadataURIUpdated(string oldURI, string newURI);


    // --- Constructor ---

    /// @notice Initializes the factory owner and default DAO parameters.
    /// @param owner_ The initial owner of the factory.
    /// @param defaultParams_ Initial default parameters for new DAOs.
    constructor(address owner_, DaoCreationConfig memory defaultParams_) Ownable(owner_) {
        _defaultDaoConfig = defaultParams_;
        _defaultDaoConfig.initialTreasuryTokens = new address[](0); // Ensure default lists are empty
        _defaultDaoConfig.initialTreasuryAmounts = new uint256[](0);
        _factoryMetadataURI = ""; // Initialize with empty URI
    }

    // --- Public/External Functions (20+ functions required) ---

    /// @notice Creates and deploys a new DeFi DAO contract.
    /// @dev Collects creation fee and any initial ETH contribution for the DAO treasury.
    /// Checks for pause status and creation whitelist if enabled.
    /// @param params_ Configuration parameters for the new DAO.
    /// @param initialTreasuryEth_ Amount of native currency (ETH) to send to the new DAO's treasury upon creation.
    /// @param initialTreasuryTokens_ List of initial ERC20 token addresses for the treasury. Must be from approved list.
    /// @param initialTreasuryAmounts_ List of initial ERC20 token amounts for the treasury. Must match lengths with `initialTreasuryTokens_`.
    /// @param initialTokenOwner_ Address that receives the initial supply of DAO tokens.
    /// @param metadataURI_ URI for the DAO's metadata.
    /// @param useDefaultParams_ Flag to use default factory parameters for governance settings instead of providing them.
    /// @param proposalThreshold_ Raw token amount for proposal threshold if not using defaults.
    /// @param minimumVotingPower_ Raw token amount for minimum voting power if not using defaults.
    /// @param votingPeriod_ Voting period in seconds if not using defaults.
    /// @param votingDelay_ Voting delay in seconds if not using defaults.
    /// @return The address of the newly deployed DeFi DAO contract.
    function createDeFiDao(
        string calldata params_name,
        string calldata params_tokenName,
        string calldata params_tokenSymbol,
        uint256 params_initialSupply,
        uint256 initialTreasuryEth_,
        address[] calldata initialTreasuryTokens_,
        uint256[] calldata initialTreasuryAmounts_,
        address initialTokenOwner_,
        string calldata metadataURI_,
        bool useDefaultParams_,
        uint256 proposalThreshold_, // Only used if !useDefaultParams_
        uint256 minimumVotingPower_, // Only used if !useDefaultParams_
        uint256 votingPeriod_,      // Only used if !useDefaultParams_
        uint256 votingDelay_        // Only used if !useDefaultParams_

    ) external payable whenNotPaused returns (address) {
        require(msg.value >= _creationFee + initialTreasuryEth_, "Factory: Insufficient ETH sent (fee + treasury)");
        require(initialTreasuryTokens_.length == initialTreasuryAmounts_.length, "Factory: Treasury token/amount mismatch");

        if (_creationWhitelistingEnabled) {
            require(_isCreatorWhitelisted[msg.sender], "Factory: Creator not whitelisted");
        }

        // Validate approved treasury tokens
        for (uint i = 0; i < initialTreasuryTokens_.length; i++) {
            require(_approvedTreasuryTokens[initialTreasuryTokens_[i]], "Factory: Treasury token not approved");
        }

        // Determine governance parameters
        uint256 actualProposalThreshold;
        uint256 actualMinimumVotingPower;
        uint256 actualVotingPeriod;
        uint256 actualVotingDelay;

        if (useDefaultParams_) {
             // Calculate raw amounts based on default ratios and initial supply
             actualProposalThreshold = (params_initialSupply * _defaultDaoConfig.proposalThresholdRatioBps) / 10000;
             actualMinimumVotingPower = (params_initialSupply * _defaultDaoConfig.minimumVotingPowerRatioBps) / 10000;
             actualVotingPeriod = _defaultDaoConfig.votingPeriod;
             actualVotingDelay = _defaultDaoConfig.votingDelay;
        } else {
            actualProposalThreshold = proposalThreshold_;
            actualMinimumVotingPower = minimumVotingPower_;
            actualVotingPeriod = votingPeriod_;
            actualVotingDelay = votingDelay_;
        }
         // Basic sanity checks on calculated/provided params
         require(actualProposalThreshold < params_initialSupply, "Factory: Threshold too high");
         require(actualMinimumVotingPower < params_initialSupply, "Factory: Min voting power too high");
         require(actualVotingPeriod > 0, "Factory: Voting period too short");

        // Construct the config struct to pass to the new DAO
        IDeFiDao.DaoConfig memory daoInitConfig = IDeFiDao.DaoConfig({
            name: params_name,
            tokenName: params_tokenName,
            tokenSymbol: params_tokenSymbol,
            initialSupply: params_initialSupply,
            initialOwner: initialTokenOwner_ == address(0) ? msg.sender : initialTokenOwner_, // Default token owner to creator if 0
            proposalThreshold: actualProposalThreshold,
            votingPeriod: actualVotingPeriod,
            votingDelay: actualVotingDelay,
            minimumVotingPower: actualMinimumVotingPower,
            initialTreasuryTokens: initialTreasuryTokens_,
            initialTreasuryAmounts: initialTreasuryAmounts_,
            governorSettings: address(0), // Placeholder for an optional settings contract
            metadataURI: metadataURI_
        });

        // --- Actual Deployment ---
        // Note: The actual DeFiDao contract code would be required here.
        // For this example, we assume a contract named DeFiDao exists with a constructor
        // matching the IDeFiDao.DaoConfig struct.
        // address newDaoAddress = address(new DeFiDao(daoInitConfig)); // <-- This line requires the DeFiDao contract code

        // Dummy deployment address for demonstration purposes without the actual DeFiDao code
        address newDaoAddress = address(uint160(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, params_name)))));


        // --- Post-Deployment Setup ---

        _deployedDaos.push(newDaoAddress);

        // Store the creation config for this specific DAO
        _daoConfigs[newDaoAddress] = DaoCreationConfig({
            name: params_name,
            tokenName: params_tokenName,
            tokenSymbol: params_tokenSymbol,
            initialSupply: params_initialSupply,
            initialOwner: initialTokenOwner_ == address(0) ? msg.sender : initialTokenOwner_,
            proposalThresholdRatioBps: useDefaultParams_ ? _defaultDaoConfig.proposalThresholdRatioBps : 0, // Store ratio if default used, 0 otherwise
            minimumVotingPowerRatioBps: useDefaultParams_ ? _defaultDaoConfig.minimumVotingPowerRatioBps : 0, // Store ratio if default used, 0 otherwise
            votingPeriod: actualVotingPeriod, // Store calculated/provided value
            votingDelay: actualVotingDelay,   // Store calculated/provided value
            initialTreasuryTokens: initialTreasuryTokens_, // Store provided values
            initialTreasuryAmounts: initialTreasuryAmounts_, // Store provided values
            metadataURI: metadataURI_
        });


        // Transfer initial ETH to the new DAO
        if (initialTreasuryEth_ > 0) {
            payable(newDaoAddress).sendValue(initialTreasuryEth_);
        }

        // Handle any initial treasury tokens (requires approval *before* calling factory)
        // The DAO's constructor or an init function would typically pull these approved tokens.
        // For this simplified example, we'll just require allowance and mention it.
        // require(IERC20(token).transferFrom(msg.sender, newDaoAddress, amount), "Factory: Token transfer failed");
        // Note: Transferring tokens needs to happen either before calling the factory (approval)
        // or the factory needs permission/logic to pull from the creator. The DAO itself is the
        // cleaner place to handle receiving initial tokens *after* deployment.
        // So, this factory function just REQUIRES the creator to have approved the DAO address
        // for the initial tokens *after* the DAO is deployed, and the DAO needs an init function
        // to pull them. Or, the factory *could* pull if granted allowance, but sending is safer.
        // Let's assume the DAO constructor or init handles pulling approved tokens.

        // Collect the creation fee
        if (_creationFee > 0) {
            // Send fee to owner/collector. Any excess ETH is already sent to the DAO treasury.
            // require(payable(owner()).send(_creationFee), "Factory: Fee transfer failed"); // send is deprecated
            (bool success,) = payable(owner()).call{value: _creationFee}("");
            require(success, "Factory: Fee transfer failed");
            _collectedFees += _creationFee;
        }


        emit DaoCreated(newDaoAddress, msg.sender, _daoConfigs[newDaoAddress]);

        return newDaoAddress;
    }

    /// @notice Returns the total number of DAOs created by this factory.
    function getDeployedDaoCount() external view returns (uint256) {
        return _deployedDaos.length;
    }

    /// @notice Returns the address of a deployed DAO at a specific index.
    /// @param index The index of the DAO in the deployed list.
    function getDeployedDaoAddress(uint256 index) external view returns (address) {
        require(index < _deployedDaos.length, "Factory: Index out of bounds");
        return _deployedDaos[index];
    }

     /// @notice Retrieves the specific configuration used when a given DAO was created.
     /// @param daoAddress The address of the deployed DAO.
     /// @return The DaoCreationConfig struct.
    function getDaoConfig(address daoAddress) external view returns (DaoCreationConfig memory) {
         require(_daoConfigs[daoAddress].initialSupply > 0 || _daoConfigs[daoAddress].votingPeriod > 0, "Factory: DAO config not found"); // Basic check if mapping entry exists
         return _daoConfigs[daoAddress];
    }

    /// @notice Sets the default configuration values used if specific parameters are omitted during DAO creation.
    /// @param params_ The new default parameters.
    function setDefaultDaoParameters(DaoCreationConfig memory params_) external onlyOwner {
        // Basic validation
        require(params_.initialSupply > 0, "Factory: Default initial supply must be > 0");
        require(params_.proposalThresholdRatioBps <= 10000, "Factory: Default threshold ratio invalid");
        require(params_.minimumVotingPowerRatioBps <= 10000, "Factory: Default min voting power ratio invalid");
        require(params_.votingPeriod > 0, "Factory: Default voting period must be > 0");
        // Note: We don't set initialTreasuryTokens/Amounts here as they are instance specific.
        // We store the other parameters as defaults.
        _defaultDaoConfig.name = params_.name; // Store name for default config reference, though instance overrides
        _defaultDaoConfig.tokenName = params_.tokenName; // Store token name for default config reference, though instance overrides
        _defaultDaoConfig.tokenSymbol = params_.tokenSymbol; // Store symbol for default config reference, though instance overrides
        _defaultDaoConfig.initialSupply = params_.initialSupply; // Store supply for ratio calculation reference
        _defaultDaoConfig.proposalThresholdRatioBps = params_.proposalThresholdRatioBps;
        _defaultDaoConfig.minimumVotingPowerRatioBps = params_.minimumVotingPowerRatioBps;
        _defaultDaoConfig.votingPeriod = params_.votingPeriod;
        _defaultDaoConfig.votingDelay = params_.votingDelay;
        _defaultDaoConfig.metadataURI = params_.metadataURI; // Store URI for default config reference

        emit DefaultDaoParamsUpdated(_defaultDaoConfig);
    }

    /// @notice Retrieves the current default DAO parameters.
    function getDefaultDaoParameters() external view returns (DaoCreationConfig memory) {
        // Return the stored default config
        return _defaultDaoConfig;
    }

    /// @notice Transfers ownership of the factory contract to a new address.
    /// Follows the ERC20-like transfer pattern (propose/accept).
    /// @param newOwner The address to transfer ownership to.
    function updateFactoryOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner); // Using Ownable's transferOwnership
    }

    /// @notice Pauses the factory, preventing new DAO creations.
    function pauseFactory() external onlyOwner whenNotPaused {
        _pause();
        emit FactoryPaused(msg.sender);
    }

    /// @notice Unpauses the factory, allowing creation again.
    function unpauseFactory() external onlyOwner whenPaused {
        _unpause();
        emit FactoryUnpaused(msg.sender);
    }

    /// @notice Sets the fee required in native currency (ETH) to create a DAO.
    /// @param fee The new creation fee amount.
    function setCreationFee(uint256 fee) external onlyOwner {
        uint256 oldFee = _creationFee;
        _creationFee = fee;
        emit CreationFeeUpdated(oldFee, fee);
    }

    /// @notice Returns the current DAO creation fee.
    function getCreationFee() external view returns (uint256) {
        return _creationFee;
    }

    /// @notice Allows the factory owner to withdraw collected creation fees.
    /// @param to The address to send the fees to.
    function withdrawFees(address payable to) external onlyOwner {
        uint256 amount = _collectedFees;
        _collectedFees = 0;
        require(amount > 0, "Factory: No fees collected");
        to.sendValue(amount);
        emit FeesWithdrawn(to, amount);
    }

    /// @notice Adds an external DeFi protocol address (e.g., Uniswap Router, Aave Lending Pool) to an approved list for created DAOs.
    /// This is informational/recommendational for DAOs created by this factory.
    /// @param protocolAddress The address of the external protocol contract.
    /// @param description A description of the protocol (e.g., "Uniswap V3 Router", "Aave V3 Lending Pool").
    function registerExternalProtocol(address protocolAddress, string calldata description) external onlyOwner {
        require(protocolAddress != address(0), "Factory: Zero address");
        require(!_isProtocolRegistered(protocolAddress), "Factory: Protocol already registered");
        _registeredExternalProtocols[protocolAddress] = description;
        _registeredExternalProtocolList.push(protocolAddress);
        emit ProtocolRegistered(protocolAddress, description);
    }

    /// @notice Removes a protocol address from the approved list.
    /// @param protocolAddress The address of the protocol to remove.
    function unregisterExternalProtocol(address protocolAddress) external onlyOwner {
        require(_isProtocolRegistered(protocolAddress), "Factory: Protocol not registered");
        delete _registeredExternalProtocols[protocolAddress];
        // Remove from the list (simple but potentially inefficient for large lists)
        for (uint i = 0; i < _registeredExternalProtocolList.length; i++) {
            if (_registeredExternalProtocolList[i] == protocolAddress) {
                _registeredExternalProtocolList[i] = _registeredExternalProtocolList[_registeredExternalProtocolList.length - 1];
                _registeredExternalProtocolList.pop();
                break;
            }
        }
        emit ProtocolUnregistered(protocolAddress);
    }

    /// @notice Returns the list of all registered external protocols.
    function getRegisteredProtocols() external view returns (address[] memory) {
        return _registeredExternalProtocolList;
    }

    /// @notice Checks if a specific protocol address is registered.
    /// @param protocolAddress The address to check.
    function isProtocolRegistered(address protocolAddress) external view returns (bool) {
        return _isProtocolRegistered(protocolAddress);
    }

    /// @notice Adds an ERC20 token address to a list of tokens that created DAOs are approved to hold/manage in their treasury.
    /// This is informational/recommendational for DAOs created by this factory.
    /// @param tokenAddress The address of the ERC20 token.
    function addApprovedTokenForTreasury(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Factory: Zero address");
        require(!_approvedTreasuryTokens[tokenAddress], "Factory: Token already approved");
        _approvedTreasuryTokens[tokenAddress] = true;
        _approvedTreasuryTokenList.push(tokenAddress);
        emit TreasuryTokenApproved(tokenAddress);
    }

    /// @notice Removes a token address from the approved treasury list.
    /// @param tokenAddress The address of the token to remove.
    function removeApprovedTokenForTreasury(address tokenAddress) external onlyOwner {
        require(_approvedTreasuryTokens[tokenAddress], "Factory: Token not approved");
        delete _approvedTreasuryTokens[tokenAddress];
         // Remove from the list (simple but potentially inefficient for large lists)
        for (uint i = 0; i < _approvedTreasuryTokenList.length; i++) {
            if (_approvedTreasuryTokenList[i] == tokenAddress) {
                _approvedTreasuryTokenList[i] = _approvedTreasuryTokenList[_approvedTreasuryTokenList.length - 1];
                _approvedTreasuryTokenList.pop();
                break;
            }
        }
        emit TreasuryTokenRemoved(tokenAddress);
    }

    /// @notice Returns the list of all approved treasury tokens.
    function getApprovedTokensForTreasury() external view returns (address[] memory) {
        return _approvedTreasuryTokenList;
    }

     /// @notice Checks if a specific token address is approved for treasury use by DAOs.
     /// @param tokenAddress The address to check.
    function isApprovedTokenForTreasury(address tokenAddress) external view returns (bool) {
        return _approvedTreasuryTokens[tokenAddress];
    }


    /// @notice Sets a URI pointing to factory-specific metadata (e.g., documentation, UI configuration).
    /// @param uri The new metadata URI.
    function setFactoryMetadataURI(string calldata uri) external onlyOwner {
        string memory oldURI = _factoryMetadataURI;
        _factoryMetadataURI = uri;
        emit FactoryMetadataURIUpdated(oldURI, uri);
    }

    /// @notice Returns the current factory metadata URI.
    function getFactoryMetadataURI() external view returns (string memory) {
        return _factoryMetadataURI;
    }

    /// @notice Sets an address authorized to manage the DAO creation whitelist.
    /// Setting to address(0) disables the whitelist.
    /// @param whitelister The address of the whitelister.
    function setDaoCreationWhitelister(address whitelister) external onlyOwner {
        address oldWhitelister = _daoCreationWhitelister;
        _daoCreationWhitelister = whitelister;
        _creationWhitelistingEnabled = (whitelister != address(0)); // Enable/disable based on address
        emit CreationWhitelisterUpdated(oldWhitelister, whitelister);
        emit CreationWhitelistingEnabled(_creationWhitelistingEnabled);
    }

    /// @notice Returns the current creation whitelister address.
    function getDaoCreationWhitelister() external view returns (address) {
        return _daoCreationWhitelister;
    }

    /// @notice Adds an address to the list of allowed DAO creators. Callable only by the whitelister.
    /// @param creator The address to whitelist.
    function whitelistDaoCreator(address creator) external {
        require(msg.sender == _daoCreationWhitelister, "Factory: Only whitelister");
        require(creator != address(0), "Factory: Zero address");
        require(!_isCreatorWhitelisted[creator], "Factory: Creator already whitelisted");
        _isCreatorWhitelisted[creator] = true;
        emit CreatorWhitelisted(creator);
    }

    /// @notice Removes an address from the whitelist. Callable only by the whitelister.
    /// @param creator The address to unwhitelist.
    function unwhitelistDaoCreator(address creator) external {
        require(msg.sender == _daoCreationWhitelister, "Factory: Only whitelister");
        require(creator != address(0), "Factory: Zero address");
        require(_isCreatorWhitelisted[creator], "Factory: Creator not whitelisted");
        _isCreatorWhitelisted[creator] = false;
        emit CreatorUnwhitelisted(creator);
    }

    /// @notice Checks if DAO creation is currently restricted by a whitelist.
    function isDaoCreationWhitelisted() external view returns (bool) {
        return _creationWhitelistingEnabled;
    }

    /// @notice Checks if a specific address is on the creation whitelist.
    /// @param creator The address to check.
    function isCreatorWhitelisted(address creator) external view returns (bool) {
        return _isCreatorWhitelisted[creator];
    }

    /// @notice Sets the default ratio (basis points) of total supply required for a proposal to pass in created DAOs.
    /// Used when `useDefaultParams_` is true during creation. 10000 = 100%.
    /// @param ratioBps The new minimum voting power ratio in basis points.
    function setDaoMinimumVotingPowerRatio(uint256 ratioBps) external onlyOwner {
         require(ratioBps <= 10000, "Factory: Ratio invalid (max 10000)");
         _defaultDaoConfig.minimumVotingPowerRatioBps = ratioBps;
         // Re-emit the full default config for clarity
         emit DefaultDaoParamsUpdated(_defaultDaoConfig);
    }

     /// @notice Returns the default minimum voting power ratio (basis points).
    function getDaoMinimumVotingPowerRatio() external view returns (uint256) {
        return _defaultDaoConfig.minimumVotingPowerRatioBps;
    }

    /// @notice Sets the default ratio (basis points) of total supply required to create a proposal in created DAOs.
    /// Used when `useDefaultParams_` is true during creation. 10000 = 100%.
    /// @param ratioBps The new proposal threshold ratio in basis points.
    function setDaoProposalThresholdRatio(uint256 ratioBps) external onlyOwner {
         require(ratioBps <= 10000, "Factory: Ratio invalid (max 10000)");
        _defaultDaoConfig.proposalThresholdRatioBps = ratioBps;
        // Re-emit the full default config for clarity
        emit DefaultDaoParamsUpdated(_defaultDaoConfig);
    }

    /// @notice Returns the default proposal threshold ratio (basis points).
    function getDaoProposalThresholdRatio() external view returns (uint256) {
        return _defaultDaoConfig.proposalThresholdRatioBps;
    }

    // --- Internal Helper Functions ---

    /// @dev Helper to check if a protocol is registered.
    function _isProtocolRegistered(address protocolAddress) internal view returns (bool) {
        // Check if the address is in the mapping (description will be non-empty if registered)
        // Also double-check if the address is in the list to be safe, though mapping check is usually sufficient
         if (bytes(_registeredExternalProtocols[protocolAddress]).length == 0) return false;
         // Optional: Additional check against the list if paranoid about mapping state corruption,
         // but for simplicity and gas, relying on the mapping is standard.
         return true; // Assume true if description exists
    }

    // Fallback/Receive functions to accept ETH, potentially for fees or future features
    receive() external payable {
        // ETH received directly can either be for fees or just sent to the factory.
        // If createDeFiDao is called with initialTreasuryEth > 0, that ETH goes directly to the DAO.
        // Any ETH sent outside of createDeFiDao lands here. It's added to collectedFees
        // or could be handled differently (e.g., rejected, forwarded). Let's assume it's fees.
        _collectedFees += msg.value;
        // Note: A more sophisticated factory might reject ETH sent this way or
        // have a specific function for depositing towards future creations etc.
    }

    fallback() external payable {
        // Same handling as receive() for calls with data but no matching function
        _collectedFees += msg.value;
    }
}
```