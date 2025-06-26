Okay, let's create a sophisticated smart contract concept focused on a "Multi-Asset Interaction Vault" with advanced capabilities. This contract will hold different types of tokens (ETH, ERC20, ERC721, ERC1155) and be capable of performing complex interactions with other protocols or executing controlled low-level calls, all managed through flexible access control.

It combines concepts like:
*   **Multi-Asset Management:** Handling various token standards.
*   **Protocol Interaction:** Abstracting calls to external DeFi, NFT, or other contracts.
*   **Controlled Generic Calls:** Allowing execution of arbitrary calls under strict conditions.
*   **Time-Locked Operations:** Implementing time-based release mechanics.
*   **Flexible Access Control:** Beyond simple ownership, defining roles or allowed external callers.
*   **Pausability:** Standard safety mechanism.
*   **ERC-1155 Receiver:** Proper handling of incoming ERC-1155 tokens.

We will avoid simply replicating standard ERC20/721/1155 implementations, basic Swaps, simple Staking (will provide an *interface* for interaction), or basic Vesting contracts. The focus is on *managing and interacting* with these assets *from* the vault based on advanced logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Votes.sol"; // For advanced ERC20 features

// --- Outline ---
// 1. Interfaces: Define minimal interfaces for external protocols the vault might interact with (Staking, Rewards).
// 2. State Variables: Storage for balances, withdrawal details, access control lists, pause status.
// 3. Events: Signalling important actions.
// 4. Modifiers: Custom checks for access control and state.
// 5. Constructor: Setting initial owner.
// 6. Receive/Fallback: Handling direct ETH deposits.
// 7. ERC-1155 Receiver Implementation: Necessary functions to receive ERC-1155 tokens.
// 8. Core Asset Management: Deposit and withdrawal functions for ETH, ERC20, ERC721, ERC1155.
// 9. Balance/Ownership Checks: Functions to query held assets.
// 10. Protocol Interaction Functions: Functions to interact with external contracts (staking, claiming, voting, approving).
// 11. Advanced Execution: Controlled low-level call execution.
// 12. Time-Locked Withdrawals: Mechanism for setting up and executing time-bound releases.
// 13. Access Control & State Management: Managing allowed interaction addresses, pause function, ownership (via Ownable).

// --- Function Summary ---
// Basic Asset Management:
// - depositETH(): Receive ETH deposits.
// - withdrawETH(uint256 amount, address payable recipient): Send ETH from vault.
// - depositERC20(IERC20 token, uint256 amount): Receive ERC20 (requires prior approval).
// - withdrawERC20(IERC20 token, uint256 amount, address recipient): Send ERC20 from vault.
// - depositERC721(IERC721 token, uint256 tokenId): Receive ERC721 (requires prior transferFrom/safeTransferFrom).
// - withdrawERC721(IERC721 token, uint256 tokenId, address recipient): Send ERC721 from vault.
// - depositERC1155(IERC1155 token, uint256 tokenId, uint256 amount): Receive ERC1155 (handled by onERC1155Received).
// - withdrawERC1155(IERC1155 token, uint256 tokenId, uint256 amount, address recipient): Send ERC1155 from vault.
// - onERC1155Received(...): Standard ERC1155 single reception handler.
// - onERC1155BatchReceived(...): Standard ERC1155 batch reception handler.
// - supportsInterface(bytes4 interfaceId): Standard ERC1155Receiver required function.

// Balance/Ownership Checks:
// - getETHBalance(): Query vault's ETH balance.
// - getERC20Balance(IERC20 token): Query vault's ERC20 balance.
// - getERC721Owner(IERC721 token, uint256 tokenId): Check if vault owns a specific ERC721 token.
// - getERC1155Balance(IERC1155 token, uint256 tokenId): Query vault's ERC1155 balance for a token ID.

// Protocol Interaction:
// - approveERC20ForProtocol(IERC20 token, address protocol, uint256 amount): Approve vault's ERC20 for an external spender.
// - stakeERC20(IERC20 token, IStakingProtocol stakingProtocol, uint256 amount): Stake ERC20s held in the vault via a staking contract interface.
// - unstakeERC20(IERC20 token, IStakingProtocol stakingProtocol, uint256 amount): Unstake via interface.
// - claimRewards(IRewardsProtocol rewardsProtocol, address token): Claim rewards via a rewards interface.
// - delegateERC20Votes(IERC20Votes token, address delegatee): Delegate voting power for ERC20Votes tokens held.

