Okay, let's design an advanced smart contract incorporating several interesting concepts:

**Contract Theme:** A "Dynamic Synthetic Vault" (DSV) that allows users to stake underlying assets (like WETH or stablecoins) and mint dynamic synthetic tokens representing a position. These positions are represented by NFTs, and both the value calculation of the synthetic tokens and the attributes of the position NFTs can change based on external factors (simulated oracles, governance actions) and user actions (locking the position).

**Advanced Concepts Used:**

1.  **Synthetic Assets:** Creating a new ERC-20 token whose value is derived from underlying collateral and dynamic parameters.
2.  **NFTs representing Positions:** Using ERC-721 tokens to represent a user's specific stake and rights within the vault, allowing positions to be traded or used in other protocols.
3.  **Dynamic Value Calculation:** The value of the synthetic token is not fixed to the underlying 1:1 but depends on a dynamic "strategy multiplier" and potentially other factors.
4.  **Parametric Strategies:** Defining different "strategies" (simulated here by multipliers) that affect the synthetic value calculation, chosen by the user or governance.
5.  **Governance Integration (Simulated):** Allowing parameters or strategy multipliers to be updated via a simple governance mechanism (proposals and voting).
6.  **Time-Based State:** Position NFTs can be locked for a duration, affecting their status or benefits.
7.  **Signature-Based Interaction (Permit for Minting):** Allowing users to authorize minting synthetic tokens from their position *without* directly sending a transaction (meta-transaction pattern).
8.  **Oracle Integration (Simulated):** Incorporating a mechanism to fetch external data (like underlying asset price) crucial for value calculation and liquidation.
9.  **Liquidation Mechanism:** Allowing undercollateralized positions to be liquidated.
10. **Protocol Fees:** Implementing a simple fee structure.
11. **Reentrancy Protection:** Standard security practice.
12. **ERC-165 (Interface Detection):** For ERC-721 compliance.

**Outline & Function Summary**

**Contract Name:** `DynamicSyntheticVault`

**Inherits:** `ERC20` (for the synthetic token), `ERC721` (for position NFTs), `Ownable`, `ReentrancyGuard`, `IERC20`, `IERC721Receiver`, `IERC165`.

**State Variables:**
*   `underlyingToken`: Address of the staked asset (e.g., WETH).
*   `syntheticToken`: ERC-20 details (handled by inheritance).
*   `positionNFT`: ERC-721 details (handled by inheritance), `_tokenIds` counter.
*   `positions`: Mapping from `uint256` (tokenId) to `Position` struct.
*   `Position` struct: Holds `owner`, `stakedAmount`, `syntheticBalance`, `lockupEndTime`, `strategyId`, `mintNonce`.
*   `strategies`: Mapping from `uint256` (strategyId) to `Strategy` struct.
*   `Strategy` struct: Holds `multiplier` (basis points), `riskScore`.
*   `governanceContract`: Address of the governance contract (simulated).
*   `oracleContract`: Address of the price oracle (simulated).
*   `liquidationIncentiveBP`: Basis points added to liquidated amount.
*   `protocolFeeBP`: Basis points taken as fee on minted synthetics.
*   `minCollateralRatioBP`: Minimum collateral ratio required.
*   `proposals`: Mapping from `uint256` (proposalId) to `Proposal` struct.
*   `Proposal` struct: Holds target strategyId, proposed multiplier, votes for, votes against, end time, executed status.
*   `proposalCounter`: Counter for new proposals.

**Events:**
*   `Deposit(uint256 indexed positionId, address indexed user, uint256 amount)`
*   `Withdraw(uint256 indexed positionId, address indexed user, uint256 amount)`
*   `MintSynthetic(uint256 indexed positionId, address indexed minter, uint256 amount, uint256 feeAmount)`
*   `BurnSynthetic(uint256 indexed positionId, address indexed burner, uint256 amount)`
*   `PositionCreated(uint256 indexed positionId, address indexed owner, uint256 initialDeposit)`
*   `PositionLocked(uint256 indexed positionId, uint256 lockDuration, uint256 unlockTime)`
*   `PositionUnlocked(uint256 indexed positionId)`
*   `StrategyUpdated(uint256 indexed strategyId, uint256 oldMultiplier, uint256 newMultiplier)`
*   `UserStrategyChanged(uint256 indexed positionId, uint256 oldStrategyId, uint256 newStrategyId)`
*   `Liquidation(uint256 indexed positionId, address indexed liquidator, uint256 seizedCollateral, uint256 burntSynthetic)`
*   `ProposalCreated(uint256 indexed proposalId, uint256 indexed strategyId, uint256 proposedMultiplier, uint256 endTime)`
*   `Voted(uint256 indexed proposalId, address indexed voter, bool support)`
*   `ProposalExecuted(uint256 indexed proposalId)`
*   `FeesClaimed(address indexed token, address indexed receiver, uint256 amount)`

**Functions (>= 20):**

1.  `constructor(address _underlyingToken, string memory _synthName, string memory _synthSymbol, string memory _nftName, string memory _nftSymbol, address _governanceContract, address _oracleContract)`: Initializes tokens, base parameters, and key addresses.
2.  `depositUnderlying(uint256 amount)`: Allows a user to deposit underlying token. Creates a new position NFT or adds to an existing one if they don't own a position.
3.  `withdrawUnderlying(uint256 positionId, uint256 amount)`: Allows a user to withdraw staked underlying from their position. Checks lockup and minimum collateral ratio.
4.  `mintSynthetic(uint256 positionId, uint256 amount)`: Mints synthetic tokens to the caller based on their position's staked collateral, current strategy multiplier, and underlying price. Applies fees. Checks collateral ratio.
5.  `burnSynthetic(uint256 positionId, uint256 amount)`: Burns synthetic tokens from the caller's balance, reducing the synthetic debt on their position.
6.  `permitMint(address owner, uint256 positionId, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)`: Allows a trusted third party (relayer) to call `mintSynthetic` on behalf of the `owner` for their `positionId` if a valid signed message (EIP-712 style, simplified here for demonstration) is provided.
7.  `lockPosition(uint256 positionId, uint256 duration)`: Allows the position NFT owner to lock their position for a specified duration, updating `lockupEndTime`.
8.  `unlockPosition(uint256 positionId)`: Allows the position NFT owner to remove the lock *after* `lockupEndTime` has passed.
9.  `liquidatePosition(uint256 positionId)`: Allows anyone to call this if the position is undercollateralized. Seizes underlying collateral, burns synthetic debt, and provides an incentive to the liquidator.
10. `getUnderlyingPrice()`: (Simulated) Returns the current price of the underlying asset in a common unit (e.g., USD) by calling the simulated oracle contract.
11. `getSyntheticValue(uint256 positionId)`: Reads the value of the synthetic tokens held in a specific position based on the position's strategy, current strategy multiplier, and underlying price.
12. `getCurrentCollateralRatio(uint256 positionId)`: Calculates the current collateral ratio (value of staked underlying / value of minted synthetic) for a position, considering the strategy multiplier.
13. `addStrategy(uint256 strategyId, uint256 multiplier, uint256 riskScore)`: (Governance) Adds a new strategy definition.
14. `updateStrategyMultiplier(uint256 strategyId, uint256 newMultiplier)`: (Governance/Proposal Execution) Updates the multiplier for an existing strategy.
15. `setUserStrategy(uint256 positionId, uint256 newStrategyId)`: Allows the position NFT owner to change the strategy associated with their position (potentially with cooldowns/fees in a real system, simplified here).
16. `proposeStrategyMultiplierChange(uint256 strategyId, uint256 proposedMultiplier, uint256 votingDuration)`: (Governance) Creates a new proposal to change a strategy multiplier.
17. `voteOnProposal(uint256 proposalId, bool support)`: (Governance) Allows eligible voters (e.g., governance token holders, position owners) to vote on a proposal.
18. `executeProposal(uint256 proposalId)`: (Anyone, after voting ends) Executes the outcome of a successful proposal (e.g., calls `updateStrategyMultiplier`).
19. `claimProtocolFees(address receiver)`: (Admin/Governance) Allows claiming accumulated protocol fees in the underlying token.
20. `sweepDust(address tokenAddress, address receiver)`: (Admin) Allows sweeping accidental token transfers stuck in the contract.
21. `getPositionDetails(uint256 positionId)`: (View) Returns all details of a specific position.
22. `getStrategyDetails(uint256 strategyId)`: (View) Returns details of a specific strategy.
23. `getProposalDetails(uint256 proposalId)`: (View) Returns details of a specific proposal.
24. `isPositionLocked(uint256 positionId)`: (View) Checks if a position is currently locked.
25. `calculateMintableAmount(uint256 positionId, uint256 desiredSyntheticAmount)`: (Pure/View) Calculates the maximum synthetic amount that *could* be minted from a position without violating the min collateral ratio *with the current state*. (This is a helper/preview function).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for getting all tokenIds
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using >=0.8, SafeMath is mostly built-in, but good habit or for clarity
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For permit functionality
import "@openzeppelin/contracts/utils/Address.sol"; // For token transfers
import "@openzeppelin/contracts/utils/introspection/IERC165.sol"; // For ERC721 compliance

