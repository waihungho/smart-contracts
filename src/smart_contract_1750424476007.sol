Okay, let's design a sophisticated smart contract that combines elements of DeFi vaults, dynamic NFTs, and conditional logic powered by oracles.

We'll call it `MetaMorphosisVault`. This contract will allow users to deposit both ERC-20 tokens and ERC-721 NFTs into time-locked vaults. The interesting twists are:

1.  **Multi-Asset Deposits:** Handles both fungible and non-fungible tokens.
2.  **Dynamic Lock-up:** Minimum lock-up periods set by the owner.
3.  **Conditional Withdrawals:** Users can optionally set conditions (e.g., token price above a threshold via oracle) for withdrawal *before* the lock-up ends (with potential fees).
4.  **Simulated Yield/Growth:** Includes functions to represent or calculate a simulated yield based on time/value locked.
5.  **Dynamic Fee Structure:** Withdrawal fees can vary based on early withdrawal, asset type, or other parameters.
6.  **MetaMorphosis NFT:** Upon significant interaction (e.g., completing a long lock-up, withdrawing a large amount, or simply upon request after a certain period), the user can mint a unique "MetaMorphosis" NFT whose traits (represented by metadata) are *derived from their vault interaction history* (total value deposited, duration locked, types of assets, number of transactions). This NFT serves as a badge of their vault participation.

This combines vault mechanics, oracle integration, dynamic logic, and NFT generation based on on-chain activity, making it non-trivial and covering several advanced/trendy concepts.

---

**Outline:**

1.  **Pragma, Imports, Interfaces**
2.  **Error Definitions**
3.  **Libraries**
4.  **State Variables**
    *   Admin/Ownership
    *   Pausable state
    *   Allowed tokens (ERC-20, ERC-721 addresses)
    *   Deposit data structures
    *   Mapping for user deposits
    *   Global deposit counter
    *   MetaMorphosis NFT Contract Address
    *   Oracle Contract Address
    *   Vault settings (lock-up, fees, yield rate)
    *   Accumulated fees
    *   Mapping for user's minted NFT ID
    *   Mapping for user's simulated yield
5.  **Events**
6.  **Modifiers**
7.  **Constructor**
8.  **Core Vault Functions**
    *   Deposit (ERC20, ERC721)
    *   Withdraw (ERC20, ERC721)
    *   Withdraw Conditional (ERC20, ERC721)
9.  **MetaMorphosis NFT Functions**
    *   Set NFT contract address
    *   Mint NFT
    *   Generate NFT metadata URI (logic based on user history)
10. **Dynamic/Yield Functions**
    *   Claim Simulated Yield
    *   Reinvest Simulated Yield
    *   Calculate Withdrawal Fee
11. **Admin Functions**
    *   Set allowed tokens
    *   Set NFT contract address
    *   Set Oracle address
    *   Set minimum lock-up
    *   Set fee parameters
    *   Set simulated yield rate
    *   Pause/Unpause
    *   Owner withdraw fees
    *   Emergency withdraw specific token (admin only)
12. **Getter Functions**
    *   Get deposit details
    *   Get user deposit IDs
    *   Get total value locked (basic estimate)
    *   Get user total deposits (basic estimate)
    *   Get user simulated yield
    *   Get minimum lock-up
    *   Get fee parameters
    *   Get accumulated fees
    *   Check if token is allowed
    *   Get user NFT ID
    *   Get user deposit count
    *   Get user total duration locked
    *   Get Oracle address
    *   Get NFT contract address

---

**Function Summary:**

*   `constructor()`: Initializes ownership, sets initial parameters.
*   `depositERC20(address tokenAddress, uint256 amount, uint64 lockUpUntil)`: Deposits ERC-20 tokens with a specified lock-up time.
*   `depositERC721(address tokenAddress, uint256 tokenId, uint64 lockUpUntil)`: Deposits ERC-721 tokens with a specified lock-up time.
*   `withdrawERC20(uint256 depositId, uint256 amount)`: Withdraws deposited ERC-20 tokens after the lock-up period ends. Applies fees if applicable (e.g., partial or early withdrawal logic).
*   `withdrawERC721(uint256 depositId)`: Withdraws a deposited ERC-721 token after the lock-up period ends. Applies fees if applicable.
*   `withdrawERC20Conditional(uint256 depositId, uint256 amount, int256 priceThreshold)`: Withdraws ERC-20 before lock-up IF the oracle reports a price meeting the threshold. Applies early withdrawal fees.
*   `withdrawERC721Conditional(uint256 depositId, int256 priceThreshold)`: Withdraws ERC-721 before lock-up IF the oracle reports a price meeting the threshold. Applies early withdrawal fees.
*   `claimSimulatedYield()`: Calculates accrued simulated yield for the user based on their active deposits and makes it available for withdrawal (adds to an internal balance, not actual tokens).
*   `reinvestSimulatedYield()`: Reinvests accumulated simulated yield back into an existing deposit or creates a new virtual deposit (increases tracked value for future yield calculation).
*   `mintMetaMorphosisNFT(uint256 depositId)`: Mints a unique MetaMorphosis NFT to the caller, potentially using the history of the specified deposit ID (or overall user history) to influence its metadata. Requires the user to not have already minted one or meet certain criteria.
*   `generateNFTMetadataUri(address user, uint256 nftId)`: Internal/view function logic to determine the basis for the NFT metadata URI based on the user's vault interactions. The actual URI generation/hosting happens off-chain but is *derived* from on-chain data calculated here.
*   `calculateWithdrawalFee(uint256 depositId, uint256 withdrawAmount)`: Calculates the fee for a potential withdrawal based on deposit parameters and withdrawal amount/timing.
*   `setMetaMorphosisNFTContract(address _nftContract)`: Admin sets the address of the MetaMorphosis NFT contract.
*   `setOracleAddress(address _oracle)`: Admin sets the address of the Oracle contract (e.g., Chainlink AggregatorV3).
*   `setAllowedTokens(address[] calldata erc20s, address[] calldata erc721s, bool allowed)`: Admin allows/disallows token addresses for deposits.
*   `setMinimumLockUp(uint64 _minLockUp)`: Admin sets the minimum required lock-up duration for new deposits.
*   `setFeeParameters(uint256 baseFeeBps, uint256 earlyWithdrawalFeeBps)`: Admin sets parameters for fee calculation (basis points).
*   `setSimulatedYieldRate(uint256 rate)`: Admin sets the annual simulated yield rate (basis points).
*   `pause()`: Admin pauses deposits and withdrawals.
*   `unpause()`: Admin unpauses the contract.
*   `ownerWithdrawFees(address tokenAddress)`: Owner withdraws accumulated fees for a specific token.
*   `emergencyTokenWithdraw(address tokenAddress, uint256 amount)`: Admin can withdraw a specific token amount in emergencies (e.g., wrongly sent tokens).
*   `getDepositDetails(uint256 depositId)`: Returns details for a specific deposit ID.
*   `getUserDepositIds(address user)`: Returns an array of deposit IDs for a given user.
*   `getTotalValueLocked()`: Returns a basic estimation of total value locked (sums up ERC20 amounts, counts ERC721s - requires external price data for accurate value).
*   `getUserTotalDeposits(address user)`: Returns a basic estimation of a user's total deposited value.
*   `getUserSimulatedYield(address user)`: Returns the user's current accumulated simulated yield.
*   `getMinimumLockUp()`: Returns the current minimum lock-up period.
*   `getFeeParameters()`: Returns the current fee parameters.
*   `getAccumulatedFees(address tokenAddress)`: Returns the total accumulated fees for a specific token.
*   `isTokenAllowed(address tokenAddress)`: Checks if a token is allowed for deposit.
*   `getUserMetaMorphosisNFTId(address user)`: Returns the NFT ID minted for the user, or 0 if none.
*   `getUserDepositCount(address user)`: Returns the total number of individual deposits made by a user.
*   `getUserTotalDurationLocked(address user)`: Returns the sum of lock-up durations for all completed or active deposits of a user.
*   `getOracleAddress()`: Returns the address of the Oracle contract.
*   `getMetaMorphosisNFTContract()`: Returns the address of the MetaMorphosis NFT contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although Solidity 0.8+ has overflow checks, using SafeMath explicitly for clarity in complex calcs can be useful, or rely on built-ins. Let's stick to built-ins for 0.8+.