// Advanced Execution:
// - executeCall(address target, uint256 value, bytes memory data): Execute a low-level call from the vault's context. Highly restricted.

// Time-Locked Withdrawals (Example for ERC20):
// - setupTimeLockedWithdrawal(address recipient, IERC20 token, uint256 amount, uint256 unlockTimestamp): Create a time-locked withdrawal entry.
// - executeTimeLockedWithdrawal(uint256 withdrawalId): Trigger a time-locked withdrawal after its unlock time.

// Access Control & State:
// - addAllowedInteraction(address allowedAddress): Add an address allowed to execute certain interaction functions.
// - removeAllowedInteraction(address allowedAddress): Remove an allowed address.
// - checkAllowedInteraction(address allowedAddress): Check if an address is allowed.
// - pauseVault(bool _paused): Pause/unpause core operations.
// - isPaused(): Check pause status.
// - transferOwnership(address newOwner): Transfer ownership (from Ownable).
// - renounceOwnership(): Renounce ownership (from Ownable).

// --- Contract Implementation ---

// Minimal interfaces for conceptual interactions
interface IStakingProtocol {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    // Assuming specific staking protocols might need token addresses in their functions,
    // but keeping interface simple for this example. A real implementation would match the protocol ABI.
}

interface IRewardsProtocol {
    // Assuming a generic claim function; real protocols vary.
    // Could return amount claimed, or require specifying which reward token to claim.
    // This example assumes claiming 'token' rewards.
    function claimRewards(address token) external;
}