// --- OUTLINE & FUNCTION SUMMARY ---
// Contract Name: DynamicSyntheticVault
// Inherits: ERC20, ERC721, Ownable, ReentrancyGuard, IERC20, IERC721Receiver, IERC165
// Core Concept: Allows staking an underlying asset (ERC20) to mint dynamic synthetic tokens (ERC20).
// Positions are represented by NFTs (ERC721).
// Synthetic value depends on staked collateral, underlying price (simulated oracle), and a dynamic 'strategy multiplier'.
// Position NFTs can be locked (time-based state).
// Includes mechanisms for liquidation, governance interaction (simulated proposals),
// signature-based minting (permit), and fee collection.
// Uses advanced concepts like dynamic state, synthetic assets, NFT positions,
// parametric strategies, simulated governance/oracle, time-based state, and signature auth.
//
// State Variables:
// - underlyingToken: Address of the staked ERC20 asset.
// - syntheticToken (inherited): Details of the minted synthetic ERC20 token.
// - positionNFT (inherited): Details of the position ERC721 token.
// - positions: Mapping tokenId -> Position struct (owner, staked, synthetic debt, lockup, strategy, nonce).
// - strategies: Mapping strategyId -> Strategy struct (multiplier BP, risk score).
// - governanceContract: Address authorized for governance actions (simulated).
// - oracleContract: Address of the simulated price oracle.
// - liquidationIncentiveBP: Basis points incentive for liquidators.
// - protocolFeeBP: Basis points fee on synthetic minting.
// - minCollateralRatioBP: Minimum collateral ratio required (BP).
// - proposals: Mapping proposalId -> Proposal struct (target strategy, new multiplier, votes, state, time).
// - proposalCounter: Counter for proposals.
//
// Events:
// - Deposit, Withdraw, MintSynthetic, BurnSynthetic, PositionCreated, PositionLocked,
//   PositionUnlocked, StrategyUpdated, UserStrategyChanged, Liquidation, ProposalCreated,
//   Voted, ProposalExecuted, FeesClaimed.
//
// Functions (>= 20):
// 1. constructor(...)
// 2. depositUnderlying(uint256 amount)
// 3. withdrawUnderlying(uint256 positionId, uint256 amount)
// 4. mintSynthetic(uint256 positionId, uint256 amount)
// 5. burnSynthetic(uint256 positionId, uint256 amount)
// 6. permitMint(address owner, uint256 positionId, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
// 7. lockPosition(uint256 positionId, uint256 duration)
// 8. unlockPosition(uint256 positionId)
// 9. liquidatePosition(uint256 positionId)
// 10. getUnderlyingPrice() (Simulated Oracle)
// 11. getSyntheticValue(uint256 positionId) (Dynamic calculation based on strategy/price)
// 12. getCurrentCollateralRatio(uint256 positionId) (Dynamic calculation)
// 13. addStrategy(uint256 strategyId, uint256 multiplier, uint256 riskScore) (Governance)
// 14. updateStrategyMultiplier(uint256 strategyId, uint256 newMultiplier) (Governance/Proposal execution)
// 15. setUserStrategy(uint256 positionId, uint256 newStrategyId)
// 16. proposeStrategyMultiplierChange(uint256 strategyId, uint256 proposedMultiplier, uint256 votingDuration) (Governance)
// 17. voteOnProposal(uint256 proposalId, bool support) (Governance)
// 18. executeProposal(uint256 proposalId) (Anyone, checks if passed)
// 19. claimProtocolFees(address receiver) (Admin/Governance)
// 20. sweepDust(address tokenAddress, address receiver) (Admin)
// 21. getPositionDetails(uint256 positionId) (View)
// 22. getStrategyDetails(uint256 strategyId) (View)
// 23. getProposalDetails(uint256 proposalId) (View)
// 24. isPositionLocked(uint256 positionId) (View)
// 25. calculateMintableAmount(uint256 positionId, uint256 desiredSyntheticAmount) (View/Helper)
// --- END OUTLINE & SUMMARY ---