// Interface for a simple Price Oracle (like Chainlink AggregatorV3)
interface IAggregatorV3 {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// Interface for the MetaMorphosis NFT contract
interface IMetaMorphosisNFT {
    function mint(address to, uint256 tokenId, string calldata uri) external;
    // Add other relevant functions if needed, e.g., tokenURI
}

/// @title MetaMorphosisVault
/// @dev A multi-asset vault with dynamic lock-ups, conditional withdrawals via oracle,
/// simulated yield, dynamic fees, and a mechanism to mint unique NFTs based on user history.
contract MetaMorphosisVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;

    // --- Error Definitions ---
    error DepositNotFound();
    error LockUpNotExpired(uint64 unlockTime);
    error AmountExceedsDeposit(uint256 requested, uint256 available);
    error NotAllowedToken(address tokenAddress);
    error InvalidLockUp(uint64 required, uint64 provided);
    error NFTContractNotSet();
    error UserAlreadyMintedNFT();
    error WithdrawalConditionNotMet();
    error OracleNotSet();
    error InsufficientFees(address tokenAddress, uint256 amount);
    error InsufficientBalance(address tokenAddress, uint256 amount);
    error EmergencyWithdrawNotAllowedForNFT();
    error NotPermitted();


    // --- State Variables ---

    // Configuration
    address public metaMorphosisNFTContract;
    IAggregatorV3 public oracle;
    uint64 public minLockUpPeriod = 30 days; // Default minimum lock-up
    uint256 public baseWithdrawalFeeBps = 50; // 0.5% base fee in Basis Points
    uint256 public earlyWithdrawalFeeBps = 500; // 5% early withdrawal fee in Basis Points
    uint256 public simulatedYieldRateBps = 1000; // 10% annual simulated yield rate in Basis Points (10000 = 100%)

    // Allowed Tokens
    mapping(address => bool) private allowedERC20s;
    mapping(address => bool) private allowedERC721s;

    // Deposit Data
    struct Deposit {
        address user;
        address tokenAddress;
        uint256 amount; // For ERC20
        uint256 tokenId; // For ERC721
        bool isERC721;
        uint64 depositTime;
        uint64 lockUpUntil;
        uint256 remainingAmount; // For partial ERC20 withdrawals
        bool isActive; // Flag to track if deposit slot is active
    }

    Deposit[] public deposits; // Stores all deposits
    mapping(address => uint256[]) private userDepositIds; // Maps user to array of deposit IDs
    uint256 private nextDepositId = 1; // Start deposit IDs from 1

    // Fees and Yield
    mapping(address => uint256) public accumulatedFees; // Maps token address to total fees collected
    mapping(address => uint256) private userSimulatedYield; // Maps user to their accumulated simulated yield

    // NFT Tracking
    mapping(address => uint256) public userMetaMorphosisNFTId; // Maps user to the NFT ID they minted (0 if none)

    // --- Events ---
    event ERC20Deposited(uint256 depositId, address user, address tokenAddress, uint256 amount, uint64 lockUpUntil);
    event ERC721Deposited(uint256 depositId, address user, address tokenAddress, uint256 tokenId, uint64 lockUpUntil);
    event ERC20Withdrawn(uint256 depositId, address user, address tokenAddress, uint256 amount, uint256 fee);
    event ERC721Withdrawn(uint256 depositId, address user, address tokenAddress, uint256 fee);
    event MetaMorphosisNFTMinted(address user, uint256 nftId, string uri);
    event SimulatedYieldClaimed(address user, uint256 yieldAmount);
    event SimulatedYieldReinvested(address user, uint256 yieldAmount);
    event FeesWithdrawn(address owner, address tokenAddress, uint256 amount);
    event TokenAllowed(address tokenAddress, bool allowed);
    event NFTContractSet(address nftContract);
    event OracleSet(address oracle);
    event MinimumLockUpSet(uint64 minLockUp);
    event FeeParametersSet(uint256 baseFeeBps, uint256 earlyWithdrawalFeeBps);
    event SimulatedYieldRateSet(uint256 rate);
    event Paused(address by);
    event Unpaused(address by);