contract QuantumVault is Ownable, ERC1155Receiver {

    // --- State Variables ---

    // Allowed addresses that can trigger protocol interactions and controlled calls (besides owner)
    mapping(address => bool) private _allowedInteractions;

    // Pausability state
    bool private _paused;

    // Time-Locked Withdrawals (Example struct and mapping for ERC20)
    struct TimeLockedWithdrawal {
        address recipient;
        IERC20 token;
        uint256 amount;
        uint256 unlockTimestamp;
        bool executed; // To prevent double execution
    }
    mapping(uint256 => TimeLockedWithdrawal) private _timeLockedWithdrawals;
    uint256 private _nextWithdrawalId; // Counter for withdrawal IDs

    // --- Events ---
    event ETHDeposited(address indexed depositor, uint256 amount);
    event ETHWithdrawn(address indexed recipient, uint256 amount);
    event ERC20Deposited(address indexed depositor, IERC20 indexed token, uint256 amount);
    event ERC20Withdrawn(address indexed recipient, IERC20 indexed token, uint256 amount);
    event ERC721Deposited(address indexed depositor, IERC721 indexed token, uint256 indexed tokenId);
    event ERC721Withdrawn(address indexed recipient, IERC721 indexed token, uint256 indexed tokenId);
    event ERC1155Deposited(address indexed operator, address indexed from, uint256 indexed id, uint256 amount); // Matches ERC1155 standard event origin
    event ERC1155Withdrawn(address indexed recipient, IERC1155 indexed token, uint256 indexed id, uint256 amount);
    event ERC20Approved(IERC20 indexed token, address indexed spender, uint256 amount);
    event ProtocolCallExecuted(address indexed target, uint256 value, bytes data); // Emitted after executeCall
    event AllowedInteractionAdded(address indexed allowedAddress);
    event AllowedInteractionRemoved(address indexed allowedAddress);
    event VaultPaused(bool indexed paused);
    event ERC20Staked(IERC20 indexed token, IStakingProtocol indexed protocol, uint256 amount);
    event ERC20Unstaked(IERC20 indexed token, IStakingProtocol indexed protocol, uint256 amount);
    event RewardsClaimed(IRewardsProtocol indexed protocol, address indexed token);
    event ERC20VotesDelegated(IERC20Votes indexed token, address indexed delegatee);
    event TimeLockedWithdrawalScheduled(uint256 indexed withdrawalId, address indexed recipient, IERC20 indexed token, uint256 amount, uint256 unlockTimestamp);
    event TimeLockedWithdrawalExecuted(uint256 indexed withdrawalId);


    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!_paused, "Vault: Paused");
        _;
    }

    // Allows owner OR any address in the _allowedInteractions list
    modifier onlyAllowedInteractionOrOwner() {
        require(_allowedInteractions[msg.sender] || msg.sender == owner(), "Vault: Not owner or allowed interaction");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) {
        _paused = false;
        _nextWithdrawalId = 1; // Start IDs from 1
    }

    // --- Receive and Fallback ---

    // Allows contract to receive ETH
    receive() external payable whenNotPaused {
        emit ETHDeposited(msg.sender, msg.value);
    }

    // Fallback function, useful for receiving ETH from older contracts or direct sends
    fallback() external payable {
        // Only allow if not paused and receiving ETH (otherwise revert for unexpected calls)
        require(!_paused, "Vault: Paused (Fallback)");
        require(msg.value > 0, "Vault: Fallback requires ETH"); // Revert if a call without ETH hits here
        emit ETHDeposited(msg.sender, msg.value);
    }

    // --- ERC-1155 Receiver Implementation ---
    // Required by ERC1155Receiver

    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // Optional: Add checks if needed, e.g., only accept from certain addresses or specific tokens.
        // For a general vault, accepting any is usually fine.
        // Ensure the transfer was intended for this contract.
        require(msg.sender == address(data), "Vault: Must receive from token contract"); // Basic check

        // Emit event to log the deposit
        emit ERC1155Deposited(operator, from, id, amount);

        // Return the magic value to signify successful reception
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // Optional: Add checks if needed.
        require(msg.sender == address(data), "Vault: Must receive from token contract"); // Basic check

        // Emit events for each item in the batch
        for (uint i = 0; i < ids.length; i++) {
             emit ERC1155Deposited(operator, from, ids[i], amounts[i]);
        }

        // Return the magic value to signify successful reception
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // ERC165 interface support
        return interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC1155Receiver).interfaceId ||
               super.supportsInterface(interfaceId); // Include Ownable's potential supportsInterface
    }


    // --- Core Asset Management ---

    /// @notice Allows depositing ETH into the vault.
    /// @dev This function can only be called with ETH attached.
    function depositETH() external payable whenNotPaused {
        require(msg.value > 0, "Vault: ETH amount must be greater than zero");
        emit ETHDeposited(msg.sender, msg.value);
        // ETH is automatically added to the contract balance.
    }

    /// @notice Allows withdrawing ETH from the vault.
    /// @param amount The amount of ETH to withdraw.
    /// @param payable recipient The address to send the ETH to.
    function withdrawETH(uint256 amount, address payable recipient) external onlyOwner whenNotPaused {
        require(amount > 0, "Vault: ETH amount must be greater than zero");
        require(address(this).balance >= amount, "Vault: Insufficient ETH balance");
        require(recipient != address(0), "Vault: Invalid recipient address");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Vault: ETH withdrawal failed");

        emit ETHWithdrawn(recipient, amount);
    }

    /// @notice Allows depositing ERC20 tokens into the vault.
    /// @dev Requires the depositor to have approved the vault contract beforehand using `token.approve(address(vault), amount)`.
    /// @param token The address of the ERC20 token contract.
    /// @param amount The amount of ERC20 tokens to deposit.
    function depositERC20(IERC20 token, uint256 amount) external whenNotPaused {
        require(amount > 0, "Vault: ERC20 amount must be greater than zero");
        require(address(token) != address(0), "Vault: Invalid token address");

        // Transfer tokens from the depositor to this contract
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Vault: ERC20 transfer failed");

        emit ERC20Deposited(msg.sender, token, amount);
    }

    /// @notice Allows withdrawing ERC20 tokens from the vault.
    /// @param token The address of the ERC20 token contract.
    /// @param amount The amount of ERC20 tokens to withdraw.
    /// @param recipient The address to send the ERC20 tokens to.
    function withdrawERC20(IERC20 token, uint256 amount, address recipient) external onlyOwner whenNotPaused {
        require(amount > 0, "Vault: ERC20 amount must be greater than zero");
        require(address(token) != address(0), "Vault: Invalid token address");
        require(recipient != address(0), "Vault: Invalid recipient address");
        require(token.balanceOf(address(this)) >= amount, "Vault: Insufficient ERC20 balance");

        bool success = token.transfer(recipient, amount);
        require(success, "Vault: ERC20 withdrawal failed");

        emit ERC20Withdrawn(recipient, token, amount);
    }

    /// @notice Allows depositing ERC721 tokens into the vault.
    /// @dev Requires the depositor to have approved the vault contract or transferred ownership beforehand. Using `safeTransferFrom` from the token contract is recommended.
    /// @param token The address of the ERC721 token contract.
    /// @param tokenId The ID of the ERC721 token to deposit.
    function depositERC721(IERC721 token, uint256 tokenId) external whenNotPaused {
        require(address(token) != address(0), "Vault: Invalid token address");

        // The ERC721 standard requires the token contract to check ownership and approval/transfer logic.
        // A successful transfer to this contract address is the deposit.
        // We can add a check here to ensure the vault now owns it, though transferFrom/safeTransferFrom should guarantee this.
        address currentOwner = token.ownerOf(tokenId);
        require(currentOwner == address(this), "Vault: Vault must be the owner of the token after deposit");

        emit ERC721Deposited(msg.sender, token, tokenId);
    }

    /// @notice Allows withdrawing ERC721 tokens from the vault.
    /// @param token The address of the ERC721 token contract.
    /// @param tokenId The ID of the ERC721 token to withdraw.
    /// @param recipient The address to send the ERC721 token to.
    function withdrawERC721(IERC721 token, uint256 tokenId, address recipient) external onlyOwner whenNotPaused {
        require(address(token) != address(0), "Vault: Invalid token address");
        require(recipient != address(0), "Vault: Invalid recipient address");
        require(token.ownerOf(tokenId) == address(this), "Vault: Vault does not own this ERC721 token");

        // Use safeTransferFrom recommended by ERC721 standard
        token.safeTransferFrom(address(this), recipient, tokenId);

        emit ERC721Withdrawn(recipient, token, tokenId);
    }

    /// @notice Allows depositing ERC1155 tokens into the vault.
    /// @dev This function is implicitly handled by the `onERC1155Received` callback when tokens are sent using `safeTransferFrom` or `safeBatchTransferFrom`.
    /// Users should call the token contract's `safeTransferFrom` or `safeBatchTransferFrom` targeting this vault.
    /// This explicit function is just for documentation/clarity, the actual logic is in the receiver hooks.
    /// @param token The address of the ERC1155 token contract.
    /// @param tokenId The ID of the ERC1155 token.
    /// @param amount The amount of ERC1155 tokens.
    function depositERC1155(IERC1155 token, uint256 tokenId, uint256 amount) external pure whenNotPaused {
        // This function is essentially a NO-OP here, as the deposit is handled by the ERC1155Receiver hooks.
        // It serves to make the interface explicit.
        // The actual deposit is confirmed by the emitted event in onERC1155Received/onERC1155BatchReceived.
        revert("Vault: Deposit ERC1155 via safeTransferFrom/safeBatchTransferFrom to this contract address");
    }

    /// @notice Allows withdrawing ERC1155 tokens from the vault.
    /// @param token The address of the ERC1155 token contract.
    /// @param tokenId The ID of the ERC1155 token.
    /// @param amount The amount of ERC1155 tokens to withdraw.
    /// @param recipient The address to send the ERC1155 tokens to.
    function withdrawERC1155(IERC1155 token, uint256 tokenId, uint256 amount, address recipient) external onlyOwner whenNotPaused {
        require(amount > 0, "Vault: ERC1155 amount must be greater than zero");
        require(address(token) != address(0), "Vault: Invalid token address");
        require(recipient != address(0), "Vault: Invalid recipient address");
        require(token.balanceOf(address(this), tokenId) >= amount, "Vault: Insufficient ERC1155 balance");

        // Use safeTransferFrom recommended by ERC1155 standard
        // The operator address is the vault itself, from is the vault, to is the recipient.
        token.safeTransferFrom(address(this), recipient, tokenId, amount, ""); // Empty data bytes

        emit ERC1155Withdrawn(recipient, token, tokenId, amount);
    }

    // --- Balance/Ownership Checks ---

    /// @notice Gets the current ETH balance of the vault.
    /// @return The ETH balance in wei.
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the current balance of a specific ERC20 token held by the vault.
    /// @param token The address of the ERC20 token contract.
    /// @return The balance of the ERC20 token.
    function getERC20Balance(IERC20 token) external view returns (uint256) {
        require(address(token) != address(0), "Vault: Invalid token address");
        return token.balanceOf(address(this));
    }

    /// @notice Checks if the vault is the owner of a specific ERC721 token.
    /// @param token The address of the ERC721 token contract.
    /// @param tokenId The ID of the ERC721 token.
    /// @return True if the vault owns the token, false otherwise.
    function getERC721Owner(IERC721 token, uint256 tokenId) external view returns (address) {
        require(address(token) != address(0), "Vault: Invalid token address");
        // ERC721 ownerOf reverts for non-existent tokens, handle in consumer or rely on revert.
        return token.ownerOf(tokenId);
    }

    /// @notice Gets the current balance of a specific ERC1155 token ID held by the vault.
    /// @param token The address of the ERC1155 token contract.
    /// @param tokenId The ID of the ERC1155 token.
    /// @return The balance of the ERC1155 token ID.
    function getERC1155Balance(IERC1155 token, uint256 tokenId) external view returns (uint256) {
        require(address(token) != address(0), "Vault: Invalid token address");
        return token.balanceOf(address(this), tokenId);
    }

    // --- Protocol Interaction ---

    /// @notice Approves a specified amount of an ERC20 token held by the vault for an external protocol/spender.
    /// @dev This allows the protocol to `transferFrom` the vault. Use with caution.
    /// @param token The ERC20 token contract address.
    /// @param protocol The address of the external protocol/spender.
    /// @param amount The amount to approve. Use type(uint256).max for infinite approval.
    function approveERC20ForProtocol(IERC20 token, address protocol, uint256 amount) external onlyAllowedInteractionOrOwner whenNotPaused {
         require(address(token) != address(0), "Vault: Invalid token address");
         require(protocol != address(0), "Vault: Invalid protocol address");

         // Approve the protocol to spend tokens from this contract
         bool success = token.approve(protocol, amount);
         require(success, "Vault: ERC20 approval failed");

         emit ERC20Approved(token, protocol, amount);
    }

    /// @notice Stakes ERC20 tokens held in the vault into an external staking protocol.
    /// @dev Assumes the staking protocol has a `stake(uint256 amount)` function and has been approved beforehand (using `approveERC20ForProtocol`).
    /// @param token The ERC20 token contract address being staked.
    /// @param stakingProtocol The address of the staking protocol contract.
    /// @param amount The amount of tokens to stake.
    function stakeERC20(IERC20 token, IStakingProtocol stakingProtocol, uint256 amount) external onlyAllowedInteractionOrOwner whenNotPaused {
        require(amount > 0, "Vault: Stake amount must be greater than zero");
        require(address(token) != address(0), "Vault: Invalid token address");
        require(address(stakingProtocol) != address(0), "Vault: Invalid staking protocol address");
        require(token.balanceOf(address(this)) >= amount, "Vault: Insufficient ERC20 balance to stake");
        // Assumes stakingProtocol was previously approved via `approveERC20ForProtocol`

        // TransferFrom is called by the staking protocol, after this vault approved it.
        // Call the stake function on the external protocol
        stakingProtocol.stake(amount); // May revert if approval is insufficient or protocol logic fails

        emit ERC20Staked(token, stakingProtocol, amount);
    }

    /// @notice Unstakes ERC20 tokens from an external staking protocol back into the vault.
    /// @dev Assumes the staking protocol has an `unstake(uint256 amount)` function that sends tokens back to the caller (this vault).
    /// @param token The ERC20 token contract address being unstaked (the one sent back to the vault).
    /// @param stakingProtocol The address of the staking protocol contract.
    /// @param amount The amount of tokens to unstake.
    function unstakeERC20(IERC20 token, IStakingProtocol stakingProtocol, uint256 amount) external onlyAllowedInteractionOrOwner whenNotPaused {
        require(amount > 0, "Vault: Unstake amount must be greater than zero");
        require(address(token) != address(0), "Vault: Invalid token address");
        require(address(stakingProtocol) != address(0), "Vault: Invalid staking protocol address");

        uint256 initialBalance = token.balanceOf(address(this));

        // Call the unstake function on the external protocol
        stakingProtocol.unstake(amount); // May revert if unstaking logic fails

        // Verify tokens were received back (optional but good practice)
        require(token.balanceOf(address(this)) >= initialBalance + amount, "Vault: Unstaked tokens not received");

        emit ERC20Unstaked(token, stakingProtocol, amount);
    }

    /// @notice Claims rewards from an external rewards protocol into the vault.
    /// @dev Assumes the rewards protocol has a `claimRewards(address token)` function (or similar) that sends reward tokens back to the caller (this vault).
    /// @param rewardsProtocol The address of the rewards protocol contract.
    /// @param token The address of the reward token to claim (adjust based on protocol interface).
    function claimRewards(IRewardsProtocol rewardsProtocol, address token) external onlyAllowedInteractionOrOwner whenNotPaused {
         require(address(rewardsProtocol) != address(0), "Vault: Invalid rewards protocol address");
         require(token != address(0), "Vault: Invalid reward token address");

         // Call the claim function on the external protocol
         // Note: This simplistic interface might not match real protocols.
         // A real implementation would need to know the specific claim function signature and how it identifies rewards.
         rewardsProtocol.claimRewards(token); // May revert

         emit RewardsClaimed(rewardsProtocol, token);
    }

    /// @notice Delegates voting power for ERC20Votes tokens held in the vault.
    /// @dev Requires the token to implement the ERC20Votes standard (EIP-5805).
    /// @param token The address of the ERC20Votes token contract.
    /// @param delegatee The address to delegate voting power to.
    function delegateERC20Votes(IERC20Votes token, address delegatee) external onlyAllowedInteractionOrOwner whenNotPaused {
         require(address(token) != address(0), "Vault: Invalid token address");
         require(delegatee != address(0), "Vault: Invalid delegatee address");

         token.delegate(delegatee); // Requires the vault to hold the ERC20Votes tokens

         emit ERC20VotesDelegated(token, delegatee);
    }


    // --- Advanced Execution ---

    /// @notice Executes a low-level call to an arbitrary target address from the vault's context.
    /// @dev This function is extremely powerful and potentially dangerous. It should only be callable by trusted addresses (owner or highly trusted allowed interactions).
    /// The `data` parameter contains the function signature and encoded arguments for the target contract.
    /// @param target The address of the contract to call.
    /// @param value The amount of ETH to send with the call (from the vault's balance).
    /// @param data The calldata for the target function.
    /// @return success True if the call succeeded, false otherwise.
    /// @return result The data returned by the call.
    function executeCall(address target, uint256 value, bytes memory data)
        external
        onlyAllowedInteractionOrOwner // Restricted access!
        whenNotPaused
        returns (bool success, bytes memory result)
    {
        require(target != address(0), "Vault: Invalid target address for executeCall");
        // Check if the vault has enough ETH if value > 0
        require(address(this).balance >= value, "Vault: Insufficient ETH for value transfer in executeCall");

        // Perform the low-level call
        (success, result) = target.call{value: value}(data);

        // Note: It's often better to add a require(success, "Vault: External call failed");
        // However, returning success allows calling functions that are expected to sometimes fail.
        // The consumer of this function must check the success boolean.

        emit ProtocolCallExecuted(target, value, data);
        return (success, result);
    }


    // --- Time-Locked Withdrawals (Example for ERC20) ---

    /// @notice Sets up a time-locked withdrawal for a specific ERC20 token.
    /// @dev Creates an entry for a withdrawal that can only be executed after a specified timestamp.
    /// @param recipient The address to which the tokens will be sent upon execution.
    /// @param token The ERC20 token contract address.
    /// @param amount The amount of ERC20 tokens to lock for withdrawal.
    /// @param unlockTimestamp The timestamp (in seconds since epoch) after which the withdrawal can be executed. Must be in the future.
    /// @return withdrawalId The unique ID assigned to this time-locked withdrawal.
    function setupTimeLockedWithdrawal(address recipient, IERC20 token, uint256 amount, uint256 unlockTimestamp)
        external
        onlyOwner // Only owner can schedule these
        whenNotPaused
        returns (uint256 withdrawalId)
    {
        require(recipient != address(0), "Vault: Invalid recipient address");
        require(address(token) != address(0), "Vault: Invalid token address");
        require(amount > 0, "Vault: Amount must be greater than zero");
        require(token.balanceOf(address(this)) >= amount, "Vault: Insufficient ERC20 balance to lock");
        require(unlockTimestamp > block.timestamp, "Vault: Unlock timestamp must be in the future");

        withdrawalId = _nextWithdrawalId++;
        _timeLockedWithdrawals[withdrawalId] = TimeLockedWithdrawal({
            recipient: recipient,
            token: token,
            amount: amount,
            unlockTimestamp: unlockTimestamp,
            executed: false
        });

        emit TimeLockedWithdrawalScheduled(withdrawalId, recipient, token, amount, unlockTimestamp);
        return withdrawalId;
    }

    /// @notice Executes a previously scheduled time-locked withdrawal.
    /// @dev Can only be executed after the specified unlock timestamp and if not already executed.
    /// The execution can be triggered by the owner or an allowed interaction address (e.g., a Keeper).
    /// @param withdrawalId The ID of the time-locked withdrawal to execute.
    function executeTimeLockedWithdrawal(uint256 withdrawalId) external onlyAllowedInteractionOrOwner whenNotPaused {
        TimeLockedWithdrawal storage withdrawal = _timeLockedWithdrawals[withdrawalId];

        require(withdrawal.recipient != address(0), "Vault: Invalid withdrawal ID"); // Checks if entry exists
        require(!withdrawal.executed, "Vault: Withdrawal already executed");
        require(block.timestamp >= withdrawal.unlockTimestamp, "Vault: Unlock time has not passed");
        // We don't explicitly check balance here, assuming the tokens were intended to be held until unlock.
        // If the token balance dropped below the amount, the transfer will fail.

        withdrawal.executed = true; // Mark as executed BEFORE transferring

        bool success = withdrawal.token.transfer(withdrawal.recipient, withdrawal.amount);
        require(success, "Vault: Time-locked withdrawal failed");

        emit TimeLockedWithdrawalExecuted(withdrawalId);
    }

    // --- Access Control & State ---

    /// @notice Adds an address to the list of allowed interaction addresses.
    /// @dev Allowed addresses can execute functions restricted by `onlyAllowedInteractionOrOwner`. Only callable by the owner.
    /// Useful for allowing multisigs, trusted automation bots (like Keepers), or other contracts to manage assets/interactions without full ownership.
    /// @param allowedAddress The address to add.
    function addAllowedInteraction(address allowedAddress) external onlyOwner {
        require(allowedAddress != address(0), "Vault: Invalid address");
        _allowedInteractions[allowedAddress] = true;
        emit AllowedInteractionAdded(allowedAddress);
    }

    /// @notice Removes an address from the list of allowed interaction addresses.
    /// @dev Only callable by the owner.
    /// @param allowedAddress The address to remove.
    function removeAllowedInteraction(address allowedAddress) external onlyOwner {
        require(allowedAddress != address(0), "Vault: Invalid address");
        _allowedInteractions[allowedAddress] = false;
        emit AllowedInteractionRemoved(allowedAddress);
    }

    /// @notice Checks if an address is currently in the allowed interaction list.
    /// @param allowedAddress The address to check.
    /// @return True if the address is allowed, false otherwise.
    function checkAllowedInteraction(address allowedAddress) external view returns (bool) {
        return _allowedInteractions[allowedAddress];
    }

    /// @notice Pauses or unpauses core operations of the vault.
    /// @dev When paused, deposits, withdrawals (except possibly emergency ones), and interactions are blocked.
    /// @param _paused True to pause, false to unpause.
    function pauseVault(bool _paused) external onlyOwner {
        if (this._paused != _paused) {
            this._paused = _paused;
            emit VaultPaused(_paused);
        }
    }

    /// @notice Checks if the vault is currently paused.
    /// @return True if paused, false otherwise.
    function isPaused() external view returns (bool) {
        return _paused;
    }

    // Inherits transferOwnership and renounceOwnership from Ownable.

    // Note: Emergency withdrawals could be added as separate functions bypassing the pause state,
    // callable only by the owner. This adds complexity but is a common pattern for vaults.
    // Example (not adding to count to keep it simpler, but illustrating the concept):
    /*
    function emergencyWithdrawETH(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Vault: Invalid recipient");
        require(address(this).balance >= amount, "Vault: Insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Vault: Emergency ETH withdrawal failed");
        // No paused check
        // No time lock check
        emit ETHWithdrawn(recipient, amount); // Reuse event
    }
    */

}
```