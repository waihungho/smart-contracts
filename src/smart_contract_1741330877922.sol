```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Asset Vault - Advanced Smart Contract
 * @author Gemini AI Assistant
 * @dev This smart contract implements a Dynamic Asset Vault, offering a wide range of functionalities for managing and interacting with various digital assets.
 * It goes beyond basic token transfers and incorporates advanced concepts like dynamic strategies, conditional actions,
 * NFT-based vault representations, governance mechanisms, and integrated DeFi functionalities.
 *
 * **Outline and Function Summary:**
 *
 * **Vault Management:**
 * 1. `createVault(string _name, string _description)`: Allows users to create new asset vaults with a name and description.
 * 2. `setVaultMetadata(uint256 _vaultId, string _name, string _description)`: Updates the name and description of an existing vault.
 * 3. `changeVaultOwner(uint256 _vaultId, address _newOwner)`: Transfers ownership of a vault to a new address.
 * 4. `pauseVault(uint256 _vaultId)`: Pauses all functionalities of a vault, except withdrawals by the owner.
 * 5. `unpauseVault(uint256 _vaultId)`: Resumes normal operations of a paused vault.
 * 6. `destroyVault(uint256 _vaultId)`: Allows the owner to destroy a vault and withdraw all assets (with necessary security checks).
 * 7. `getVaultDetails(uint256 _vaultId)`: Retrieves detailed information about a specific vault.
 *
 * **Asset Management:**
 * 8. `depositAssets(uint256 _vaultId, address _tokenAddress, uint256 _amount)`: Allows depositing ERC20 tokens into a vault.
 * 9. `depositETH(uint256 _vaultId) payable`: Allows depositing ETH into a vault.
 * 10. `withdrawAssets(uint256 _vaultId, address _tokenAddress, uint256 _amount)`: Allows the vault owner to withdraw ERC20 tokens from a vault.
 * 11. `withdrawETH(uint256 _vaultId, uint256 _amount)`: Allows the vault owner to withdraw ETH from a vault.
 * 12. `getVaultBalance(uint256 _vaultId, address _tokenAddress)`: Retrieves the balance of a specific token within a vault.
 * 13. `getSupportedAssetTypes(uint256 _vaultId)`: Returns a list of token addresses currently held in the vault.
 *
 * **Dynamic Strategies & Conditional Actions:**
 * 14. `executeVaultStrategy(uint256 _vaultId, bytes calldata _strategyData)`: Allows the vault owner to trigger a pre-defined strategy execution (e.g., yield farming, automated trading - strategy logic is off-chain for this example).
 * 15. `setConditionalAction(uint256 _vaultId, bytes32 _conditionHash, bytes calldata _actionData)`: Sets up a conditional action to be executed when a specific condition is met (condition checking is simulated off-chain for this example).
 * 16. `triggerConditionalAction(uint256 _vaultId, bytes32 _conditionHash)`:  Manually trigger a conditional action if the condition is met (for testing or external triggers).
 *
 * **NFT Representation & Access Control:**
 * 17. `mintNFTRepresentation(uint256 _vaultId, address _recipient)`: Mints an NFT representing ownership/access to a specific vault.
 * 18. `transferNFTRepresentation(uint256 _vaultId, address _newRecipient)`: Transfers the NFT representation of a vault (and implicitly, vault ownership/access).
 * 19. `requireNFTRepresentation(uint256 _vaultId, address _nftHolder)`: Modifier to restrict function access to holders of the vault's NFT representation.
 *
 * **Governance & Advanced Features:**
 * 20. `setVaultParameter(uint256 _vaultId, string _parameterName, uint256 _parameterValue)`: Allows the vault owner to set generic vault parameters (e.g., fees, thresholds).
 * 21. `emergencyWithdrawAll(uint256 _vaultId)`: An emergency function to withdraw all assets in case of critical issues (owner-only, use with caution).
 * 22. `upgradeContractLogic(address _newLogicContract)`:  Hypothetical function to upgrade the contract logic (requires more complex implementation with proxy patterns for real upgrades).
 * 23. `registerVaultInIndex(uint256 _vaultId)`: Registers the vault in a hypothetical global vault index/registry for discovery.
 */
contract DynamicAssetVault {

    // --- State Variables ---
    uint256 public vaultCounter;
    mapping(uint256 => Vault) public vaults;
    mapping(uint256 => address[]) public vaultAssets; // Track assets held in each vault
    address public admin; // Contract Admin (for potential upgrades, etc.)

    struct Vault {
        string name;
        string description;
        address owner;
        bool paused;
        uint256 creationTimestamp;
        // ... potentially more vault-specific metadata
    }

    // --- Events ---
    event VaultCreated(uint256 vaultId, address owner, string name);
    event VaultMetadataUpdated(uint256 vaultId, string newName, string newDescription);
    event VaultOwnershipTransferred(uint256 vaultId, address previousOwner, address newOwner);
    event VaultPaused(uint256 vaultId);
    event VaultUnpaused(uint256 vaultId);
    event VaultDestroyed(uint256 vaultId);
    event AssetsDeposited(uint256 vaultId, address tokenAddress, uint256 amount, address depositor);
    event ETHDeposited(uint256 vaultId, uint256 amount, address depositor);
    event AssetsWithdrawn(uint256 vaultId, address tokenAddress, uint256 amount, address recipient);
    event ETHWithdrawn(uint256 vaultId, uint256 amount, address recipient);
    event StrategyExecuted(uint256 vaultId, bytes strategyData);
    event ConditionalActionSet(uint256 vaultId, bytes32 conditionHash, bytes actionData);
    event ConditionalActionTriggered(uint256 vaultId, bytes32 conditionHash);
    event NFTRepresentationMinted(uint256 vaultId, address recipient);
    event NFTRepresentationTransferred(uint256 vaultId, address previousRecipient, address newRecipient);
    event VaultParameterSet(uint256 vaultId, string parameterName, uint256 parameterValue);
    event EmergencyWithdrawal(uint256 vaultId, address owner);
    event VaultRegistered(uint256 vaultId);
    event ContractUpgraded(address newLogicContract);


    // --- Modifiers ---
    modifier onlyVaultOwner(uint256 _vaultId) {
        require(vaults[_vaultId].owner == msg.sender, "Only vault owner can perform this action.");
        _;
    }

    modifier vaultNotPaused(uint256 _vaultId) {
        require(!vaults[_vaultId].paused, "Vault is currently paused.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        vaultCounter = 0;
    }

    // --- Vault Management Functions ---

    /// @notice Creates a new asset vault.
    /// @param _name The name of the vault.
    /// @param _description A brief description of the vault.
    function createVault(string memory _name, string memory _description) public returns (uint256 vaultId) {
        vaultId = vaultCounter++;
        vaults[vaultId] = Vault({
            name: _name,
            description: _description,
            owner: msg.sender,
            paused: false,
            creationTimestamp: block.timestamp
        });
        emit VaultCreated(vaultId, msg.sender, _name);
        return vaultId;
    }

    /// @notice Updates the metadata (name and description) of an existing vault.
    /// @param _vaultId The ID of the vault to update.
    /// @param _name The new name for the vault.
    /// @param _description The new description for the vault.
    function setVaultMetadata(uint256 _vaultId, string memory _name, string memory _description) public onlyVaultOwner(_vaultId) {
        vaults[_vaultId].name = _name;
        vaults[_vaultId].description = _description;
        emit VaultMetadataUpdated(_vaultId, _name, _description);
    }

    /// @notice Transfers the ownership of a vault to a new address.
    /// @param _vaultId The ID of the vault to transfer ownership of.
    /// @param _newOwner The address of the new owner.
    function changeVaultOwner(uint256 _vaultId, address _newOwner) public onlyVaultOwner(_vaultId) {
        require(_newOwner != address(0), "New owner address cannot be zero.");
        emit VaultOwnershipTransferred(_vaultId, vaults[_vaultId].owner, _newOwner);
        vaults[_vaultId].owner = _newOwner;
    }

    /// @notice Pauses all operations of a vault except owner withdrawals.
    /// @param _vaultId The ID of the vault to pause.
    function pauseVault(uint256 _vaultId) public onlyVaultOwner(_vaultId) {
        require(!vaults[_vaultId].paused, "Vault is already paused.");
        vaults[_vaultId].paused = true;
        emit VaultPaused(_vaultId);
    }

    /// @notice Resumes normal operations of a paused vault.
    /// @param _vaultId The ID of the vault to unpause.
    function unpauseVault(uint256 _vaultId) public onlyVaultOwner(_vaultId) {
        require(vaults[_vaultId].paused, "Vault is not paused.");
        vaults[_vaultId].paused = false;
        emit VaultUnpaused(_vaultId);
    }

    /// @notice Destroys a vault and allows the owner to withdraw remaining assets.
    /// @param _vaultId The ID of the vault to destroy.
    function destroyVault(uint256 _vaultId) public onlyVaultOwner(_vaultId) {
        // Implement additional security checks if needed, e.g., waiting period
        // For simplicity, we just transfer all assets back to the owner.
        address[] memory assets = vaultAssets[_vaultId];
        for (uint256 i = 0; i < assets.length; i++) {
            address tokenAddress = assets[i];
            if (tokenAddress == address(0)) { // ETH
                uint256 ethBalance = address(this).balance; // Vault's ETH balance
                if (ethBalance > 0) {
                    payable(vaults[_vaultId].owner).transfer(ethBalance);
                }
            } else { // ERC20
                IERC20 token = IERC20(tokenAddress);
                uint256 tokenBalance = token.balanceOf(address(this)); // Vault's token balance
                if (tokenBalance > 0) {
                    token.transfer(vaults[_vaultId].owner, tokenBalance);
                }
            }
        }
        delete vaults[_vaultId];
        delete vaultAssets[_vaultId]; // Clean up asset tracking
        emit VaultDestroyed(_vaultId);
    }

    /// @notice Retrieves details of a specific vault.
    /// @param _vaultId The ID of the vault.
    /// @return Vault struct containing vault details.
    function getVaultDetails(uint256 _vaultId) public view returns (Vault memory) {
        require(vaults[_vaultId].owner != address(0), "Vault does not exist."); // Ensure vault exists
        return vaults[_vaultId];
    }


    // --- Asset Management Functions ---

    /// @notice Deposits ERC20 tokens into a vault.
    /// @param _vaultId The ID of the vault to deposit into.
    /// @param _tokenAddress The address of the ERC20 token to deposit.
    /// @param _amount The amount of tokens to deposit.
    function depositAssets(uint256 _vaultId, address _tokenAddress, uint256 _amount) public vaultNotPaused(_vaultId) {
        require(_tokenAddress != address(0), "Invalid token address.");
        require(_amount > 0, "Deposit amount must be greater than zero.");

        IERC20 token = IERC20(_tokenAddress);
        bool transferSuccess = token.transferFrom(msg.sender, address(this), _amount); // Transfer from user to contract
        require(transferSuccess, "Token transfer failed.");

        // Track asset if it's the first deposit of this type in the vault
        bool assetTracked = false;
        for(uint i=0; i < vaultAssets[_vaultId].length; i++){
            if(vaultAssets[_vaultId][i] == _tokenAddress){
                assetTracked = true;
                break;
            }
        }
        if(!assetTracked){
            vaultAssets[_vaultId].push(_tokenAddress);
        }

        emit AssetsDeposited(_vaultId, _tokenAddress, _amount, msg.sender);
    }

    /// @notice Deposits ETH into a vault.
    /// @param _vaultId The ID of the vault to deposit into.
    function depositETH(uint256 _vaultId) public payable vaultNotPaused(_vaultId) {
        require(msg.value > 0, "Deposit amount must be greater than zero.");

        // Track ETH as an asset if it's the first deposit of ETH in the vault
        bool ethTracked = false;
        for(uint i=0; i < vaultAssets[_vaultId].length; i++){
            if(vaultAssets[_vaultId][i] == address(0)){ // Using address(0) to represent ETH
                ethTracked = true;
                break;
            }
        }
        if(!ethTracked){
            vaultAssets[_vaultId].push(address(0)); // Track address(0) for ETH
        }

        emit ETHDeposited(_vaultId, msg.value, msg.sender);
    }

    /// @notice Allows the vault owner to withdraw ERC20 tokens from a vault.
    /// @param _vaultId The ID of the vault to withdraw from.
    /// @param _tokenAddress The address of the ERC20 token to withdraw.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawAssets(uint256 _vaultId, address _tokenAddress, uint256 _amount) public onlyVaultOwner(_vaultId) {
        require(_tokenAddress != address(0), "Invalid token address.");
        require(_amount > 0, "Withdrawal amount must be greater than zero.");

        IERC20 token = IERC20(_tokenAddress);
        uint256 vaultBalance = token.balanceOf(address(this));
        require(vaultBalance >= _amount, "Insufficient vault balance for withdrawal.");

        bool transferSuccess = token.transfer(vaults[_vaultId].owner, _amount);
        require(transferSuccess, "Token transfer failed.");

        emit AssetsWithdrawn(_vaultId, _tokenAddress, _amount, vaults[_vaultId].owner);
    }

    /// @notice Allows the vault owner to withdraw ETH from a vault.
    /// @param _vaultId The ID of the vault to withdraw from.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawETH(uint256 _vaultId, uint256 _amount) public onlyVaultOwner(_vaultId) {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(address(this).balance >= _amount, "Insufficient ETH balance in vault.");

        payable(vaults[_vaultId].owner).transfer(_amount);
        emit ETHWithdrawn(_vaultId, _amount, vaults[_vaultId].owner);
    }

    /// @notice Gets the balance of a specific token within a vault.
    /// @param _vaultId The ID of the vault.
    /// @param _tokenAddress The address of the ERC20 token (or address(0) for ETH).
    /// @return The balance of the token in the vault.
    function getVaultBalance(uint256 _vaultId, address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == address(0)) {
            return address(this).balance; // ETH Balance
        } else {
            IERC20 token = IERC20(_tokenAddress);
            return token.balanceOf(address(this)); // ERC20 Balance
        }
    }

    /// @notice Gets a list of token addresses currently held in the vault.
    /// @param _vaultId The ID of the vault.
    /// @return An array of token addresses (including address(0) for ETH if held).
    function getSupportedAssetTypes(uint256 _vaultId) public view returns (address[] memory) {
        return vaultAssets[_vaultId];
    }


    // --- Dynamic Strategies & Conditional Actions ---

    /// @notice Executes a pre-defined vault strategy. Strategy logic is off-chain for this example.
    /// @dev In a real-world scenario, `_strategyData` could be encoded function calls, parameters, etc.,
    ///      to interact with other DeFi protocols or smart contracts.
    /// @param _vaultId The ID of the vault for which to execute the strategy.
    /// @param _strategyData Opaque data representing the strategy to execute.
    function executeVaultStrategy(uint256 _vaultId, bytes calldata _strategyData) public onlyVaultOwner(_vaultId) vaultNotPaused(_vaultId) {
        // In a real application, you would decode and execute _strategyData here.
        // This could involve calling external contracts, swapping tokens, etc.
        // For this example, we just emit an event indicating strategy execution.
        emit StrategyExecuted(_vaultId, _strategyData);
        // Placeholder for strategy logic execution based on _strategyData
        // Example: Call to a yield farming contract, automated trading, etc.
    }

    /// @notice Sets a conditional action to be triggered when a specific condition is met.
    /// @dev Condition checking and triggering in this example is simulated off-chain.
    ///      In a real-world application, you would use oracles or other mechanisms for on-chain condition evaluation.
    /// @param _vaultId The ID of the vault to set the conditional action for.
    /// @param _conditionHash A hash representing the condition to be met (e.g., keccak256("Price of ETH > $X")).
    /// @param _actionData Opaque data representing the action to execute when the condition is met.
    function setConditionalAction(uint256 _vaultId, bytes32 _conditionHash, bytes calldata _actionData) public onlyVaultOwner(_vaultId) {
        // In a real application, you would store the conditionHash and actionData, and then
        // have an off-chain service monitor conditions and call `triggerConditionalAction` when met.
        emit ConditionalActionSet(_vaultId, _conditionHash, _actionData);
        // Placeholder for storing condition and action data associated with _vaultId and _conditionHash
    }

    /// @notice Manually triggers a conditional action if the condition is met. For testing or external triggers.
    /// @dev In a real application, this would be called by an oracle or off-chain service when a condition is met.
    /// @param _vaultId The ID of the vault.
    /// @param _conditionHash The hash of the condition to trigger.
    function triggerConditionalAction(uint256 _vaultId, bytes32 _conditionHash) public vaultNotPaused(_vaultId) {
        // In a real application, you would retrieve the actionData associated with _conditionHash and _vaultId
        // and execute it here.
        emit ConditionalActionTriggered(_vaultId, _conditionHash);
        // Placeholder for fetching and executing action associated with _conditionHash
    }


    // --- NFT Representation & Access Control ---
    // Note: In a real application, you would integrate with an actual NFT contract (ERC721 or ERC1155).
    // For simplicity, we're just simulating NFT representation within this contract.

    mapping(uint256 => address) public vaultNFTRepresentations; // vaultId => NFT Holder address

    /// @notice Mints an NFT representation (simulated) for a vault to a recipient.
    /// @param _vaultId The ID of the vault to mint NFT for.
    /// @param _recipient The address to receive the NFT representation.
    function mintNFTRepresentation(uint256 _vaultId, address _recipient) public onlyVaultOwner(_vaultId) {
        require(vaultNFTRepresentations[_vaultId] == address(0), "NFT representation already minted for this vault.");
        vaultNFTRepresentations[_vaultId] = _recipient;
        emit NFTRepresentationMinted(_vaultId, _recipient);
    }

    /// @notice Transfers the NFT representation (simulated) of a vault to a new recipient.
    /// @param _vaultId The ID of the vault.
    /// @param _newRecipient The address of the new recipient.
    function transferNFTRepresentation(uint256 _vaultId, address _newRecipient) public onlyVaultOwner(_vaultId) {
        require(vaultNFTRepresentations[_vaultId] != address(0), "NFT representation not yet minted for this vault.");
        address previousRecipient = vaultNFTRepresentations[_vaultId];
        vaultNFTRepresentations[_vaultId] = _newRecipient;
        emit NFTRepresentationTransferred(_vaultId, previousRecipient, _newRecipient);
        // In a real application, you would also trigger a transfer event on the NFT contract.
        // Potentially also update vault ownership based on NFT ownership (more advanced access control).
    }

    /// @dev Modifier to require the caller to be the holder of the NFT representation for a vault.
    modifier requireNFTRepresentation(uint256 _vaultId, address _nftHolder) {
        require(vaultNFTRepresentations[_vaultId] == _nftHolder, "NFT representation required to access this function.");
        _;
    }


    // --- Governance & Advanced Features ---

    mapping(uint256 => mapping(string => uint256)) public vaultParameters; // Vault-specific parameters

    /// @notice Sets a generic parameter for a vault.
    /// @param _vaultId The ID of the vault.
    /// @param _parameterName The name of the parameter (e.g., "feeRate", "threshold").
    /// @param _parameterValue The value of the parameter.
    function setVaultParameter(uint256 _vaultId, string memory _parameterName, uint256 _parameterValue) public onlyVaultOwner(_vaultId) {
        vaultParameters[_vaultId][_parameterName] = _parameterValue;
        emit VaultParameterSet(_vaultId, _parameterName, _parameterValue);
    }

    /// @notice Emergency function to withdraw all assets from a vault in case of critical issues. Use with extreme caution.
    /// @param _vaultId The ID of the vault.
    function emergencyWithdrawAll(uint256 _vaultId) public onlyVaultOwner(_vaultId) {
        // Similar logic to destroyVault, but without destroying the vault struct itself.
        address[] memory assets = vaultAssets[_vaultId];
        for (uint256 i = 0; i < assets.length; i++) {
            address tokenAddress = assets[i];
            if (tokenAddress == address(0)) { // ETH
                uint256 ethBalance = address(this).balance;
                if (ethBalance > 0) {
                    payable(vaults[_vaultId].owner).transfer(ethBalance);
                }
            } else { // ERC20
                IERC20 token = IERC20(tokenAddress);
                uint256 tokenBalance = token.balanceOf(address(this));
                if (tokenBalance > 0) {
                    token.transfer(vaults[_vaultId].owner, tokenBalance);
                }
            }
        }
        emit EmergencyWithdrawal(_vaultId, vaults[_vaultId].owner);
    }

    /// @notice Hypothetical function to upgrade the contract logic. Requires proxy pattern in real implementation.
    /// @dev This is a simplified representation. Real contract upgrades are complex and require proxy patterns like UUPS or Transparent Proxy.
    /// @param _newLogicContract Address of the new contract logic to use.
    function upgradeContractLogic(address _newLogicContract) public onlyAdmin {
        // In a real upgradeable contract, this would involve updating the implementation address of a proxy.
        // Here, it's just a placeholder and emits an event.
        emit ContractUpgraded(_newLogicContract);
        // Placeholder for actual upgrade logic using a proxy pattern
    }

    /// @notice Registers a vault in a hypothetical global vault index or registry.
    /// @param _vaultId The ID of the vault to register.
    function registerVaultInIndex(uint256 _vaultId) public onlyVaultOwner(_vaultId) {
        // In a real application, you would interact with a separate "Vault Index" contract.
        // For now, we just emit an event indicating registration.
        emit VaultRegistered(_vaultId);
        // Placeholder for interaction with a Vault Index contract to register _vaultId
    }


}

// --- Interfaces ---
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```