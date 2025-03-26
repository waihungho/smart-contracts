```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Asset Basket (D-DAB)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized dynamic asset basket.
 *      This contract allows users to create and invest in baskets of ERC20 tokens.
 *      The basket composition and weights can be dynamically adjusted based on various strategies,
 *      on-chain data, or even decentralized governance. This contract aims to be highly flexible,
 *      secure, and feature-rich, offering advanced functionalities beyond simple token baskets.
 *
 * Function Summary:
 * -----------------
 * **Basket Management & Configuration:**
 * 1.  `createBasket(string _basketName, string _basketSymbol, string _description, address[] _initialAssets, uint256[] _initialWeights)`: Allows admin to create a new asset basket.
 * 2.  `updateBasketDescription(uint256 _basketId, string _newDescription)`: Admin function to update the description of a basket.
 * 3.  `addAssetToBasket(uint256 _basketId, address _assetAddress, uint256 _initialWeight)`: Admin function to add a new asset to an existing basket.
 * 4.  `removeAssetFromBasket(uint256 _basketId, address _assetAddress)`: Admin function to remove an asset from a basket.
 * 5.  `setAssetWeights(uint256 _basketId, address[] _assetAddresses, uint256[] _newWeights)`: Admin function to set the weights of assets within a basket.
 * 6.  `setRebalancingStrategy(uint256 _basketId, address _strategyContract)`: Admin function to set a rebalancing strategy contract for a basket.
 * 7.  `pauseBasket(uint256 _basketId)`: Admin function to pause all activities related to a basket (deposits, withdrawals, rebalancing).
 * 8.  `resumeBasket(uint256 _basketId)`: Admin function to resume a paused basket.
 * 9.  `setGovernanceContract(address _governanceContract)`: Admin function to set a governance contract that can control certain parameters.
 * 10. `transferAdminRole(address _newAdmin)`: Admin function to transfer admin rights to a new address.
 *
 * **User Interaction & Basket Investment:**
 * 11. `depositAssets(uint256 _basketId, address[] _assetAddresses, uint256[] _amounts)`: Allows users to deposit assets into a basket and receive basket tokens.
 * 12. `withdrawBasketTokens(uint256 _basketId, uint256 _basketTokenAmount)`: Allows users to withdraw their share of underlying assets by burning basket tokens.
 * 13. `getBasketValue(uint256 _basketId)`: Returns the total value of a basket in a reference currency (e.g., USD, using an oracle).
 * 14. `getUserBasketTokenBalance(uint256 _basketId, address _user)`: Returns the basket token balance of a user for a specific basket.
 * 15. `getBasketComposition(uint256 _basketId)`: Returns the list of assets and their current weights in a basket.
 * 16. `getBasketDescription(uint256 _basketId)`: Returns the description of a basket.
 *
 * **Advanced & Dynamic Features:**
 * 17. `triggerRebalance(uint256 _basketId)`: Allows anyone (or a designated actor) to trigger a rebalancing of a basket if conditions are met.
 * 18. `previewDeposit(uint256 _basketId, address[] _assetAddresses, uint256[] _amounts)`:  Previews the amount of basket tokens a user would receive for a deposit.
 * 19. `previewWithdrawal(uint256 _basketId, uint256 _basketTokenAmount)`: Previews the amount of each underlying asset a user would receive for a basket token withdrawal.
 * 20. `emergencyWithdrawal(uint256 _basketId)`:  Admin function to force an emergency withdrawal of all assets from a basket, potentially in case of critical vulnerabilities.
 * 21. `setOracleAddress(address _oracleAddress)`: Admin function to set the address of the price oracle contract.
 * 22. `getBasketAssets(uint256 _basketId)`: Returns the list of asset addresses in a basket.
 * 23. `getAssetWeight(uint256 _basketId, address _assetAddress)`: Returns the weight of a specific asset in a basket.
 * 24. `isBasketPaused(uint256 _basketId)`: Returns whether a basket is currently paused.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IPriceOracle {
    function getPrice(address _asset) external view returns (uint256 price); // Returns price in USD (or a base currency with consistent decimals)
    function decimals() external view returns (uint8); // Returns decimals of the price (e.g., 8 for 1e8 USD)
}

contract DynamicAssetBasket is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Structs & Enums ---
    struct Basket {
        string name;
        string symbol;
        string description;
        address[] assets;
        uint256[] weights; // Weights are in percentages (e.g., 3000 for 30.00%) - scaled to 10000 for precision
        uint256 totalSupply;
        address rebalancingStrategy;
        bool isPaused;
    }

    // --- State Variables ---
    Basket[] public baskets;
    mapping(uint256 => mapping(address => uint256)) public userBasketTokenBalances; // basketId => userAddress => balance
    mapping(uint256 => mapping(address => uint256)) public basketAssetBalances;     // basketId => assetAddress => balance
    address public governanceContract;
    address public priceOracleAddress;
    uint256 public basketCounter;

    // --- Events ---
    event BasketCreated(uint256 basketId, string basketName, string basketSymbol, address creator);
    event BasketDescriptionUpdated(uint256 basketId, string newDescription, address admin);
    event AssetAddedToBasket(uint256 basketId, address assetAddress, uint256 initialWeight, address admin);
    event AssetRemovedFromBasket(uint256 basketId, address assetAddress, address admin);
    event AssetWeightsUpdated(uint256 basketId, address[] assetAddresses, uint256[] newWeights, address admin);
    event RebalancingStrategySet(uint256 basketId, address strategyContract, address admin);
    event BasketPaused(uint256 basketId, address admin);
    event BasketResumed(uint256 basketId, address admin);
    event AssetsDeposited(uint256 basketId, address user, address[] assetAddresses, uint256[] amounts, uint256 basketTokensMinted);
    event BasketTokensWithdrawn(uint256 basketId, address user, uint256 basketTokensBurned, address[] assetAddresses, uint256[] withdrawnAmounts);
    event RebalanceTriggered(uint256 basketId, address triggerer);
    event EmergencyWithdrawalTriggered(uint256 basketId, address admin);
    event OracleAddressSet(address newOracleAddress, address admin);

    // --- Modifiers ---
    modifier onlyGovernance() {
        require(msg.sender == governanceContract, "Only governance contract allowed");
        _;
    }

    modifier basketExists(uint256 _basketId) {
        require(_basketId < basketCounter && _basketId < baskets.length, "Basket does not exist");
        _;
    }

    modifier basketNotPaused(uint256 _basketId) {
        require(!baskets[_basketId].isPaused, "Basket is currently paused");
        _;
    }

    // --- Constructor ---
    constructor(address _initialAdmin, address _oracleAddress) Ownable() {
        transferOwnership(_initialAdmin);
        priceOracleAddress = _oracleAddress;
        basketCounter = 0;
    }

    // --- Basket Management & Configuration Functions ---

    /**
     * @dev Creates a new asset basket. Only admin can call this function.
     * @param _basketName The name of the basket.
     * @param _basketSymbol The symbol for the basket token.
     * @param _description A brief description of the basket.
     * @param _initialAssets An array of initial asset addresses (ERC20 tokens).
     * @param _initialWeights An array of initial weights for the assets (in percentages, scaled to 10000).
     */
    function createBasket(
        string memory _basketName,
        string memory _basketSymbol,
        string memory _description,
        address[] memory _initialAssets,
        uint256[] memory _initialWeights
    ) external onlyOwner {
        require(_initialAssets.length == _initialWeights.length, "Assets and weights length mismatch");
        require(_initialAssets.length > 0, "Basket must contain at least one asset");
        uint256 totalWeight = 0;
        for (uint256 weight in _initialWeights) {
            totalWeight = totalWeight.add(weight);
        }
        require(totalWeight == 10000, "Total weights must equal 100%");

        baskets.push(Basket({
            name: _basketName,
            symbol: _basketSymbol,
            description: _description,
            assets: _initialAssets,
            weights: _initialWeights,
            totalSupply: 0,
            rebalancingStrategy: address(0), // No strategy initially
            isPaused: false
        }));

        emit BasketCreated(basketCounter, _basketName, _basketSymbol, msg.sender);
        basketCounter++;
    }

    /**
     * @dev Updates the description of an existing basket. Only admin can call this function.
     * @param _basketId The ID of the basket to update.
     * @param _newDescription The new description for the basket.
     */
    function updateBasketDescription(uint256 _basketId, string memory _newDescription) external onlyOwner basketExists(_basketId) {
        baskets[_basketId].description = _newDescription;
        emit BasketDescriptionUpdated(_basketId, _newDescription, msg.sender);
    }

    /**
     * @dev Adds a new asset to an existing basket. Only admin can call this function.
     *      Rebalances the weights proportionally to accommodate the new asset.
     * @param _basketId The ID of the basket to add the asset to.
     * @param _assetAddress The address of the ERC20 token to add.
     * @param _initialWeight The initial weight of the new asset (in percentage, scaled to 10000).
     */
    function addAssetToBasket(uint256 _basketId, address _assetAddress, uint256 _initialWeight) external onlyOwner basketExists(_basketId) {
        require(_assetAddress != address(0), "Invalid asset address");
        require(_initialWeight > 0, "Initial weight must be greater than zero");

        Basket storage basket = baskets[_basketId];
        address[] storage assets = basket.assets;
        uint256[] storage weights = basket.weights;

        // Check if asset already exists
        for (uint256 i = 0; i < assets.length; i++) {
            require(assets[i] != _assetAddress, "Asset already exists in basket");
        }

        // Adjust existing weights proportionally to make space for the new asset
        uint256 currentTotalWeight = 0;
        for (uint256 weight in weights) {
            currentTotalWeight = currentTotalWeight.add(weight);
        }
        uint256 weightReductionFactor = (10000 - _initialWeight).mul(10000).div(currentTotalWeight); // Scale factor

        for (uint256 i = 0; i < weights.length; i++) {
            weights[i] = weights[i].mul(weightReductionFactor).div(10000);
        }

        assets.push(_assetAddress);
        weights.push(_initialWeight);

        emit AssetAddedToBasket(_basketId, _assetAddress, _initialWeight, msg.sender);
    }

    /**
     * @dev Removes an asset from an existing basket. Only admin can call this function.
     *      Rebalances the weights proportionally of the remaining assets.
     * @param _basketId The ID of the basket to remove the asset from.
     * @param _assetAddress The address of the ERC20 token to remove.
     */
    function removeAssetFromBasket(uint256 _basketId, address _assetAddress) external onlyOwner basketExists(_basketId) {
        Basket storage basket = baskets[_basketId];
        address[] storage assets = basket.assets;
        uint256[] storage weights = basket.weights;

        bool assetFound = false;
        uint256 removedAssetIndex;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == _assetAddress) {
                assetFound = true;
                removedAssetIndex = i;
                break;
            }
        }
        require(assetFound, "Asset not found in basket");

        uint256 removedAssetWeight = weights[removedAssetIndex];

        // Remove asset and weight from arrays
        for (uint256 i = removedAssetIndex; i < assets.length - 1; i++) {
            assets[i] = assets[i + 1];
            weights[i] = weights[i + 1];
        }
        assets.pop();
        weights.pop();

        // Redistribute the removed asset's weight to the remaining assets proportionally
        if (assets.length > 0) { // Avoid division by zero if basket becomes empty (though unlikely in this function's context)
            uint256 currentTotalWeight = 0;
            for (uint256 weight in weights) {
                currentTotalWeight = currentTotalWeight.add(weight);
            }
            uint256 weightIncreaseFactor = (10000 + removedAssetWeight).mul(10000).div(currentTotalWeight);

            for (uint256 i = 0; i < weights.length; i++) {
                weights[i] = weights[i].mul(weightIncreaseFactor).div(10000);
            }
        }


        emit AssetRemovedFromBasket(_basketId, _assetAddress, msg.sender);
    }

    /**
     * @dev Sets the weights of assets within a basket. Only admin can call this function.
     * @param _basketId The ID of the basket to update.
     * @param _assetAddresses An array of asset addresses to set weights for. Must be a subset of existing basket assets.
     * @param _newWeights An array of new weights corresponding to the asset addresses (in percentages, scaled to 10000).
     */
    function setAssetWeights(uint256 _basketId, address[] memory _assetAddresses, uint256[] memory _newWeights) external onlyOwner basketExists(_basketId) {
        require(_assetAddresses.length == _newWeights.length, "Assets and weights length mismatch");
        Basket storage basket = baskets[_basketId];
        address[] storage assets = basket.assets;
        uint256[] storage weights = basket.weights;

        require(_assetAddresses.length == assets.length, "Number of assets to set weights for must match current basket assets"); // Enforce setting weights for all assets

        uint256 totalWeight = 0;
        for (uint256 weight in _newWeights) {
            totalWeight = totalWeight.add(weight);
        }
        require(totalWeight == 10000, "Total weights must equal 100%");

        for (uint256 i = 0; i < _assetAddresses.length; i++) {
            bool assetFound = false;
            for (uint256 j = 0; j < assets.length; j++) {
                if (_assetAddresses[i] == assets[j]) {
                    weights[j] = _newWeights[i]; // Update weight at the correct index
                    assetFound = true;
                    break;
                }
            }
            require(assetFound, "Asset address not found in basket");
        }

        emit AssetWeightsUpdated(_basketId, _assetAddresses, _newWeights, msg.sender);
    }

    /**
     * @dev Sets the rebalancing strategy contract for a basket. Only admin can call this function.
     * @param _basketId The ID of the basket to set the strategy for.
     * @param _strategyContract The address of the rebalancing strategy contract.
     */
    function setRebalancingStrategy(uint256 _basketId, address _strategyContract) external onlyOwner basketExists(_basketId) {
        // In a real-world scenario, you might want to validate that the strategy contract
        // implements a specific interface to ensure compatibility.
        baskets[_basketId].rebalancingStrategy = _strategyContract;
        emit RebalancingStrategySet(_basketId, _strategyContract, msg.sender);
    }

    /**
     * @dev Pauses all activities related to a basket (deposits, withdrawals, rebalancing). Only admin can call this function.
     * @param _basketId The ID of the basket to pause.
     */
    function pauseBasket(uint256 _basketId) external onlyOwner basketExists(_basketId) {
        baskets[_basketId].isPaused = true;
        emit BasketPaused(_basketId, msg.sender);
    }

    /**
     * @dev Resumes activities for a paused basket. Only admin can call this function.
     * @param _basketId The ID of the basket to resume.
     */
    function resumeBasket(uint256 _basketId) external onlyOwner basketExists(_basketId) {
        baskets[_basketId].isPaused = false;
        emit BasketResumed(_basketId, msg.sender);
    }

    /**
     * @dev Sets the governance contract address. Only admin can call this function.
     * @param _governanceContract The address of the governance contract.
     */
    function setGovernanceContract(address _governanceContract) external onlyOwner {
        governanceContract = _governanceContract;
    }

    /**
     * @dev Transfers admin role to a new address. Inherited from Ownable.
     * @param _newAdmin The address of the new admin.
     */
    function transferAdminRole(address _newAdmin) external onlyOwner {
        transferOwnership(_newAdmin);
    }


    // --- User Interaction & Basket Investment Functions ---

    /**
     * @dev Allows users to deposit assets into a basket and receive basket tokens.
     * @param _basketId The ID of the basket to deposit into.
     * @param _assetAddresses An array of asset addresses being deposited. Must match basket's assets or a subset.
     * @param _amounts An array of amounts to deposit for each asset. Order must correspond to _assetAddresses.
     */
    function depositAssets(uint256 _basketId, address[] memory _assetAddresses, uint256[] memory _amounts)
        external
        basketExists(_basketId)
        basketNotPaused(_basketId)
    {
        require(_assetAddresses.length == _amounts.length, "Assets and amounts length mismatch");
        Basket storage basket = baskets[_basketId];
        address[] storage assets = basket.assets;
        uint256[] storage weights = basket.weights;

        uint256 totalDepositValueUSD = 0;
        uint256 basketValueUSD = getBasketValue(_basketId); // Get current total basket value in USD
        uint256 currentBasketSupply = basket.totalSupply;
        uint256 basketTokensToMint;

        require(assets.length == _assetAddresses.length, "Deposit must include all basket assets"); // Enforce depositing all basket assets - can be relaxed if needed.

        for (uint256 i = 0; i < _assetAddresses.length; i++) {
            bool assetInBasket = false;
            uint256 assetIndex;
            for (uint256 j = 0; j < assets.length; j++) {
                if (_assetAddresses[i] == assets[j]) {
                    assetInBasket = true;
                    assetIndex = j;
                    break;
                }
            }
            require(assetInBasket, "Asset is not part of this basket");

            IERC20 assetToken = IERC20(_assetAddresses[i]);
            uint256 depositAmount = _amounts[i];

            // Transfer assets from user to contract
            assetToken.transferFrom(msg.sender, address(this), depositAmount);

            // Update basket asset balance
            basketAssetBalances[_basketId][_assetAddresses[i]] = basketAssetBalances[_basketId][_assetAddresses[i]].add(depositAmount);

            // Calculate deposit value in USD using oracle
            uint256 assetPriceUSD = IPriceOracle(priceOracleAddress).getPrice(_assetAddresses[i]);
            uint256 priceDecimals = IPriceOracle(priceOracleAddress).decimals();
            uint256 assetValueUSD = depositAmount.mul(assetPriceUSD).div(10**IERC20(_assetAddresses[i]).decimals()).div(10**priceDecimals); // Normalize decimals

            totalDepositValueUSD = totalDepositValueUSD.add(assetValueUSD);
        }

        // Mint basket tokens based on deposit value and current basket supply
        if (currentBasketSupply == 0 || basketValueUSD == 0) {
            basketTokensToMint = totalDepositValueUSD; // If basket is new or value is zero, mint basket tokens equal to USD value (initial ratio 1:1 - can be adjusted)
        } else {
            basketTokensToMint = totalDepositValueUSD.mul(currentBasketSupply).div(basketValueUSD);
        }

        basket.totalSupply = basket.totalSupply.add(basketTokensToMint);
        userBasketTokenBalances[_basketId][msg.sender] = userBasketTokenBalances[_basketId][msg.sender].add(basketTokensToMint);

        emit AssetsDeposited(_basketId, msg.sender, _assetAddresses, _amounts, basketTokensToMint);
    }

    /**
     * @dev Allows users to withdraw their share of underlying assets by burning basket tokens.
     * @param _basketId The ID of the basket to withdraw from.
     * @param _basketTokenAmount The amount of basket tokens to burn for withdrawal.
     */
    function withdrawBasketTokens(uint256 _basketId, uint256 _basketTokenAmount)
        external
        basketExists(_basketId)
        basketNotPaused(_basketId)
    {
        require(_basketTokenAmount > 0, "Withdrawal amount must be greater than zero");
        Basket storage basket = baskets[_basketId];
        address[] storage assets = basket.assets;
        uint256 currentBasketSupply = basket.totalSupply;
        uint256 userBalance = userBasketTokenBalances[_basketId][msg.sender];
        require(userBalance >= _basketTokenAmount, "Insufficient basket token balance");
        require(currentBasketSupply > 0, "Basket has zero supply");

        uint256 basketValueUSD = getBasketValue(_basketId); // Get current total basket value in USD

        uint256 withdrawalValueUSD = basketValueUSD.mul(_basketTokenAmount).div(currentBasketSupply); // Value of withdrawal in USD

        address[] memory withdrawnAssetAddresses = new address[](assets.length);
        uint256[] memory withdrawnAmounts = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            address assetAddress = assets[i];
            uint256 assetPriceUSD = IPriceOracle(priceOracleAddress).getPrice(assetAddress);
            uint256 priceDecimals = IPriceOracle(priceOracleAddress).decimals();
            uint256 assetBalanceInBasket = basketAssetBalances[_basketId][assetAddress];

            // Calculate amount of each asset to withdraw based on USD value and asset price
            uint256 assetWithdrawalAmount = withdrawalValueUSD.mul(10**IERC20(assetAddress).decimals()).mul(10**priceDecimals).div(assetPriceUSD); // Normalize decimals

            // Ensure there are enough assets in the basket for withdrawal
            if (assetWithdrawalAmount > assetBalanceInBasket) {
                assetWithdrawalAmount = assetBalanceInBasket; // Withdraw max available if requested amount exceeds balance
            }

            if (assetWithdrawalAmount > 0) { // Only transfer if withdrawal amount is positive
                IERC20 assetToken = IERC20(assetAddress);
                assetToken.transfer(msg.sender, assetWithdrawalAmount);
                basketAssetBalances[_basketId][assetAddress] = basketAssetBalances[_basketId][assetAddress].sub(assetWithdrawalAmount);

                withdrawnAssetAddresses[i] = assetAddress;
                withdrawnAmounts[i] = assetWithdrawalAmount;
            }
        }

        // Burn basket tokens
        basket.totalSupply = basket.totalSupply.sub(_basketTokenAmount);
        userBasketTokenBalances[_basketId][msg.sender] = userBasketTokenBalances[_basketId][msg.sender].sub(_basketTokenAmount);

        emit BasketTokensWithdrawn(_basketId, msg.sender, _basketTokenAmount, withdrawnAssetAddresses, withdrawnAmounts);
    }

    /**
     * @dev Returns the total value of a basket in USD (using the price oracle).
     * @param _basketId The ID of the basket.
     * @return The total value of the basket in USD.
     */
    function getBasketValue(uint256 _basketId) public view basketExists(_basketId) returns (uint256) {
        Basket storage basket = baskets[_basketId];
        address[] storage assets = basket.assets;
        uint256 totalBasketValueUSD = 0;

        for (uint256 i = 0; i < assets.length; i++) {
            address assetAddress = assets[i];
            uint256 assetBalance = basketAssetBalances[_basketId][assetAddress];
            uint256 assetPriceUSD = IPriceOracle(priceOracleAddress).getPrice(assetAddress);
            uint256 priceDecimals = IPriceOracle(priceOracleAddress).decimals();

            uint256 assetValueUSD = assetBalance.mul(assetPriceUSD).div(10**IERC20(assetAddress).decimals()).div(10**priceDecimals); // Normalize decimals
            totalBasketValueUSD = totalBasketValueUSD.add(assetValueUSD);
        }
        return totalBasketValueUSD;
    }

    /**
     * @dev Returns the basket token balance of a user for a specific basket.
     * @param _basketId The ID of the basket.
     * @param _user The address of the user.
     * @return The basket token balance of the user.
     */
    function getUserBasketTokenBalance(uint256 _basketId, address _user) public view basketExists(_basketId) returns (uint256) {
        return userBasketTokenBalances[_basketId][_user];
    }

    /**
     * @dev Returns the list of assets and their current weights in a basket.
     * @param _basketId The ID of the basket.
     * @return An array of asset addresses and an array of their current weights (in percentages, scaled to 10000).
     */
    function getBasketComposition(uint256 _basketId) public view basketExists(_basketId) returns (address[] memory, uint256[] memory) {
        return (baskets[_basketId].assets, baskets[_basketId].weights);
    }

    /**
     * @dev Returns the description of a basket.
     * @param _basketId The ID of the basket.
     * @return The description of the basket.
     */
    function getBasketDescription(uint256 _basketId) public view basketExists(_basketId) returns (string memory) {
        return baskets[_basketId].description;
    }

    // --- Advanced & Dynamic Features ---

    /**
     * @dev Allows anyone (or a designated actor) to trigger a rebalancing of a basket if conditions are met.
     *      In a real-world scenario, this would typically be triggered by an off-chain service or a rebalancing strategy contract.
     *      For simplicity, this example just emits an event. Actual rebalancing logic would be implemented in a strategy contract.
     * @param _basketId The ID of the basket to rebalance.
     */
    function triggerRebalance(uint256 _basketId) external basketExists(_basketId) basketNotPaused(_basketId) {
        // In a more advanced implementation, this function would:
        // 1. Check if rebalancing conditions are met (e.g., time elapsed, weight deviation threshold reached).
        // 2. Call the rebalancing strategy contract (if set) to execute trades.
        // 3. Or implement basic rebalancing logic directly in this contract (less flexible).

        // For this example, just emit an event to indicate rebalancing is triggered.
        emit RebalanceTriggered(_basketId, msg.sender);

        // Example: Basic Rebalancing Logic (Simplified - for illustration only)
        // In a real-world scenario, you'd need to integrate with a DEX or implement a more sophisticated trading mechanism.
        // if (baskets[_basketId].rebalancingStrategy != address(0)) {
        //     // Call rebalancing strategy contract
        //     // IRebalancingStrategy(baskets[_basketId].rebalancingStrategy).rebalance(_basketId);
        // } else {
        //     // Basic rebalancing logic - e.g., try to adjust weights back to target weights using internal swaps (very simplified)
        //     // ... (complex logic involving price oracles, DEX interactions, etc. would go here)
        // }
    }

    /**
     * @dev Previews the amount of basket tokens a user would receive for a deposit.
     * @param _basketId The ID of the basket.
     * @param _assetAddresses An array of asset addresses being deposited.
     * @param _amounts An array of amounts to deposit for each asset.
     * @return The previewed amount of basket tokens that would be minted.
     */
    function previewDeposit(uint256 _basketId, address[] memory _assetAddresses, uint256[] memory _amounts)
        public view basketExists(_basketId) returns (uint256)
    {
        uint256 totalDepositValueUSD = 0;
        uint256 basketValueUSD = getBasketValue(_basketId);
        uint256 currentBasketSupply = baskets[_basketId].totalSupply;
        uint256 basketTokensToMint;

        for (uint256 i = 0; i < _assetAddresses.length; i++) {
            uint256 assetPriceUSD = IPriceOracle(priceOracleAddress).getPrice(_assetAddresses[i]);
            uint256 priceDecimals = IPriceOracle(priceOracleAddress).decimals();
            uint256 assetValueUSD = _amounts[i].mul(assetPriceUSD).div(10**IERC20(_assetAddresses[i]).decimals()).div(10**priceDecimals); // Normalize decimals
            totalDepositValueUSD = totalDepositValueUSD.add(assetValueUSD);
        }

        if (currentBasketSupply == 0 || basketValueUSD == 0) {
            basketTokensToMint = totalDepositValueUSD;
        } else {
            basketTokensToMint = totalDepositValueUSD.mul(currentBasketSupply).div(basketValueUSD);
        }
        return basketTokensToMint;
    }

    /**
     * @dev Previews the amount of each underlying asset a user would receive for a basket token withdrawal.
     * @param _basketId The ID of the basket.
     * @param _basketTokenAmount The amount of basket tokens to withdraw.
     * @return Arrays of asset addresses and previewed withdrawal amounts for each asset.
     */
    function previewWithdrawal(uint256 _basketId, uint256 _basketTokenAmount)
        public view basketExists(_basketId) returns (address[] memory, uint256[] memory)
    {
        Basket storage basket = baskets[_basketId];
        address[] storage assets = basket.assets;
        uint256 currentBasketSupply = basket.totalSupply;
        uint256 basketValueUSD = getBasketValue(_basketId);
        uint256 withdrawalValueUSD = basketValueUSD.mul(_basketTokenAmount).div(currentBasketSupply);

        address[] memory previewedAssetAddresses = new address[](assets.length);
        uint256[] memory previewedAmounts = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            address assetAddress = assets[i];
            uint256 assetPriceUSD = IPriceOracle(priceOracleAddress).getPrice(assetAddress);
            uint256 priceDecimals = IPriceOracle(priceOracleAddress).decimals();
            uint256 assetBalanceInBasket = basketAssetBalances[_basketId][assetAddress];

            uint256 assetWithdrawalAmount = withdrawalValueUSD.mul(10**IERC20(assetAddress).decimals()).mul(10**priceDecimals).div(assetPriceUSD);

            if (assetWithdrawalAmount > assetBalanceInBasket) {
                assetWithdrawalAmount = assetBalanceInBasket;
            }

            previewedAssetAddresses[i] = assetAddress;
            previewedAmounts[i] = assetWithdrawalAmount;
        }
        return (previewedAssetAddresses, previewedAmounts);
    }

    /**
     * @dev Admin function to force an emergency withdrawal of all assets from a basket.
     *      Potentially used in case of critical vulnerabilities or contract upgrades.
     * @param _basketId The ID of the basket to perform emergency withdrawal on.
     */
    function emergencyWithdrawal(uint256 _basketId) external onlyOwner basketExists(_basketId) {
        Basket storage basket = baskets[_basketId];
        address[] storage assets = basket.assets;

        for (uint256 i = 0; i < assets.length; i++) {
            address assetAddress = assets[i];
            uint256 assetBalance = basketAssetBalances[_basketId][assetAddress];
            if (assetBalance > 0) {
                IERC20 assetToken = IERC20(assetAddress);
                assetToken.transfer(owner(), assetBalance); // Transfer all assets to the contract owner (admin)
                basketAssetBalances[_basketId][assetAddress] = 0; // Reset balance
            }
        }
        emit EmergencyWithdrawalTriggered(_basketId, msg.sender);
    }

    /**
     * @dev Sets the address of the price oracle contract. Only admin can call this function.
     * @param _oracleAddress The address of the price oracle contract.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        priceOracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress, msg.sender);
    }

    /**
     * @dev Returns the list of asset addresses in a basket.
     * @param _basketId The ID of the basket.
     * @return An array of asset addresses.
     */
    function getBasketAssets(uint256 _basketId) public view basketExists(_basketId) returns (address[] memory) {
        return baskets[_basketId].assets;
    }

    /**
     * @dev Returns the weight of a specific asset in a basket.
     * @param _basketId The ID of the basket.
     * @param _assetAddress The address of the asset.
     * @return The weight of the asset (in percentage, scaled to 10000).
     */
    function getAssetWeight(uint256 _basketId, address _assetAddress) public view basketExists(_basketId) returns (uint256) {
        Basket storage basket = baskets[_basketId];
        address[] storage assets = basket.assets;
        uint256[] storage weights = basket.weights;

        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == _assetAddress) {
                return weights[i];
            }
        }
        return 0; // Asset not found, return 0 weight (or handle error differently if needed)
    }

    /**
     * @dev Returns whether a basket is currently paused.
     * @param _basketId The ID of the basket.
     * @return True if the basket is paused, false otherwise.
     */
    function isBasketPaused(uint256 _basketId) public view basketExists(_basketId) returns (bool) {
        return baskets[_basketId].isPaused;
    }
}
```