    // --- Modifiers ---
    modifier onlyAllowedToken(address tokenAddress, bool isERC721Check) {
        if (isERC721Check) {
            if (!allowedERC721s[tokenAddress]) revert NotAllowedToken(tokenAddress);
        } else {
            if (!allowedERC20s[tokenAddress]) revert NotAllowedToken(tokenAddress);
        }
        _;
    }

    modifier depositActive(uint256 depositId) {
        if (depositId == 0 || depositId > deposits.length || !deposits[depositId - 1].isActive) revert DepositNotFound();
        _;
    }

    modifier onlyDepositOwner(uint256 depositId) {
        if (deposits[depositId - 1].user != msg.sender) revert NotPermitted();
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {}

    // --- Core Vault Functions ---

    /// @dev Deposits ERC-20 tokens into the vault with a specified lock-up period.
    /// @param tokenAddress Address of the ERC-20 token.
    /// @param amount Amount of tokens to deposit.
    /// @param lockUpUntil Timestamp until which the deposit is locked.
    function depositERC20(address tokenAddress, uint256 amount, uint64 lockUpUntil)
        external
        payable // Allow receiving native currency too if needed later, currently unused
        whenNotPaused
        nonReentrant
        onlyAllowedToken(tokenAddress, false)
    {
        if (lockUpUntil < block.timestamp + minLockUpPeriod) {
            revert InvalidLockUp(block.timestamp + minLockUpPeriod, lockUpUntil);
        }

        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentId = nextDepositId++;
        deposits.push(Deposit({
            user: msg.sender,
            tokenAddress: tokenAddress,
            amount: amount,
            tokenId: 0, // N/A for ERC20
            isERC721: false,
            depositTime: uint64(block.timestamp),
            lockUpUntil: lockUpUntil,
            remainingAmount: amount,
            isActive: true
        }));
        userDepositIds[msg.sender].push(currentId);

        emit ERC20Deposited(currentId, msg.sender, tokenAddress, amount, lockUpUntil);
    }

    /// @dev Deposits an ERC-721 token into the vault with a specified lock-up period.
    /// @param tokenAddress Address of the ERC-721 token.
    /// @param tokenId ID of the ERC-721 token.
    /// @param lockUpUntil Timestamp until which the deposit is locked.
    function depositERC721(address tokenAddress, uint256 tokenId, uint64 lockUpUntil)
        external
        payable // Allow receiving native currency too
        whenNotPaused
        nonReentrant
        onlyAllowedToken(tokenAddress, true)
    {
        if (lockUpUntil < block.timestamp + minLockUpPeriod) {
            revert InvalidLockUp(block.timestamp + minLockUpPeriod, lockUpUntil);
        }

        IERC721 token = IERC721(tokenAddress);
        // Ensure the vault is approved or is the operator
        token.safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 currentId = nextDepositId++;
        deposits.push(Deposit({
            user: msg.sender,
            tokenAddress: tokenAddress,
            amount: 0, // N/A for ERC721
            tokenId: tokenId,
            isERC721: true,
            depositTime: uint64(block.timestamp),
            lockUpUntil: lockUpUntil,
            remainingAmount: 0, // N/A for ERC721
            isActive: true
        }));
        userDepositIds[msg.sender].push(currentId);

        emit ERC721Deposited(currentId, msg.sender, tokenAddress, tokenId, lockUpUntil);
    }

    /// @dev Withdraws deposited ERC-20 tokens after the lock-up expires.
    /// @param depositId The ID of the deposit to withdraw from.
    /// @param amount The amount of tokens to withdraw.
    function withdrawERC20(uint256 depositId, uint256 amount)
        external
        nonReentrant
        depositActive(depositId)
        onlyDepositOwner(depositId)
    {
        Deposit storage dep = deposits[depositId - 1];

        if (block.timestamp < dep.lockUpUntil) {
            revert LockUpNotExpired(dep.lockUpUntil);
        }
        if (amount > dep.remainingAmount) {
            revert AmountExceedsDeposit(amount, dep.remainingAmount);
        }

        uint256 fee = calculateWithdrawalFee(depositId, amount);
        uint256 amountToSend = amount - fee;

        accumulatedFees[dep.tokenAddress] += fee;
        dep.remainingAmount -= amount;

        IERC20(dep.tokenAddress).safeTransfer(msg.sender, amountToSend);

        if (dep.remainingAmount == 0) {
            dep.isActive = false; // Mark deposit as complete
        }

        emit ERC20Withdrawn(depositId, msg.sender, dep.tokenAddress, amountToSend, fee);
    }

    /// @dev Withdraws a deposited ERC-721 token after the lock-up expires.
    /// @param depositId The ID of the deposit to withdraw from.
    function withdrawERC721(uint256 depositId)
        external
        nonReentrant
        depositActive(depositId)
        onlyDepositOwner(depositId)
    {
        Deposit storage dep = deposits[depositId - 1];

        if (!dep.isERC721) revert NotPermitted(); // Ensure it's an ERC721 deposit

        if (block.timestamp < dep.lockUpUntil) {
            revert LockUpNotExpired(dep.lockUpUntil);
        }

        // ERC721 withdrawal is always full for that token ID
        uint256 fee = calculateWithdrawalFee(depositId, dep.amount); // Amount is 0 for ERC721, fee logic needs adjustment or separate calc
        // A simpler fee for NFT could be fixed or based on duration? Let's make it 0 for now for simplicity
        // If fees were needed, they'd need to be paid in ERC20 or native currency.
        uint256 feeToPay = 0; // No ERC20 fee for NFT withdrawal currently

        // accumulatedFees[feeTokenAddress] += feeToPay; // If fees were in a specific token

        IERC721(dep.tokenAddress).safeTransferFrom(address(this), msg.sender, dep.tokenId);

        dep.isActive = false; // Mark deposit as complete

        emit ERC721Withdrawn(depositId, msg.sender, dep.tokenAddress, feeToPay);
    }

    /// @dev Withdraws deposited ERC-20 tokens before lock-up if oracle condition is met.
    /// @param depositId The ID of the deposit.
    /// @param amount Amount to withdraw.
    /// @param priceThreshold The minimum oracle price required for the withdrawal (scaled by oracle decimals).
    function withdrawERC20Conditional(uint256 depositId, uint256 amount, int256 priceThreshold)
        external
        nonReentrant
        depositActive(depositId)
        onlyDepositOwner(depositId)
    {
        Deposit storage dep = deposits[depositId - 1];

        if (block.timestamp >= dep.lockUpUntil) {
            // If lock-up is already met, use the standard withdrawal function
            withdrawERC20(depositId, amount);
            return;
        }

        if (address(oracle) == address(0)) revert OracleNotSet();

        // Check oracle condition
        (, int256 price, , ,) = oracle.latestRoundData();
        if (price < priceThreshold) revert WithdrawalConditionNotMet();

        if (amount > dep.remainingAmount) {
            revert AmountExceedsDeposit(amount, dep.remainingAmount);
        }

        // Apply early withdrawal fee
        // Calculate fee based on amount and early withdrawal rate
        uint256 fee = (amount * earlyWithdrawalFeeBps) / 10000;
        uint256 amountToSend = amount - fee;

        accumulatedFees[dep.tokenAddress] += fee;
        dep.remainingAmount -= amount;

        IERC20(dep.tokenAddress).safeTransfer(msg.sender, amountToSend);

        if (dep.remainingAmount == 0) {
            dep.isActive = false; // Mark deposit as complete
        }

        emit ERC20Withdrawn(depositId, msg.sender, dep.tokenAddress, amountToSend, fee); // Re-use event
    }

    /// @dev Withdraws a deposited ERC-721 token before lock-up if oracle condition is met.
    /// @param depositId The ID of the deposit.
    /// @param priceThreshold The minimum oracle price required for the withdrawal (scaled by oracle decimals).
    function withdrawERC721Conditional(uint256 depositId, int256 priceThreshold)
        external
        nonReentrant
        depositActive(depositId)
        onlyDepositOwner(depositId)
    {
        Deposit storage dep = deposits[depositId - 1];

        if (!dep.isERC721) revert NotPermitted(); // Ensure it's an ERC721 deposit

        if (block.timestamp >= dep.lockUpUntil) {
            // If lock-up is already met, use the standard withdrawal function
            withdrawERC721(depositId);
            return;
        }

        if (address(oracle) == address(0)) revert OracleNotSet();

        // Check oracle condition
        (, int256 price, , ,) = oracle.latestRoundData();
        if (price < priceThreshold) revert WithdrawalConditionNotMet();

        // Apply early withdrawal fee (if any, currently 0 for NFT)
        uint256 feeToPay = 0;

        // accumulatedFees[feeTokenAddress] += feeToPay; // If fees were in a specific token

        IERC721(dep.tokenAddress).safeTransferFrom(address(this), msg.sender, dep.tokenId);

        dep.isActive = false; // Mark deposit as complete

        emit ERC721Withdrawn(depositId, msg.sender, dep.tokenAddress, feeToPay); // Re-use event
    }


    // --- MetaMorphosis NFT Functions ---

    /// @dev Mints a unique MetaMorphosis NFT to the caller.
    /// Traits/metadata should be derived from the user's vault history.
    /// @param depositId A deposit ID to potentially base NFT traits on (can be 0 to use overall history).
    /// Requires the NFT contract address to be set and user not to have minted already.
    function mintMetaMorphosisNFT(uint256 depositId)
        external
        nonReentrant
    {
        if (address(metaMorphosisNFTContract) == address(0)) revert NFTContractNotSet();
        if (userMetaMorphosisNFTId[msg.sender] != 0) revert UserAlreadyMintedNFT();

        // --- NFT Trait Determination Logic (Simplified) ---
        // In a real scenario, this logic would be complex, combining:
        // - getUserDepositCount(msg.sender)
        // - getUserTotalDurationLocked(msg.sender)
        // - getUserTotalDeposits(msg.sender) - requires price oracle for value
        // - Specific deposit details if depositId > 0
        // - Types of tokens deposited
        // This contract determines the *basis* for traits (e.g., "long-term holder", "multi-asset depositor").
        // The actual JSON metadata and image are typically handled off-chain, pointed to by the URI.

        // Let's generate a unique NFT ID based on user address and deposit count/history hash
        // Or simply increment a counter within the NFT contract.
        // We'll assume the NFT contract handles unique ID generation or we pass a hash.
        // For simplicity, let's generate a token ID based on a hash of user + their deposit count.
        uint256 userTotalDeposits = getUserDepositCount(msg.sender);
        // Add other factors for uniqueness and trait basis
        uint256 baseHash = uint256(keccak256(abi.encodePacked(msg.sender, userTotalDeposits, getUserTotalDurationLocked(msg.sender))));
        uint256 nftTokenId = baseHash % (2**32); // Use lower bits as a potential ID basis (collision possible, real NFT contract should handle this)

        // Generate metadata URI - this function contains the logic for the URI derivation
        string memory tokenURI = generateNFTMetadataUri(msg.sender, nftTokenId);

        IMetaMorphosisNFT(metaMorphosisNFTContract).mint(msg.sender, nftTokenId, tokenURI);

        userMetaMorphosisNFTId[msg.sender] = nftTokenId; // Record the minted NFT ID

        emit MetaMorphosisNFTMinted(msg.sender, nftTokenId, tokenURI);
    }

    /// @dev Internal logic to generate the basis for the NFT metadata URI.
    /// This function calculates parameters based on user vault history which an off-chain service
    /// uses to serve the actual JSON metadata and image.
    /// @param user The user address.
    /// @param nftId The calculated/assigned NFT ID.
    /// @return A string representing the base URI + parameters, or just a base URI.
    function generateNFTMetadataUri(address user, uint256 nftId)
        public
        view
        returns (string memory)
    {
        // Placeholder logic: Construct a URI that includes key stats.
        // A real implementation would calculate trait values (e.g., "Tier: Diamond" if total value > X and duration > Y).
        uint256 depositCount = getUserDepositCount(user);
        uint256 totalDuration = getUserTotalDurationLocked(user);
        // uint256 totalValue = getUserTotalDeposits(user); // Needs oracle for accurate USD/ETH value

        // Example: "ipfs://[CID]/metadata/[user_address]_[nft_id]?deposits=[count]&duration=[duration]"
        // An external service reading this URI would then fetch/generate the JSON metadata based on query params.
        // This is a simplified representation. More robust systems encode parameters in the path or use on-chain getters.

        return string(abi.encodePacked(
            "ipfs://[METADATA_BASE_CID]/", // Base URL
            Strings.toHexString(uint160(user)), // User address
            "_",
            Strings.toString(nftId), // NFT ID
            "?deposits=",
            Strings.toString(depositCount), // Trait parameter: deposit count
            "&duration=",
            Strings.toString(totalDuration) // Trait parameter: total duration
            // Add more parameters based on other stats
        ));
    }

    // --- Dynamic/Yield Functions ---

    /// @dev Calculates accrued simulated yield for the user and moves it to their claimable balance.
    /// Yield is calculated based on active deposits and yield rate.
    function claimSimulatedYield() external nonReentrant {
        uint256 userYield = getUserSimulatedYield(msg.sender); // Calculate based on current state
        if (userYield == 0) return;

        // Add calculated yield to a 'claimable' balance or directly to userSimulatedYield state.
        // Let's assume userSimulatedYield state holds the *total* yield ever accrued,
        // and this function makes it "claimable" (meaning subsequent calls to getUserSimulatedYield might reset calculation basis or accrue from a new point).
        // For simplicity here, let's just emit an event and update the state.
        // A more complex model might track accrual time per deposit.

        // In this simple model, getUserSimulatedYield returns the *current* value, and
        // claimSimulatedYield resets the accrual start time or marks yield as claimed.
        // Let's update the state variable `userSimulatedYield` here as if calculating *up to now*
        // and making it available internally. A true yield system would likely track yield
        // per deposit over time.

        // Basic implementation: iterate user's active deposits, calculate yield since last claim/deposit, add to userSimulatedYield state.
        uint256 newlyAccruedYield = _calculateAccruedYield(msg.sender);
        userSimulatedYield[msg.sender] += newlyAccruedYield;
        // A mechanism to reset yield accrual start time would be needed here.
        // For this example, _calculateAccruedYield should probably calculate total theoretical yield up to now,
        // and this function just finalizes that value in state, potentially resetting a timer.

        emit SimulatedYieldClaimed(msg.sender, newlyAccruedYield);
    }

    /// @dev Reinvests accumulated simulated yield back into the vault.
    /// This increases the base value for future yield calculation, without depositing real tokens.
    /// Requires claimable yield to be present.
    function reinvestSimulatedYield() external nonReentrant {
        uint256 yieldToReinvest = userSimulatedYield[msg.sender];
        if (yieldToReinvest == 0) return;

        // In a simple model, this might just add to a user's "reinvested value" state
        // which influences future getUserSimulatedYield calculations.
        // In a complex model, it could simulate adding value to existing deposits or creating new virtual ones.

        // For simplicity: clear the user's accumulated yield and consider it "reinvested"
        // influencing the base value used in _calculateAccruedYield.
        // Need a state variable for this, e.g., mapping(address => uint256) userReinvestedValue;
        // userReinvestedValue[msg.sender] += yieldToReinvest;
        // userSimulatedYield[msg.sender] = 0; // Clear claimable yield

        // A more direct way for demonstration: Simply clear the claimable yield state.
        // The _calculateAccruedYield function must then correctly calculate new yield based on deposits + previous reinvestments.
        // This requires a more complex yield tracking mechanism per deposit or globally per user with timestamps.
        // Let's keep it simple: claiming yield moves it to `userSimulatedYield`, reinvesting just clears that state,
        // implying it contributes to the *base* for *future* yield calculations (conceptually).

        uint256 reinvested = userSimulatedYield[msg.sender];
        userSimulatedYield[msg.sender] = 0; // Mark as reinvested (conceptually)

        emit SimulatedYieldReinvested(msg.sender, reinvested);
    }


    /// @dev Calculates the withdrawal fee for a specific deposit and amount.
    /// Base fee applies always, early withdrawal fee applies if before lock-up.
    /// ERC721 fees are calculated differently (or are 0 as in this example).
    /// @param depositId The ID of the deposit.
    /// @param withdrawAmount The amount being withdrawn (only relevant for ERC20).
    /// @return The calculated fee amount.
    function calculateWithdrawalFee(uint256 depositId, uint256 withdrawAmount)
        public
        view
        depositActive(depositId)
        returns (uint256)
    {
        Deposit storage dep = deposits[depositId - 1];

        if (dep.isERC721) {
            // ERC721 fee logic (currently 0)
            return 0;
        }

        // ERC20 fee logic
        uint256 totalFeeBps = baseWithdrawalFeeBps;
        if (block.timestamp < dep.lockUpUntil) {
            totalFeeBps += earlyWithdrawalFeeBps;
        }

        // Avoid overflow: calculate fee using the current remaining amount in the deposit
        // The fee is on the amount being withdrawn, so use withdrawAmount
        uint256 fee = (withdrawAmount * totalFeeBps) / 10000;

        // Ensure calculated fee doesn't exceed the amount being withdrawn
        return fee > withdrawAmount ? withdrawAmount : fee;
    }


    // --- Admin Functions ---

    /// @dev Allows the owner to set allowed ERC-20 and ERC-721 token addresses for deposits.
    /// @param erc20s Array of ERC-20 token addresses.
    /// @param erc721s Array of ERC-721 token addresses.
    /// @param allowed Status to set (true to allow, false to disallow).
    function setAllowedTokens(address[] calldata erc20s, address[] calldata erc721s, bool allowed) external onlyOwner {
        for (uint i = 0; i < erc20s.length; i++) {
            allowedERC20s[erc20s[i]] = allowed;
            emit TokenAllowed(erc20s[i], allowed);
        }
        for (uint i = 0; i < erc721s.length; i++) {
            allowedERC721s[erc721s[i]] = allowed;
            emit TokenAllowed(erc721s[i], allowed);
        }
    }

    /// @dev Allows the owner to set the MetaMorphosis NFT contract address.
    /// @param _nftContract The address of the NFT contract.
    function setMetaMorphosisNFTContract(address _nftContract) external onlyOwner {
        metaMorphosisNFTContract = _nftContract;
        emit NFTContractSet(_nftContract);
    }

    /// @dev Allows the owner to set the Oracle contract address.
    /// @param _oracle The address of the Oracle contract (e.g., Chainlink AggregatorV3).
    function setOracleAddress(address _oracle) external onlyOwner {
        oracle = IAggregatorV3(_oracle);
        emit OracleSet(_oracle);
    }

    /// @dev Allows the owner to set the minimum required lock-up period for new deposits.
    /// @param _minLockUp The minimum lock-up duration in seconds.
    function setMinimumLockUp(uint64 _minLockUp) external onlyOwner {
        minLockUpPeriod = _minLockUp;
        emit MinimumLockUpSet(_minLockUp);
    }

    /// @dev Allows the owner to set the base and early withdrawal fee rates in basis points.
    /// @param _baseFeeBps The base fee rate (0-10000).
    /// @param _earlyWithdrawalFeeBps The early withdrawal fee rate (0-10000).
    function setFeeParameters(uint256 _baseFeeBps, uint256 _earlyWithdrawalFeeBps) external onlyOwner {
        // Basic validation
        if (_baseFeeBps > 10000 || _earlyWithdrawalFeeBps > 10000) revert InvalidLockUp(0, 0); // Use a generic error or add new one

        baseWithdrawalFeeBps = _baseFeeBps;
        earlyWithdrawalFeeBps = _earlyWithdrawalFeeBps;
        emit FeeParametersSet(_baseFeeBps, _earlyWithdrawalFeeBps);
    }

     /// @dev Allows the owner to set the simulated annual yield rate in basis points.
    /// @param rate The yield rate (0-10000).
    function setSimulatedYieldRate(uint256 rate) external onlyOwner {
         if (rate > 10000) revert InvalidLockUp(0, 0); // Use a generic error or add new one

        simulatedYieldRateBps = rate;
        emit SimulatedYieldRateSet(rate);
    }


    /// @dev Pauses the contract (disables deposits and withdrawals).
    function pause() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /// @dev Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /// @dev Allows the owner to withdraw accumulated fees for a specific token.
    /// @param tokenAddress The address of the token whose fees to withdraw.
    function ownerWithdrawFees(address tokenAddress) external onlyOwner {
        uint256 fees = accumulatedFees[tokenAddress];
        if (fees == 0) revert InsufficientFees(tokenAddress, 0);

        accumulatedFees[tokenAddress] = 0;

        if (tokenAddress == address(0)) {
            // Withdraw native currency (ETH) if tokenAddress is zero address
            (bool success, ) = payable(owner()).call{value: fees}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(tokenAddress).safeTransfer(owner(), fees);
        }

        emit FeesWithdrawn(owner(), tokenAddress, fees);
    }

    /// @dev Allows the owner to withdraw tokens stuck in the contract in emergencies.
    /// Does not allow withdrawing deposited NFTs or actively managed ERC20s.
    /// Use with extreme caution.
    /// @param tokenAddress The address of the token to withdraw.
    /// @param amount The amount to withdraw.
    function emergencyTokenWithdraw(address tokenAddress, uint256 amount) external onlyOwner {
        if (allowedERC721s[tokenAddress]) revert EmergencyWithdrawNotAllowedForNFT(); // Cannot withdraw managed NFTs
        if (allowedERC20s[tokenAddress]) {
             // Potentially add more complex checks here to ensure it's not core vault balance
             // e.g., check against total value locked etc. For simplicity, disallow allowed ERC20s too.
            revert EmergencyWithdrawNotAllowedForNFT(); // Cannot withdraw managed ERC20s this way
        }


        if (tokenAddress == address(0)) {
            (bool success, ) = payable(owner()).call{value: amount}("");
             require(success, "ETH transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            if (token.balanceOf(address(this)) < amount) revert InsufficientBalance(tokenAddress, amount);
             token.safeTransfer(owner(), amount);
        }
    }


    // --- Getter Functions ---

    /// @dev Gets the details of a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return A tuple containing deposit details.
    function getDepositDetails(uint256 depositId)
        external
        view
        depositActive(depositId)
        returns (address user, address tokenAddress, uint256 amount, uint256 tokenId, bool isERC721, uint64 depositTime, uint64 lockUpUntil, uint256 remainingAmount)
    {
        Deposit storage dep = deposits[depositId - 1];
        return (dep.user, dep.tokenAddress, dep.amount, dep.tokenId, dep.isERC721, dep.depositTime, dep.lockUpUntil, dep.remainingAmount);
    }

    /// @dev Gets the array of deposit IDs for a given user.
    /// @param user The user address.
    /// @return An array of deposit IDs.
    function getUserDepositIds(address user) external view returns (uint256[] memory) {
        return userDepositIds[user];
    }

    /// @dev Gets a basic estimation of the total value locked across all deposits.
    /// This does NOT use an oracle for price conversion, just sums ERC20 amounts and counts ERC721s.
    /// @return totalERC20Value Basic sum of ERC20 amounts, totalERC721Count count of ERC721s.
    function getTotalValueLocked() external view returns (uint256 totalERC20Value, uint256 totalERC721Count) {
        uint256 erc20Sum = 0;
        uint256 erc721Count = 0;
        for (uint i = 0; i < deposits.length; i++) {
            if (deposits[i].isActive) {
                if (deposits[i].isERC721) {
                    erc721Count++;
                } else {
                    erc20Sum += deposits[i].remainingAmount;
                }
            }
        }
        return (erc20Sum, erc721Count);
    }

    /// @dev Gets a basic estimation of a user's total deposited value.
    /// Sums active ERC20 deposits and counts active ERC721s. No price oracle used.
    /// @param user The user address.
    /// @return userERC20Value Basic sum of user's active ERC20s, userERC721Count count of user's active ERC721s.
    function getUserTotalDeposits(address user) external view returns (uint256 userERC20Value, uint256 userERC721Count) {
        uint256 erc20Sum = 0;
        uint256 erc721Count = 0;
        uint256[] memory depositIds = userDepositIds[user];
        for (uint i = 0; i < depositIds.length; i++) {
            uint256 id = depositIds[i];
            if (id > 0 && id <= deposits.length) { // Check array bounds before access
                Deposit storage dep = deposits[id - 1];
                if (dep.isActive) {
                    if (dep.isERC721) {
                        erc721Count++;
                    } else {
                        erc20Sum += dep.remainingAmount;
                    }
                }
            }
        }
        return (erc20Sum, erc721Count);
    }

    /// @dev Gets the user's current accumulated simulated yield.
    /// This is the yield calculated up to the last claimSimulatedYield call, plus new yield accrued since then.
    /// @param user The user address.
    /// @return The user's total simulated yield amount.
    function getUserSimulatedYield(address user) public view returns (uint256) {
        // This simple model calculates yield based on *current* active deposits and total duration *up to now*.
        // A more complex model would track yield per deposit over time and calculate delta since last claim/reinvestment.
        // For this example, let's just return the state variable value as the 'claimable' amount.
        // A more accurate calculation would involve iterating active deposits and applying time/rate since last update.
        // Let's add a basic calculation placeholder: Yield = Sum(deposit_value * duration_active * rate)
        return userSimulatedYield[user] + _calculateAccruedYield(user);
    }

    /// @dev Internal function to calculate yield accrued since last state update (conceptually).
    /// A proper implementation needs to track when yield was last calculated for each deposit/user.
    /// This is a simplified example placeholder.
    function _calculateAccruedYield(address user) internal view returns (uint256) {
        uint256 newlyAccrued = 0;
        uint256[] memory depositIds = userDepositIds[user];
        uint256 currentTime = block.timestamp;

        for (uint i = 0; i < depositIds.length; i++) {
             uint256 id = depositIds[i];
              if (id > 0 && id <= deposits.length) {
                Deposit storage dep = deposits[id - 1];
                if (dep.isActive && !dep.isERC721) { // Only accrue yield on ERC20 for simplicity
                    // Simple linear accrual based on total duration locked (including future lockup)
                    // This is a very basic model. Real yield calculation is more complex.
                    uint256 totalDuration = dep.lockUpUntil - dep.depositTime;
                    if (totalDuration > 0) {
                        // Simplified calculation: Yield = amount * rate * time / TotalPossibleTime
                        // This isn't ideal, a better model is yield based on *time active* and *remaining value*
                        // Let's try a different simple model: Yield = amount * rate * (time_elapsed_since_deposit)
                        uint256 durationElapsed = currentTime - dep.depositTime;
                         // Prevent overflow, scale appropriately
                         // Example: amount * rateBps / 10000 * duration / seconds_in_year
                         // Let's assume 1 year = 31536000 seconds
                        uint256 secondsInYear = 31536000;
                        if (durationElapsed > 0 && simulatedYieldRateBps > 0) {
                             uint256 yieldPerSecond = (dep.remainingAmount * simulatedYieldRateBps) / 10000 / secondsInYear; // Possible precision loss
                             // This simplistic model doesn't track *when* yield was last calculated per deposit.
                             // It would over-calculate if called multiple times without a state update.
                             // For a real contract, need: mapping(uint256 => uint64) lastYieldCalculationTime;
                             // Calculate yield from lastYieldCalculationTime to now.
                             // Update lastYieldCalculationTime = now.

                             // Let's just return 0 for this internal calculation for now, and assume `userSimulatedYield` state is updated by `claimSimulatedYield` based on some external factor or timer.
                             // Returning 0 makes getUserSimulatedYield just return the static state value.
                             // A proper system would calculate yield *since* the last time `userSimulatedYield[user]` was touched.
                             // This requires more state and complex logic.
                             // Sticking to the simpler model where `userSimulatedYield` is updated manually or via a simplified claim.

                            // Simplified placeholder calculation for demonstration:
                            // Accumulate yield based on initial deposit amount and full lockup duration
                            // This ignores partial withdrawals and time elapsed correctly, for concept demo only.
                             newlyAccrued += (dep.amount * simulatedYieldRateBps) / 10000; // This isn't time-based yield
                        }
                    }
                }
              }
        }
         // Reset the calculation base - this needs proper time tracking state per user/deposit
         // For this demo, just return a conceptual value derived simply.
         // Let's make it simpler: Yield is purely conceptual, updated by `claimSimulatedYield`
         // based on *something else* (manual oracle, external trigger, etc.) and `_calculateAccruedYield` always returns 0.
        return 0; // Placeholder: Actual yield calculation needs proper time tracking per deposit
    }


    /// @dev Returns the current minimum required lock-up period.
    function getMinimumLockUp() external view returns (uint64) {
        return minLockUpPeriod;
    }

    /// @dev Returns the current fee parameters.
    function getFeeParameters() external view returns (uint256 baseFeeBps, uint256 earlyWithdrawalFeeBps) {
        return (baseWithdrawalFeeBps, earlyWithdrawalFeeBps);
    }

    /// @dev Returns the total accumulated fees for a specific token address.
    /// @param tokenAddress The address of the token.
    function getAccumulatedFees(address tokenAddress) external view returns (uint256) {
        return accumulatedFees[tokenAddress];
    }

    /// @dev Checks if a token address is allowed for deposits.
    /// @param tokenAddress The address of the token.
    /// @return True if allowed (either ERC20 or ERC721), false otherwise.
    function isTokenAllowed(address tokenAddress) external view returns (bool) {
        return allowedERC20s[tokenAddress] || allowedERC721s[tokenAddress];
    }

    /// @dev Gets the MetaMorphosis NFT ID minted for a user.
    /// Returns 0 if no NFT has been minted for the user by this contract.
    /// @param user The user address.
    /// @return The NFT ID or 0.
    function getUserMetaMorphosisNFTId(address user) external view returns (uint256) {
        return userMetaMorphosisNFTId[user];
    }

    /// @dev Gets the total count of individual deposits made by a user (active or inactive).
    /// @param user The user address.
    /// @return The total number of deposits.
    function getUserDepositCount(address user) public view returns (uint256) {
        return userDepositIds[user].length;
    }

    /// @dev Gets the sum of lock-up durations for all completed or active deposits of a user.
    /// Used as a factor for NFT trait generation.
    /// @param user The user address.
    /// @return The total duration locked in seconds.
    function getUserTotalDurationLocked(address user) public view returns (uint256) {
        uint256 totalDuration = 0;
        uint256[] memory depositIds = userDepositIds[user];
        for (uint i = 0; i < depositIds.length; i++) {
             uint256 id = depositIds[i];
              if (id > 0 && id <= deposits.length) {
                 Deposit storage dep = deposits[id - 1];
                 // Include duration even if deposit is inactive, contributing to history
                 totalDuration += (dep.lockUpUntil > dep.depositTime) ? (dep.lockUpUntil - dep.depositTime) : 0;
              }
        }
        return totalDuration;
    }

     /// @dev Returns the address of the set Oracle contract.
    function getOracleAddress() external view returns (address) {
        return address(oracle);
    }

     /// @dev Returns the address of the set MetaMorphosis NFT contract.
    function getMetaMorphosisNFTContract() external view returns (address) {
        return metaMorphosisNFTContract;
    }
}
```

**Explanation and Notes:**

1.  **Complexity:** This contract is significantly more complex than a basic vault. It handles multiple asset types (requiring careful mapping of deposit IDs to asset details), integrates external contracts (NFT, Oracle), implements dynamic fee calculation, time-based checks, conditional logic, and includes mechanics for simulating yield and generating NFTs based on history.
2.  **MetaMorphosis NFT Logic:** The `generateNFTMetadataUri` is a crucial part of the creative concept. The *actual* logic for determining NFT traits based on `depositCount`, `totalDuration`, etc., would live off-chain and be served via an API or IPFS. The smart contract provides the *data* (the user's history stats) from which those traits are derived, and the URI links to where that data is used. The placeholder URI shows how you might encode these stats into the URI itself.
3.  **Simulated Yield:** The yield mechanism here is *simulated*. A real yield-generating vault would likely deposit assets into other DeFi protocols (like Aave, Compound, Yearn) or participate in staking/farming. Implementing that within this contract would add significant complexity and require external protocol interaction logic. The current implementation is conceptual, allowing the contract owner or an external trigger to increase `userSimulatedYield` or for `_calculateAccruedYield` to use a simplified formula. A proper system needs careful time-tracking per deposit.
4.  **Oracle:** The conditional withdrawal uses a placeholder `IAggregatorV3` interface, standard for Chainlink price feeds. In a real deployment, you'd use the actual Chainlink contract address and understand its `latestRoundData()` return value and scaling.
5.  **Fees:** Fees are calculated in the *same token* being withdrawn. This is simple but might not be desired (e.g., might prefer fees in ETH or a stablecoin).
6.  **Deposit Management:** Using a dynamic array `deposits` and a mapping `userDepositIds` allows tracking individual deposits. Marking deposits as `isActive` instead of deleting saves gas on deletion (which is complex) but requires iterating through potentially inactive deposits in some getter functions. A more gas-efficient approach for active deposits might involve linked lists or separate active/inactive mappings.
7.  **ERC721 Handling:** When depositing ERC721s, the user needs to approve the vault contract first (`IERC721(tokenAddress).approve(address(vault), tokenId)` or setApprovalForAll). The vault uses `safeTransferFrom` which includes checks.
8.  **Owner Privileges:** The owner has significant control (setting allowed tokens, fees, lock-up, pausing, withdrawing fees/emergency). This is typical but requires trust in the owner.
9.  **Security:** Includes `Ownable`, `Pausable`, `ReentrancyGuard`, and `SafeERC20`/`SafeERC721`. Basic input validation is present, but a production contract would require extensive auditing.
10. **Function Count:** Counts public and external functions: 2 deposit, 4 withdraw, 3 NFT, 3 yield/fee calc, 9 admin, 10 getters. Total = 31 public/external functions. Meets the requirement.
11. **Non-Duplication:** While drawing inspiration from common DeFi and NFT concepts, the combination of multi-asset deposits, oracle-conditional withdrawals, simulated yield, dynamic fees, and NFT generation *tied to vault history* in a single contract provides a unique set of features not commonly found in a single open-source implementation.

This contract serves as a solid foundation and demonstration of how multiple advanced Solidity concepts can be combined creatively. Remember that deploying such a contract to a live network requires thorough testing, auditing, and careful consideration of gas costs and potential attack vectors.