contract DynamicSyntheticVault is ERC20, ERC721Enumerable, Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Address for address;

    IERC20 public immutable underlyingToken;

    Counters.Counter private _positionTokenIds;

    struct Position {
        address owner;
        uint256 stakedAmount;
        uint256 syntheticBalance; // Synthetic debt held by this position
        uint256 lockupEndTime;
        uint256 strategyId;
        uint256 mintNonce; // Nonce for permitMint
    }

    mapping(uint256 => Position) public positions;
    mapping(address => uint256) private _userPositionId; // Simple mapping for users to find *their* primary position NFT

    struct Strategy {
        uint256 multiplierBP; // Multiplier in basis points (e.g., 10000 for 1x, 15000 for 1.5x)
        uint256 riskScore; // Simulated risk score (e.g., 1-100)
    }

    mapping(uint256 => Strategy) public strategies;

    address public governanceContract; // Simulated governance
    address public oracleContract;     // Simulated price oracle

    uint256 public liquidationIncentiveBP = 10500; // 5% incentive
    uint256 public protocolFeeBP = 50; // 0.5% fee on minting
    uint256 public minCollateralRatioBP = 15000; // 150% minimum collateral ratio

    struct Proposal {
        uint256 strategyId;
        uint256 proposedMultiplierBP;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
        bool passed; // Final outcome after voting ends
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted
    Counters.Counter private _proposalIds;

    // PermitMint related
    bytes32 private immutable _DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_MINT_TYPEHASH = keccak256("PermitMint(address owner,uint256 positionId,uint256 amount,uint256 deadline,uint256 nonce)");

    event Deposit(uint256 indexed positionId, address indexed user, uint256 amount);
    event Withdraw(uint256 indexed positionId, address indexed user, uint256 amount);
    event MintSynthetic(uint256 indexed positionId, address indexed minter, uint256 amount, uint256 feeAmount);
    event BurnSynthetic(uint256 indexed positionId, address indexed burner, uint256 amount);
    event PositionCreated(uint256 indexed positionId, address indexed owner, uint256 initialDeposit);
    event PositionLocked(uint256 indexed positionId, uint256 lockDuration, uint256 unlockTime);
    event PositionUnlocked(uint256 indexed positionId);
    event StrategyUpdated(uint256 indexed strategyId, uint256 oldMultiplier, uint256 newMultiplier);
    event UserStrategyChanged(uint256 indexed positionId, uint256 oldStrategyId, uint256 newStrategyId);
    event Liquidation(uint256 indexed positionId, address indexed liquidator, uint256 seizedCollateral, uint256 burntSynthetic);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed strategyId, uint256 proposedMultiplier, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event FeesClaimed(address indexed token, address indexed receiver, uint256 amount);

    constructor(
        address _underlyingToken,
        string memory _synthName,
        string memory _synthSymbol,
        string memory _nftName,
        string memory _nftSymbol,
        address _governanceContract,
        address _oracleContract
    )
        ERC20(_synthName, _synthSymbol)
        ERC721(_nftName, _nftSymbol)
        Ownable(msg.sender) // Initial owner is deployer
    {
        underlyingToken = _underlyingToken;
        governanceContract = _governanceContract; // In a real system, this would be a complex governance contract
        oracleContract = _oracleContract;         // In a real system, this would be a Chainlink/Band/etc. oracle

        // Initialize a default strategy
        strategies[1] = Strategy({
            multiplierBP: 10000, // 1x
            riskScore: 50
        });

        // Set up EIP-712 domain separator for permitMint
        _DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(_synthName)), // Or use the contract name? Let's use synth name for permit context
            keccak256("1"), // Version of EIP712 domain
            block.chainid,
            address(this)
        ));
    }

    // --- Core Vault & Asset Management ---

    /**
     * @dev Deposits underlying tokens into the vault. Creates a new position NFT if the user doesn't have one.
     * @param amount The amount of underlying token to deposit.
     */
    function depositUnderlying(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be > 0");
        address user = msg.sender;
        uint256 positionId = _userPositionId[user];

        if (positionId == 0) {
            // Create a new position
            _positionTokenIds.increment();
            positionId = _positionTokenIds.current();
            _safeMint(user, positionId);
            _userPositionId[user] = positionId;

            positions[positionId] = Position({
                owner: user,
                stakedAmount: amount,
                syntheticBalance: 0,
                lockupEndTime: 0,
                strategyId: 1, // Default strategy
                mintNonce: 0
            });

            emit PositionCreated(positionId, user, amount);
        } else {
            // Deposit into existing position
            require(ownerOf(positionId) == user, "Not owner of position");
            positions[positionId].stakedAmount += amount;
        }

        // Transfer tokens to the contract
        bool success = IERC20(underlyingToken).transferFrom(user, address(this), amount);
        require(success, "Underlying transfer failed");

        emit Deposit(positionId, user, amount);
    }

    /**
     * @dev Withdraws underlying tokens from a position.
     * @param positionId The ID of the position NFT.
     * @param amount The amount of underlying token to withdraw.
     */
    function withdrawUnderlying(uint256 positionId, uint256 amount) external nonReentrant {
        address user = msg.sender;
        require(ownerOf(positionId) == user, "Not owner of position");
        require(positions[positionId].stakedAmount >= amount, "Insufficient staked amount");
        require(amount > 0, "Withdraw amount must be > 0");
        require(block.timestamp >= positions[positionId].lockupEndTime, "Position is locked");

        positions[positionId].stakedAmount -= amount;

        // Check collateral ratio after withdrawal (if synthetic debt exists)
        if (positions[positionId].syntheticBalance > 0) {
             uint256 currentRatio = getCurrentCollateralRatio(positionId);
             require(currentRatio >= minCollateralRatioBP, "Withdrawal causes insufficient collateral ratio");
        }

        // Transfer tokens back to the user
        bool success = IERC20(underlyingToken).transfer(user, amount);
        require(success, "Underlying transfer failed");

        emit Withdraw(positionId, user, amount);
    }

    /**
     * @dev Mints synthetic tokens against a position's collateral.
     * Applies a protocol fee.
     * @param positionId The ID of the position NFT.
     * @param amount The amount of synthetic tokens to mint (before fee).
     */
    function mintSynthetic(uint256 positionId, uint256 amount) external nonReentrant {
        address user = msg.sender;
        // Allow owner OR someone authorized via permitMint
        require(ownerOf(positionId) == user || positions[positionId].owner == user, "Not position owner or authorized"); // Check initial owner from struct if NFT transferred

        require(amount > 0, "Mint amount must be > 0");

        uint256 feeAmount = amount.mul(protocolFeeBP).div(10000);
        uint256 amountToMint = amount.sub(feeAmount);

        positions[positionId].syntheticBalance += amount; // Position accrues synthetic debt
        _mint(user, amountToMint); // User receives minted amount minus fee

        uint256 currentRatio = getCurrentCollateralRatio(positionId);
        require(currentRatio >= minCollateralRatioBP, "Minting causes insufficient collateral ratio");

        emit MintSynthetic(positionId, user, amount, feeAmount);

        // Note: Fees accumulate in the contract's synthetic balance.
        // A separate mechanism (`claimProtocolFees`) is needed to withdraw them (handled below).
    }

    /**
     * @dev Burns synthetic tokens to reduce a position's synthetic debt.
     * @param positionId The ID of the position NFT.
     * @param amount The amount of synthetic tokens to burn.
     */
    function burnSynthetic(uint256 positionId, uint256 amount) external nonReentrant {
        address user = msg.sender;
        require(positions[positionId].owner == user, "Not position owner"); // Must be original owner to burn debt
        require(amount > 0, "Burn amount must be > 0");
        require(positions[positionId].syntheticBalance >= amount, "Insufficient synthetic debt on position");
        require(balanceOf(user) >= amount, "Insufficient synthetic balance");

        positions[positionId].syntheticBalance -= amount;
        _burn(user, amount);

        emit BurnSynthetic(positionId, user, amount);
    }

    /**
     * @dev Allows authorization of a third party to mint synthetic tokens from a position
     * via a signed message, without requiring the owner to send a transaction.
     * This follows a meta-transaction pattern similar to ERC-2612 permit, but for minting.
     * @param owner The address of the position owner.
     * @param positionId The ID of the position NFT.
     * @param amount The maximum amount of synthetic tokens authorized to mint.
     * @param deadline The time until which the signature is valid.
     * @param v ECDSA signature parameter.
     * @param r ECDSA signature parameter.
     * @param s ECDSA signature parameter.
     */
    function permitMint(address owner, uint256 positionId, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(block.timestamp <= deadline, "Permit expired");
        require(positions[positionId].owner == owner, "Not position owner"); // Check owner in struct

        uint256 currentNonce = positions[positionId].mintNonce;
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            _DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_MINT_TYPEHASH, owner, positionId, amount, deadline, currentNonce))
        ));

        address recoveredAddress = digest.recover(v, r, s);
        require(recoveredAddress == owner, "Invalid signature");

        // Increment nonce to prevent replay attacks
        positions[positionId].mintNonce = currentNonce + 1;

        // Now, mint the tokens to the original owner's address
        // This pattern is often used where the relayer pays gas, but tokens go to the user.
        // We call _mint directly here as the authorization is verified.
        uint256 feeAmount = amount.mul(protocolFeeBP).div(10000);
        uint256 amountToMint = amount.sub(feeAmount);

        positions[positionId].syntheticBalance += amount; // Position accrues synthetic debt
        _mint(owner, amountToMint); // User receives minted amount minus fee

        uint256 currentRatio = getCurrentCollateralRatio(positionId);
        require(currentRatio >= minCollateralRatioBP, "Minting causes insufficient collateral ratio");

        emit MintSynthetic(positionId, owner, amount, feeAmount);
    }


    // --- Position & NFT Management ---

    /**
     * @dev Locks a position NFT, preventing withdrawal of underlying until lockup expires.
     * Can potentially be used for future yield boosts or governance weight.
     * @param positionId The ID of the position NFT.
     * @param duration The duration in seconds to lock the position for.
     */
    function lockPosition(uint256 positionId, uint256 duration) external {
        address user = msg.sender;
        require(ownerOf(positionId) == user, "Not owner of position");
        require(duration > 0, "Lock duration must be > 0");
        // Allow extending the lock
        positions[positionId].lockupEndTime = block.timestamp + duration;
        emit PositionLocked(positionId, duration, positions[positionId].lockupEndTime);
    }

    /**
     * @dev Unlocks a position NFT if the lockup period has expired.
     * @param positionId The ID of the position NFT.
     */
    function unlockPosition(uint256 positionId) external {
        address user = msg.sender;
        require(ownerOf(positionId) == user, "Not owner of position");
        require(block.timestamp >= positions[positionId].lockupEndTime, "Lockup period not ended");
        positions[positionId].lockupEndTime = 0;
        emit PositionUnlocked(positionId);
    }

     /**
     * @dev Allows governance to force unlock a position in exceptional circumstances.
     * @param positionId The ID of the position NFT.
     */
    function forceUnlockPosition(uint256 positionId) external onlyOwner {
        require(positions[positionId].owner != address(0), "Position does not exist");
        positions[positionId].lockupEndTime = 0;
        emit PositionUnlocked(positionId);
    }

    /**
     * @dev Transfers position NFT. Includes ERC721 standard hooks.
     * @param from The address transferring the NFT.
     * @param to The address receiving the NFT.
     * @param tokenId The ID of the position NFT.
     */
    function transferPositionNFT(address from, address to, uint256 tokenId) public {
         // Use _transfer function from ERC721Enumerable
        _transfer(from, to, tokenId);
        // Note: This transfers ownership of the NFT, but the underlying and synthetic debt
        // remain tied to the Position struct associated with this tokenId.
        // A more complex system might update the 'owner' in the struct or require
        // position NFT holders to be the original depositor. For this example,
        // the struct 'owner' field is primarily used for `permitMint` and `burnSynthetic`
        // which are tied to the original depositor, while ERC721 `ownerOf` determines
        // who can call `withdrawUnderlying` and `lock/unlockPosition`.
        // This separation is intentional for demonstrating different rights.
    }

     // Override required by ERC721
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Override required by ERC721
    function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._afterTokenTransfer(from, to, tokenId);
        // If transferring to address(0), the position is burned (handled by ERC721),
        // but underlying collateral and synthetic debt remain trapped unless withdrawn/liquidated first.
        // Real system would require burning debt/collateral before NFT burn.
    }

     // Required for receiving NFTs (if vault could hold other NFTs)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // This vault doesn't support receiving other NFTs currently, so reject.
        // If it did, add logic here to handle the received NFT.
        return this.onERC721Received.selector;
    }

     // Required by ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // --- Dynamic State & Strategy ---

    /**
     * @dev Simulated oracle call to get the underlying asset price.
     * In a real contract, this would query a trusted oracle contract.
     * @return price The simulated price (e.g., in USD cents, scaled).
     */
    function getUnderlyingPrice() public view returns (uint256) {
        // In a real contract, this would call oracleContract.getLatestPrice() or similar
        // For simulation, return a hardcoded or dummy price.
        // Let's assume the price is in USD cents, scaled by 1e8 for precision.
        // e.g., $2000 USD would be 2000 * 1e8 = 200000000000
        // underlying token is assumed to have 18 decimals for standard ERC20
        // We need to return price relative to underlying token decimals.
        // Let's assume 1 Underlying Token = X USD_Scaled units.
        // Example: if 1 WETH = $2000, and USD_Scaled uses 8 decimals (like Chainlink):
        // Price is 2000 * 1e8 = 2e11 USD_Scaled per 1 WETH.
        // If underlying has 18 decimals, and synth uses 18 decimals:
        // Value of 1e18 WETH = 2e11 * 1e18 USD_Scaled.
        // Value of 1 WETH (smallest unit) = 2e11 USD_Scaled.
        // So, the price feed value directly corresponds to 1 unit of underlying (smallest unit).
        // Let's simulate a price of 2000 USD, scaled by 1e8.
        // The return value represents the value of 1 WEI of the underlying token in USD_Scaled units.
        // So, value of 1e18 WEI (1 token) is 2e11 * 1e18.
        // Price feed usually gives value of 1 unit of asset in terms of base unit of quote.
        // Example: ETH/USD feed gives USD price per 1 ETH.
        // So, if feed is 2000e8, it means 1 ETH = 2000 * 1e8 USD_Scaled.
        // Let's assume the oracle returns USD_Scaled * 1e18 / (1 Underlying Token)
        // No, let's assume oracle returns price per 1 UNIT of underlying (1e18 if 18 decimals), scaled by 1e8
        // So, if 1 ETH = $2000, oracle returns 2000 * 1e8 = 2e11.
        // This value represents 2e11 USD_Scaled per 1e18 Underlying units.
        // To get value of `amount` Underlying units: `amount` * price / 1e18 (if price is per 1e18 unit)
        // Let's simplify: Oracle returns price per 1 unit (wei) of underlying, scaled by 1e8.
        // Price of 1e18 underlying token = oracle_price * 1e18
        // Value of `stakedAmount` (in wei) = `stakedAmount` * oracle_price / 1e8 (if oracle price is per wei)
        // Let's assume oracle returns price of 1 UNIT (1e18) of underlying, scaled by 1e8.
        // Price of 1e18 Underlying = 2000 * 1e8 = 2e11 (Simulated value)
        // Value of stakedAmount = stakedAmount * (2e11 / 1e18)
        // To avoid floating point: Value = stakedAmount * 2e11 / 1e18
        // Let's use a constant simulated price scaled appropriately.
        // Value of 1e18 Underlying = 2000e18 * 1e8 / 1e8 = 2000e18 (if using 18 decimals for price feed)
        // If price feed returns 2000 * 1e8 per 1e18 underlying:
        // Value of `stakedAmount` = `stakedAmount` * (2000e8) / 1e18
        // Let's fix price feed returns: Price of 1e18 Underlying is `price * 1e8`. So oracle returns `price` in USD with 8 decimals.
        // $2000 USD -> 2000e8 = 2e11
        uint256 simulatedPriceScaled8 = 2000e8; // $2000 USD, scaled by 1e8
        // Assuming underlying has 18 decimals and synthetic has 18 decimals.
        // Value of `amount` (in 1e18 units) of underlying is `amount` * simulatedPriceScaled8 / 1e8.
        // Value of `amount` (in WEI) of underlying is `amount` * simulatedPriceScaled8 / 1e8. Wait, no.
        // The oracle gives the value of 1 *unit* of the asset. If the asset has 18 decimals, this price is for 1e18 smallest units.
        // So if oracle returns 2000e8 for ETH/USD, it means 1 ETH = 2000e8 USD.
        // If we have `stakedAmount` in WEI, its value is `stakedAmount` * (2000e8 / 1e18) USD.
        // This involves division by 1e18. Let's instead scale the oracle price by 1e10
        // Oracle returns price of 1 WEI of underlying, scaled by 1e10 + 1e8 = 1e18.
        // Price of 1 ETH (1e18 WEI) = 2000e8 USD. Price of 1 WEI = 2000e8 / 1e18 USD.
        // If we scale this by 1e18, we get (2000e8 / 1e18) * 1e18 = 2000e8. This is not right.
        // Let's assume oracle returns price of 1 unit (1e18) of underlying, scaled by 1e18.
        // 1 ETH = 2000 USD -> price = 2000 * 1e18.
        // Value of `stakedAmount` (in WEI) = `stakedAmount` * price / 1e18.
        // Let's return the simulated price of 1e18 underlying in 1e18 USD.
        // Simulated price of 1 underlying (1e18 units) in USD (1e18 units).
        uint256 simulatedPriceScaled18 = 2000e18; // $2000 USD, scaled by 1e18

        // In a real system, you'd call a mock oracle contract here:
        // (new MockOracle(oracleContract)).getPrice();
        // Or query a specific Chainlink feed etc.
        // For this demo, we hardcode.
        return simulatedPriceScaled18; // Price of 1e18 underlying = 2000e18 (simulated USD)
    }

    /**
     * @dev Calculates the dynamic value of the synthetic tokens associated with a position.
     * Value = syntheticBalance * strategyMultiplier * underlyingPrice / 1e18 (scaling)
     * @param positionId The ID of the position NFT.
     * @return value The total value of synthetic tokens held by the position, scaled by 1e18.
     */
    function getSyntheticValue(uint256 positionId) public view returns (uint256) {
        require(positions[positionId].owner != address(0), "Position does not exist");

        uint256 synthBalance = positions[positionId].syntheticBalance;
        if (synthBalance == 0) {
            return 0;
        }

        uint256 strategyId = positions[positionId].strategyId;
        require(strategies[strategyId].multiplierBP > 0, "Invalid strategy multiplier"); // Ensure strategy exists/is valid

        uint256 multiplierBP = strategies[strategyId].multiplierBP;
        uint256 underlyingPrice = getUnderlyingPrice(); // Price of 1e18 underlying in 1e18 USD

        // Value = syntheticBalance * multiplierBP / 10000 * underlyingPrice / 1e18
        // Use SafeMath to avoid overflow/underflow
        // Value = (synthBalance * multiplierBP / 10000) * (underlyingPrice / 1e18)
        // Value = (synthBalance * multiplierBP * underlyingPrice) / (10000 * 1e18)
        // Let's assume synthetic is also 1e18 decimals.
        // synthBalance is in WEI of synthetic. Value needs to be in WEI of USD (1e18).
        // Value of 1e18 synth = 1e18 * multiplierBP / 10000 * underlyingPrice / 1e18 USD
        // = multiplierBP / 10000 * underlyingPrice USD (scaled 1e18)
        // Value of `synthBalance` (in WEI) = `synthBalance` * (multiplierBP / 10000) * (underlyingPrice / 1e18)
        // Re-arranging: `synthBalance` * multiplierBP * underlyingPrice / (10000 * 1e18)
        // Simplified: `synthBalance` * multiplierBP / 1e4 * underlyingPrice / 1e18
        // `synthBalance` (1e18) * multiplierBP (1e4) * underlyingPrice (1e18) / (1e4 * 1e18) = 1e18 scale
        // synthBalance * multiplierBP * underlyingPrice / 1e22 -> Needs care with intermediate products.
        // Better: (synthBalance / 1e18) * (multiplierBP / 1e4) * (underlyingPrice / 1e18) * 1e18 (result scale)
        // (synthBalance * multiplierBP * underlyingPrice) / (1e4 * 1e18) * 1e18 / 1e18
        // (synthBalance * multiplierBP * underlyingPrice) / (1e4 * 1e18 * 1e18 / 1e18)
        // Let's assume underlyingPrice is scaled 1e18 per 1e18 underlying. synthBalance is 1e18 per 1e18 synthetic.
        // Value of syntheticBalance (scaled 1e18) = syntheticBalance (scaled 1e18) * multiplierBP / 1e4 * underlyingPrice (scaled 1e18) / 1e18
        // = syntheticBalance * multiplierBP * underlyingPrice / (1e4 * 1e18)
        // Ensure synthBalance and underlyingPrice have same scaling (both 1e18).
        // Result should be in 1e18 scale USD.
        // value = (synthBalance * multiplierBP / 10000).mul(underlyingPrice).div(1e18); // potential intermediate overflow if both large
        // value = (synthBalance.mul(multiplierBP) / 10000).mul(underlyingPrice) / 1e18; // same issue
        // Let's assume 1e18 for both synthetic and underlying, price scaled 1e18 per 1e18.
        // value = (synthBalance.mul(multiplierBP)).div(10000); // This gets synthetic value * multiplier, in synth units * multiplier
        // value = value.mul(underlyingPrice).div(1e18); // Convert to USD
         uint256 effectiveSynthAmountScaled18 = synthBalance.mul(multiplierBP).div(10000); // Apply multiplier to synth amount
         uint256 valueScaled18 = effectiveSynthAmountScaled18.mul(underlyingPrice).div(1e18); // Convert effectively priced synth to USD

        return valueScaled18; // Value in 1e18 USD
    }

     /**
     * @dev Calculates the total value of staked collateral in a position.
     * Value = stakedAmount * underlyingPrice / 1e18 (scaling)
     * @param positionId The ID of the position NFT.
     * @return value The total value of staked collateral, scaled by 1e18.
     */
    function getCollateralValue(uint256 positionId) public view returns (uint256) {
         require(positions[positionId].owner != address(0), "Position does not exist");
         uint256 staked = positions[positionId].stakedAmount;
         if (staked == 0) return 0;

         uint256 underlyingPrice = getUnderlyingPrice(); // Price of 1e18 underlying in 1e18 USD
         // value = stakedAmount (1e18) * underlyingPrice (1e18) / 1e18
         uint256 valueScaled18 = staked.mul(underlyingPrice).div(1e18); // Value in 1e18 USD
         return valueScaled18;
    }


    /**
     * @dev Calculates the current collateral ratio for a position in basis points.
     * Ratio = (Collateral Value / Synthetic Value) * 10000
     * @param positionId The ID of the position NFT.
     * @return ratio The collateral ratio in basis points (e.g., 20000 for 200%).
     */
    function getCurrentCollateralRatio(uint256 positionId) public view returns (uint256) {
        require(positions[positionId].owner != address(0), "Position does not exist");

        uint256 collateralValue = getCollateralValue(positionId);
        uint256 syntheticValue = getSyntheticValue(positionId);

        if (syntheticValue == 0) {
            return type(uint256).max; // Infinite ratio if no synthetic debt
        }

        // ratio = (collateralValue * 10000) / syntheticValue
        uint256 ratioBP = collateralValue.mul(10000).div(syntheticValue);
        return ratioBP;
    }

    /**
     * @dev Calculates the maximum synthetic amount that can be minted from a position
     * based on the current state and minimum collateral ratio.
     * @param positionId The ID of the position NFT.
     * @return maxMintable The maximum amount of synthetic that could be minted.
     */
     function calculateMintableAmount(uint256 positionId) public view returns (uint256) {
         require(positions[positionId].owner != address(0), "Position does not exist");

         uint256 stakedValue = getCollateralValue(positionId); // Value scaled 1e18
         uint256 currentSynthDebtValue = getSyntheticValue(positionId); // Value scaled 1e18

         // Max allowed total synthetic value = stakedValue * 10000 / minCollateralRatioBP
         uint256 maxSynthValueAllowed = stakedValue.mul(10000).div(minCollateralRatioBP);

         if (maxSynthValueAllowed <= currentSynthDebtValue) {
             return 0; // Cannot mint more without violating ratio
         }

         // Value of 1 unit (1e18) of synthetic = multiplierBP / 10000 * underlyingPrice (scaled 1e18) / 1e18
         // = multiplierBP * underlyingPrice / 1e22
         // Let's get the value of 1e18 synthetic in 1e18 USD (as used by getSyntheticValue but for a single unit)
         uint256 strategyId = positions[positionId].strategyId;
         require(strategies[strategyId].multiplierBP > 0, "Invalid strategy multiplier");
         uint256 multiplierBP = strategies[strategyId].multiplierBP;
         uint256 underlyingPrice = getUnderlyingPrice(); // Price of 1e18 underlying in 1e18 USD

         // Value of 1e18 synthetic = multiplierBP * underlyingPrice / 10000
         // If underlyingPrice is 1e18 scale, then value of 1e18 synthetic is multiplierBP * underlyingPrice / 1e4
         // But getSyntheticValue calculates value = synthBalance * multiplierBP * underlyingPrice / (1e4 * 1e18)
         // So value of 1e18 synthetic = 1e18 * multiplierBP * underlyingPrice / (1e4 * 1e18) = multiplierBP * underlyingPrice / 1e4
         // Re-calculate value of 1e18 synthetic in 1e18 USD:
         uint256 valuePerSynthUnitScaled18 = multiplierBP.mul(underlyingPrice).div(10000); // Value of 1e18 synthetic in 1e18 USD

         if (valuePerSynthUnitScaled18 == 0) {
             return type(uint256).max; // Avoid division by zero, effectively infinite minting if price is zero
         }

         // Difference in value allowed = maxSynthValueAllowed - currentSynthDebtValue
         uint256 valueDiff = maxSynthValueAllowed.sub(currentSynthDebtValue);

         // Amount of synthetic that can be minted = valueDiff / (value per synth unit)
         // = valueDiff (1e18) / (valuePerSynthUnitScaled18 (1e18) / 1e18 (synth unit))
         // = valueDiff * 1e18 / valuePerSynthUnitScaled18
         uint256 maxMintableScaled18 = valueDiff.mul(1e18).div(valuePerSynthUnitScaled18);

         // Subtract potential fees if this is used before calling mintSynthetic
         // The fee is calculated on the *gross* amount minted, not the net.
         // Let M = gross amount. Fee = M * protocolFeeBP / 10000. Net = M - Fee = M * (10000 - protocolFeeBP) / 10000
         // If maxMintableScaled18 is the *net* amount, the gross amount needed is maxMintableScaled18 * 10000 / (10000 - protocolFeeBP)
         // If maxMintableScaled18 is the *gross* amount, the calculation is simpler.
         // The ratio check is based on the total synthetic debt *amount* held by the position.
         // So the relevant value for the ratio check is the total synthetic *amount* (syntheticBalance).
         // Let S be the total synthetic amount (syntheticBalance + new amount).
         // Value(S) = S * multiplierBP / 10000 * underlyingPrice / 1e18
         // Need Value(S) <= stakedValue * 10000 / minCollateralRatioBP
         // S * multiplierBP / 10000 * underlyingPrice / 1e18 <= stakedValue * 10000 / minCollateralRatioBP
         // S <= (stakedValue * 10000 / minCollateralRatioBP) * (10000 * 1e18) / (multiplierBP * underlyingPrice)
         // S <= stakedValue * 1e8 * 1e18 / (minCollateralRatioBP * multiplierBP * underlyingPrice)
         // S <= (stakedValue * 1e26) / (minCollateralRatioBP * multiplierBP * underlyingPrice)
         // Max total synthetic amount (scaled 1e18) = (stakedValue (1e18) * 1e8 * 1e18) / (minCollateralRatioBP (1e4) * multiplierBP (1e4) * underlyingPrice (1e18))
         // = (stakedValue * 1e26) / (minCollateralRatioBP * multiplierBP * underlyingPrice)
         // Max Total Synthetic Amount (1e18) = stakedValue (1e18) * 10000 / minCollateralRatioBP * 1e18 / (multiplierBP * underlyingPrice / 1e4)
         // Let VPU = Value Per Synth Unit (1e18 USD) = multiplierBP * underlyingPrice / 10000 (if price is 1e18 per 1e18)
         // Max Total Synth Amount (1e18) = (stakedValue * 10000 / minCollateralRatioBP) / VPU * 1e18
         // = maxSynthValueAllowed (1e18) / VPU (1e18/1e18 synth) * 1e18 (synth unit)
         // = maxSynthValueAllowed * 1e18 / VPU
         // This seems right. Max total synthetic amount is maxSynthValueAllowed * 1e18 / valuePerSynthUnitScaled18.
         uint256 maxTotalSyntheticAmountScaled18 = maxSynthValueAllowed.mul(1e18).div(valuePerSynthUnitScaled18);

         // maxMintable is maxTotal - currentDebt
         uint256 maxMintableAmount = 0;
         if (maxTotalSyntheticAmountScaled18 > positions[positionId].syntheticBalance) {
              maxMintableAmount = maxTotalSyntheticAmountScaled18.sub(positions[positionId].syntheticBalance);
         }

         // This is the max *total* amount you could mint (including fee portion).
         // mintSynthetic takes the requested *gross* amount (before fee).
         return maxMintableAmount;
     }

     /**
     * @dev Sets the strategy ID for a specific position.
     * @param positionId The ID of the position NFT.
     * @param newStrategyId The ID of the new strategy to use.
     */
    function setUserStrategy(uint256 positionId, uint256 newStrategyId) external {
        address user = msg.sender;
        require(ownerOf(positionId) == user, "Not owner of position");
        require(strategies[newStrategyId].multiplierBP > 0, "Strategy does not exist"); // Check if strategy is valid

        uint256 oldStrategyId = positions[positionId].strategyId;
        require(oldStrategyId != newStrategyId, "New strategy is the same as current");

        positions[positionId].strategyId = newStrategyId;

        // Check collateral ratio after changing strategy, as the multiplier might change value
        uint256 currentRatio = getCurrentCollateralRatio(positionId);
        require(currentRatio >= minCollateralRatioBP, "New strategy causes insufficient collateral ratio");

        emit UserStrategyChanged(positionId, oldStrategyId, newStrategyId);
    }


    // --- Liquidation ---

    /**
     * @dev Allows liquidation of an undercollateralized position.
     * Liquidator gets a portion of the seized collateral as incentive.
     * The synthetic debt is burnt.
     * @param positionId The ID of the position NFT to liquidate.
     */
    function liquidatePosition(uint256 positionId) external nonReentrant {
        require(positions[positionId].owner != address(0), "Position does not exist");
        require(positions[positionId].syntheticBalance > 0, "Position has no synthetic debt");

        uint256 currentRatio = getCurrentCollateralRatio(positionId);
        require(currentRatio < minCollateralRatioBP, "Position is not undercollateralized");

        address liquidator = msg.sender;
        uint256 synthDebt = positions[positionId].syntheticBalance;
        uint256 stakedCollateral = positions[positionId].stakedAmount;

        // Burn the synthetic debt from the protocol's balance
        // In this model, the debt is on the position struct, not minted to the user's wallet directly
        // until they call mintSynthetic. When liquidating, we conceptually "recover" the debt
        // by transferring collateral proportional to the debt's value.
        // The simplest liquidation is to seize all collateral and burn all debt.
        // A more complex system would calculate partial liquidation.
        // Let's implement full liquidation for simplicity here.

        // Burn all synthetic debt associated with the position
        uint256 totalSynthSupplyBefore = totalSupply();
        _burn(positions[positionId].owner, balanceOf(positions[positionId].owner)); // Burn synthetic held by position owner
        // The syntheticBalance in the struct represents the amount *owed* by the position, not necessarily tokens held by the user.
        // Let's assume `mintSynthetic` mints to the owner and updates `syntheticBalance` as debt.
        // So liquidator needs to burn the debt *from the position owner's wallet* and clear the struct debt.
        uint256 ownerSyntheticBalance = balanceOf(positions[positionId].owner);
        if (ownerSyntheticBalance > 0) {
            _burn(positions[positionId].owner, ownerSyntheticBalance); // Burn whatever synth the owner holds
        }
        // The remaining debt represented by `positions[positionId].syntheticBalance` needs to be 'cleared'

        // Calculate collateral to seize. Seize *all* collateral in this simple model.
        // The incentive is a percentage of the seized collateral value.
        uint256 seizedCollateralAmount = stakedCollateral;
        uint256 incentiveAmount = seizedCollateralAmount.mul(liquidationIncentiveBP.sub(10000)).div(10000); // Incentive is (ratio - 100%)
        uint256 liquidatorReceiveAmount = seizedCollateralAmount.add(incentiveAmount); // Simplified - usually incentive is % *of debt value* paid from collateral
        // Let's use a simpler incentive: Liquidator gets total seized collateral * liquidationIncentiveBP / 10000
        // So if incentive is 10500 BP, liquidator gets 105% of seized collateral.
        liquidatorReceiveAmount = seizedCollateralAmount.mul(liquidationIncentiveBP).div(10000);

        // Transfer seized collateral to liquidator
        positions[positionId].stakedAmount = 0; // Clear staked amount in position
        bool success = IERC20(underlyingToken).transfer(liquidator, liquidatorReceiveAmount);
        require(success, "Underlying transfer failed");

        // Clear synthetic debt from the position struct
        positions[positionId].syntheticBalance = 0; // Clear synthetic debt

        // Remove the position NFT from the owner (optional, could also transfer to a liquidation address or burn)
        // Let's just remove the _userPositionId mapping entry. The NFT still exists unless burnt.
        _userPositionId[positions[positionId].owner] = 0;
        // Could burn the NFT: _burn(ownerOf(positionId), positionId);

        emit Liquidation(positionId, liquidator, seizedCollateralAmount, synthDebt); // Emit original seized/burnt amounts

        // Note: The difference between `liquidatorReceiveAmount` and `stakedCollateralAmount`
        // is either profit (if incentive is >100%) or loss for the protocol/vault.
        // In a real system, the incentive is typically a fixed percentage *of the liquidated debt value*
        // paid out of the collateral. E.g., if debt value is $1000, liquidator gets $50 incentive,
        // needing $1050 of collateral.
        // The current implementation gives liquidator 105% of seized collateral, which is simpler but different.
    }


    // --- Governance Interaction (Simulated) ---

    /**
     * @dev Allows a governance member to propose a change to a strategy's multiplier.
     * @param strategyId The ID of the strategy to propose changes for.
     * @param proposedMultiplierBP The new multiplier in basis points.
     * @param votingDuration The duration in seconds for voting.
     */
    function proposeStrategyMultiplierChange(uint256 strategyId, uint256 proposedMultiplierBP, uint256 votingDuration) external onlyGovernance {
        require(strategies[strategyId].multiplierBP > 0, "Strategy does not exist");
        require(votingDuration > 0, "Voting duration must be > 0");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            strategyId: strategyId,
            proposedMultiplierBP: proposedMultiplierBP,
            votesFor: 0,
            votesAgainst: 0,
            endTime: block.timestamp + votingDuration,
            executed: false,
            passed: false
        });

        emit ProposalCreated(proposalId, strategyId, proposedMultiplierBP, proposals[proposalId].endTime);
    }

    /**
     * @dev Allows eligible voters (simulated: anyone) to vote on an active proposal.
     * @param proposalId The ID of the proposal.
     * @param support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 proposalId, bool support) external {
        require(proposals[proposalId].endTime > block.timestamp, "Voting period has ended");
        require(!proposals[proposalId].executed, "Proposal already executed");
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        // In a real system, voting weight would be based on governance token holdings, staked tokens, NFT lockup, etc.
        // For this simulation, each address gets 1 vote.

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposals[proposalId].votesFor++;
        } else {
            proposals[proposalId].votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Allows anyone to execute a proposal if the voting period has ended and it passed.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) external {
        require(proposals[proposalId].endTime <= block.timestamp, "Voting period not ended");
        require(!proposals[proposalId].executed, "Proposal already executed");

        Proposal storage proposal = proposals[proposalId];

        // Simple majority required to pass (simulate)
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;
            // Execute the proposal logic
            uint256 strategyIdToUpdate = proposal.strategyId;
            uint256 newMultiplier = proposal.proposedMultiplierBP;
            uint256 oldMultiplier = strategies[strategyIdToUpdate].multiplierBP;
            strategies[strategyIdToUpdate].multiplierBP = newMultiplier;
            emit StrategyUpdated(strategyIdToUpdate, oldMultiplier, newMultiplier);
        } else {
            proposal.passed = false;
            // Proposal failed, no state change
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Adds a new strategy definition. Callable only by governance.
     * @param strategyId The ID for the new strategy.
     * @param multiplierBP The multiplier in basis points.
     * @param riskScore The simulated risk score.
     */
    function addStrategy(uint256 strategyId, uint256 multiplierBP, uint256 riskScore) external onlyGovernance {
         require(strategies[strategyId].multiplierBP == 0, "Strategy ID already exists");
         require(multiplierBP > 0, "Multiplier must be > 0");
         strategies[strategyId] = Strategy({
             multiplierBP: multiplierBP,
             riskScore: riskScore
         });
         // No specific event for adding strategy, StrategyUpdated could cover initial setting too
    }


    // --- Protocol Fees ---

    /**
     * @dev Allows the governance contract or owner to claim accumulated protocol fees.
     * Fees are in the synthetic token.
     * @param receiver The address to send the fees to.
     */
    function claimProtocolFees(address receiver) external onlyGovernance {
        // Fees are implicitly held in the contract's balance of the synthetic token.
        // The amount of fees is the total synthetic minted MINUS the amount sent to users.
        // Total minted = totalSupply(). Amount sent to users = sum of all syntheticBalance in positions? No.
        // Amount sent to users = total supply MINUS fees accumulated.
        // The fee amount on each mint is `amount * protocolFeeBP / 10000`. This amount is *not* minted to the user.
        // It effectively increases the total supply without increasing any user's balance.
        // The balance held by `address(this)` IS the accumulated fee.
        uint256 feeAmount = balanceOf(address(this));
        require(feeAmount > 0, "No fees accumulated");

        _transfer(address(this), receiver, feeAmount);
        emit FeesClaimed(address(this), receiver, feeAmount);
    }

    // --- Admin & Utility ---

    /**
     * @dev Allows owner to sweep accidental token transfers sent to the contract.
     * Does not allow sweeping the underlying or synthetic tokens.
     * @param tokenAddress The address of the token to sweep.
     * @param receiver The address to send the tokens to.
     */
    function sweepDust(address tokenAddress, address receiver) external onlyOwner {
        require(tokenAddress != underlyingToken, "Cannot sweep underlying token");
        require(tokenAddress != address(this), "Cannot sweep synthetic token"); // Address of ERC20 token is this contract

        IERC20 dustToken = IERC20(tokenAddress);
        uint256 balance = dustToken.balanceOf(address(this));
        require(balance > 0, "No dust balance");

        dustToken.transfer(receiver, balance);
    }

    /**
     * @dev Allows owner to set the address of the governance contract.
     * @param newGov The new governance contract address.
     */
    function setGovernanceAddress(address newGov) external onlyOwner {
        require(newGov != address(0), "New governance address cannot be zero");
        governanceContract = newGov;
    }

    /**
     * @dev Allows owner to set the address of the oracle contract.
     * @param newOracle The new oracle contract address.
     */
     function setOracleAddress(address newOracle) external onlyOwner {
         require(newOracle != address(0), "New oracle address cannot be zero");
         oracleContract = newOracle;
     }


    // --- View Functions ---

     /**
     * @dev Gets all details for a specific position.
     * @param positionId The ID of the position NFT.
     * @return owner The owner of the position NFT (can be different from original depositor).
     * @return originalOwner The original depositor (used for debt/permit logic).
     * @return stakedAmount The amount of underlying token staked.
     * @return syntheticBalance The amount of synthetic token debt held by the position.
     * @return lockupEndTime The timestamp when the lockup expires (0 if not locked).
     * @return strategyId The ID of the current strategy used by the position.
     * @return currentRatio The current collateral ratio in basis points.
     * @return mintNonce The current nonce for permitMint.
     */
    function getPositionDetails(uint256 positionId)
        public
        view
        returns (
            address owner, // NFT owner
            address originalOwner, // Original depositor
            uint256 stakedAmount,
            uint256 syntheticBalance,
            uint256 lockupEndTime,
            uint256 strategyId,
            uint256 currentRatio,
            uint256 mintNonce
        )
    {
        require(_exists(positionId), "Position NFT does not exist"); // Check NFT existence
        require(positions[positionId].owner != address(0), "Position data not initialized"); // Check struct existence

        Position storage pos = positions[positionId];
        owner = ownerOf(positionId); // ERC721 owner
        originalOwner = pos.owner; // Original depositor
        stakedAmount = pos.stakedAmount;
        syntheticBalance = pos.syntheticBalance;
        lockupEndTime = pos.lockupEndTime;
        strategyId = pos.strategyId;
        currentRatio = getCurrentCollateralRatio(positionId); // Dynamic calculation
        mintNonce = pos.mintNonce;
    }

    /**
     * @dev Gets details for a specific strategy.
     * @param strategyId The ID of the strategy.
     * @return multiplierBP The multiplier in basis points.
     * @return riskScore The simulated risk score.
     */
    function getStrategyDetails(uint256 strategyId) public view returns (uint256 multiplierBP, uint256 riskScore) {
        require(strategies[strategyId].multiplierBP > 0, "Strategy does not exist");
        Strategy storage strat = strategies[strategyId];
        multiplierBP = strat.multiplierBP;
        riskScore = strat.riskScore;
    }

    /**
     * @dev Gets details for a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return strategyId The target strategy ID.
     * @return proposedMultiplierBP The proposed new multiplier.
     * @return votesFor Total votes for the proposal.
     * @return votesAgainst Total votes against the proposal.
     * @return endTime The timestamp when voting ends.
     * @return executed Whether the proposal has been executed.
     * @return passed Whether the proposal passed (after execution).
     */
    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (
            uint256 strategyId,
            uint256 proposedMultiplierBP,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 endTime,
            bool executed,
            bool passed
        )
    {
        require(proposals[proposalId].endTime > 0 || proposalId == _proposalIds.current(), "Proposal does not exist"); // Check existence
        Proposal storage prop = proposals[proposalId];
        strategyId = prop.strategyId;
        proposedMultiplierBP = prop.proposedMultiplierBP;
        votesFor = prop.votesFor;
        votesAgainst = prop.votesAgainst;
        endTime = prop.endTime;
        executed = prop.executed;
        passed = prop.passed;
    }

     /**
     * @dev Checks if a position is currently locked.
     * @param positionId The ID of the position NFT.
     * @return bool True if locked, false otherwise.
     */
    function isPositionLocked(uint256 positionId) public view returns (bool) {
        require(positions[positionId].owner != address(0), "Position does not exist");
        return positions[positionId].lockupEndTime > block.timestamp;
    }

    /**
     * @dev Get the domain separator for EIP-712 signatures.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    /**
     * @dev Get the position ID for a given user.
     * Note: This only returns the primary position created by depositUnderlying.
     * A user could own multiple positions if they were transferred to them.
     * @param user The user address.
     * @return positionId The primary position ID, or 0 if none found.
     */
    function userPositionId(address user) external view returns (uint256) {
        return _userPositionId[user];
    }

    // Helper function to calculate amount mintable in the context of a potential mint call
    // (similar to calculateMintableAmount, but perhaps simpler or used internally)
     /**
     * @dev Internal helper to check if a mint amount is valid based on collateral ratio.
     * @param positionId The ID of the position NFT.
     * @param amountToMint The amount of synthetic tokens *gross* to be minted (before fee).
     * @return bool True if minting this amount is valid, false otherwise.
     */
    function _isValidMintAmount(uint256 positionId, uint256 amountToMint) internal view returns (bool) {
        uint256 currentSynthDebt = positions[positionId].syntheticBalance;
        uint256 potentialNewSynthDebt = currentSynthDebt.add(amountToMint);

        if (potentialNewSynthDebt == 0) return true; // Always valid to mint 0 or if resulting debt is 0

        uint256 stakedValue = getCollateralValue(positionId); // Value scaled 1e18
        uint256 strategyId = positions[positionId].strategyId;
        require(strategies[strategyId].multiplierBP > 0, "Invalid strategy multiplier"); // Ensure strategy exists/is valid
        uint256 multiplierBP = strategies[strategyId].multiplierBP;
        uint256 underlyingPrice = getUnderlyingPrice(); // Price of 1e18 underlying in 1e18 USD

        // Value of potential new total synth debt (scaled 1e18)
        // = potentialNewSynthDebt (1e18) * multiplierBP / 10000 * underlyingPrice (1e18) / 1e18
        uint256 potentialSynthValueScaled18 = potentialNewSynthDebt.mul(multiplierBP).div(10000).mul(underlyingPrice).div(1e18);

        // Check if staked value meets minimum ratio compared to potential synth value
        // stakedValue * 10000 / potentialSynthValueScaled18 >= minCollateralRatioBP
        // stakedValue * 10000 >= potentialSynthValueScaled18 * minCollateralRatioBP
         return stakedValue.mul(10000) >= potentialSynthValueScaled18.mul(minCollateralRatioBP);
    }

    // Add a fallback or receive function if you expect ETH payments (not used in this ERC20/ERC721 vault)
    // receive() external payable { revert("ETH not accepted"); }
    // fallback() external payable { revert("Calls not supported"); }

    // Note on ERC721Enumerable: This adds functions like `tokenOfOwnerByIndex`, `totalSupply`, `tokenByIndex`.
    // These can be useful but also increase gas costs and are sometimes omitted in large NFT collections.
    // For this demo, it's included.

    // Note on ERC20 Fees: The fee mechanism here means the total supply reported by ERC20
    // will be (user minted amount + protocol fee amount). The protocol fee amount is
    // held in `balanceOf(address(this))`.

    // Note on Governance: The `governanceContract` and `onlyGovernance` modifier is simulated.
    // In a real system, `onlyGovernance` would check if `msg.sender` is the expected governance contract.
    // The governance contract itself would manage proposals, voting power, and calling these functions.

     // ERC721 Overrides for Enumerable
     function _increaseBalance(address account, uint256 amount) internal pure override {} // Not needed for ERC721Enumerable token balance, overrides ERC721

}
```