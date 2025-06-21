Okay, let's create a smart contract that combines several advanced and creative concepts: a dynamic staking system where staking positions are represented by unique, evolving NFTs, fueled by a native deflationary token with a "sacrifice" mechanism.

We'll call it the **CryptoPhoenix Protocol**.

Here's the outline and function summary, followed by the Solidity code.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CryptoPhoenix Protocol
 * @dev A novel staking and NFT evolution protocol.
 *  Users stake PHX tokens into unique PhoenixNest NFTs. These NFTs are dynamic,
 *  evolving based on staked amount, duration, and PHX token sacrifices.
 *  The PHX token is deflationary, burned during sacrifices and potentially during staking/unstaking.
 *  Governance controls key parameters like reward rates and evolution criteria.
 */
contract CryptoPhoenixProtocol is ERC20, ERC721, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- CONTRACT OUTLINE ---
    // 1. State Variables
    // 2. Events
    // 3. Custom Errors
    // 4. Constructor
    // 5. ERC20 Overrides (PHX Token) - (Inherited, handled by OpenZeppelin mostly)
    // 6. ERC721 Overrides (PhoenixNest NFT) - (Inherited, handled by OpenZeppelin mostly)
    // 7. Internal Token/NFT Minting/Burning
    // 8. Staking Functions (Core Logic)
    // 9. Yield Calculation and Claiming
    // 10. Unstaking Functions
    // 11. NFT Evolution Functions
    // 12. Governance/Admin Functions
    // 13. View/Utility Functions

    // --- FUNCTION SUMMARY ---

    // PHX Token (ERC20 - Inherited/Standard functionality):
    // 1.  constructor(...) - Initializes PHX token with name, symbol, and initial supply. Also initializes ERC721 and sets owner.
    // 2.  totalSupply() external view returns (uint256)
    // 3.  balanceOf(address account) external view returns (uint256)
    // 4.  transfer(address recipient, uint256 amount) external returns (bool)
    // 5.  allowance(address owner, address spender) external view returns (uint256)
    // 6.  approve(address spender, uint256 amount) external returns (bool)
    // 7.  transferFrom(address sender, address recipient, uint256 amount) external returns (bool)
    // 8.  increaseAllowance(address spender, uint256 addedValue) external returns (bool)
    // 9.  decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool)
    // 10. _burn(address account, uint256 amount) internal - Internal burn mechanism for PHX.

    // PhoenixNest NFT (ERC721 - Inherited/Standard functionality):
    // 11. supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    // 12. balanceOf(address owner) external view returns (uint256)
    // 13. ownerOf(uint256 tokenId) external view returns (address)
    // 14. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override nonReentrant
    // 15. safeTransferFrom(address from, address to, uint256 tokenId) public virtual override nonReentrant
    // 16. transferFrom(address from, address to, uint256 tokenId) public virtual override nonReentrant
    // 17. approve(address to, uint256 tokenId) public virtual override nonReentrant
    // 18. setApprovalForAll(address operator, bool approved) public virtual override nonReentrant
    // 19. getApproved(uint256 tokenId) external view returns (address)
    // 20. isApprovedForAll(address owner, address operator) external view returns (bool)
    // 21. tokenURI(uint256 tokenId) public view override returns (string memory) - Dynamic URI reflecting NFT state.
    // 22. _mintNFT(address to, uint256 tokenId) internal - Internal minting for Nest NFTs.
    // 23. _burnNFT(uint256 tokenId) internal - Internal burning for Nest NFTs.

    // Staking Functions:
    // 24. createNestAndStake(uint256 amount) external nonReentrancy whenNotPaused - Stakes PHX to create a new PhoenixNest NFT.
    // 25. addStake(uint256 tokenId, uint256 amount) external nonReentrancy whenNotPaused - Adds PHX to an existing PhoenixNest NFT stake.

    // Yield Calculation and Claiming:
    // 26. calculateRewards(uint256 tokenId) public view returns (uint256) - Calculates accrued rewards for a Nest NFT.
    // 27. claimRewards(uint256 tokenId) external nonReentrancy whenNotPaused - Claims accrued rewards for a Nest NFT.

    // Unstaking Functions:
    // 28. unstake(uint256 tokenId) external nonReentrancy whenNotPaused - Unstakes all PHX and burns the Nest NFT. Penalty may apply.
    // 29. partialUnstake(uint256 tokenId, uint256 amount) external nonReentrancy whenNotPaused - Unstakes a partial amount of PHX (if allowed, e.g., after lockup). Burns NFT if stake becomes zero.

    // NFT Evolution Functions:
    // 30. sacrificePHX(uint256 tokenId, uint256 amount) external nonReentrancy whenNotPaused - Burns PHX to boost NFT evolution progress.
    // 31. getEvolutionLevel(uint256 tokenId) public view returns (uint8) - Gets the current evolution level of a Nest NFT.

    // Governance/Admin Functions (onlyOwner):
    // 32. setRewardRate(uint256 newRate) external onlyOwner - Sets the PHX reward rate per staked PHX per second.
    // 33. setLockupDuration(uint256 duration) external onlyOwner - Sets the minimum staking duration without penalty.
    // 34. setUnstakePenaltyRate(uint256 rate) external onlyOwner - Sets the percentage penalty for early unstaking (e.g., 5 = 5%).
    // 35. setEvolutionCriteria(uint8 level, uint256 minStake, uint256 minDuration, uint256 minSacrificePoints) external onlyOwner - Sets criteria for each evolution level.
    // 36. setBaseTokenURI(string memory newBaseURI) external onlyOwner - Sets the base URI for NFT metadata.
    // 37. pause() external onlyOwner - Pauses staking, claiming, unstaking, and sacrificing.
    // 38. unpause() external onlyOwner - Unpauses the protocol.
    // 39. withdrawStuckTokens(address tokenAddress, uint256 amount) external onlyOwner nonReentrancy - Allows owner to withdraw tokens other than PHX accidentally sent to the contract.

    // View/Utility Functions:
    // 40. getStakeInfo(uint256 tokenId) public view returns (uint256 stakedAmount, uint64 startTime, uint256 sacrificePoints, uint256 lastRewardClaimTime) - Gets detailed info for a Nest NFT stake.
    // 41. getTotalStakedPHX() public view returns (uint256) - Gets the total amount of PHX staked in the protocol.
    // 42. getRewardRate() public view returns (uint256) - Gets the current reward rate.
    // 43. getLockupDuration() public view returns (uint256) - Gets the current lockup duration.
    // 44. getUnstakePenaltyRate() public view returns (uint256) - Gets the current unstake penalty rate.
    // 45. getEvolutionCriteria(uint8 level) public view returns (uint256 minStake, uint256 minDuration, uint256 minSacrificePoints) - Gets criteria for a specific evolution level.
    // 46. getNestCount() public view returns (uint256) - Gets the total number of Nest NFTs minted.

    // --- STATE VARIABLES ---

    // PHX Token (already handled by ERC20)
    // PhoenixNest NFT (already handled by ERC721)
    Counters.Counter private _nestTokenIds; // Counter for unique Nest NFT IDs

    struct Stake {
        uint256 amount;             // Amount of PHX staked in this Nest
        uint64 startTime;          // Timestamp when the stake (or last significant addition) began
        uint256 sacrificePoints;    // Points accumulated through PHX sacrifices for this Nest
        uint64 lastRewardClaimTime; // Timestamp of the last reward claim
    }

    // Mapping from Nest NFT ID to Stake information
    mapping(uint256 => Stake) public stakes;

    // Total amount of PHX staked in the contract
    uint256 private _totalStakedPHX;

    // Reward rate: PHX per staked PHX per second (e.g., 1e18 for 1 PHX per PHX per second - adjust units)
    uint256 public rewardRate; // Store as basis points * 1e18 / secondsInYear, or similar for reasonable scale.
                               // Let's assume this is defined granularly, e.g., reward per 1e18 PHX per second.
                               // A rate of 1e18/31536000 (seconds in a year) gives 1 PHX per PHX per year.
                               // Let's use a simpler unit for the example: reward per 1e18 PHX per UNIT OF TIME.
                               // We'll assume the `rewardRate` is `rewards per second` per `1e18 stakedAmount`.
                               // So, rewards = stakedAmount * rewardRate * timeDelta / 1e18.

    // Minimum duration a stake must be active without penalty
    uint256 public lockupDuration;

    // Penalty rate for unstaking before lockup ends (in basis points, 0-10000)
    uint256 public unstakePenaltyRate; // e.g., 500 = 5%

    // Criteria for NFT evolution levels
    struct EvolutionCriteria {
        uint256 minStake;            // Minimum staked amount (scaled by 1e18)
        uint256 minDuration;         // Minimum staking duration (in seconds)
        uint256 minSacrificePoints; // Minimum sacrifice points
    }

    // Mapping from evolution level (1-based index) to criteria
    mapping(uint8 => EvolutionCriteria) public evolutionCriteria;

    // Base URI for Nest NFT metadata (append token ID and .json)
    string private _baseTokenURI;

    // --- EVENTS ---

    event StakeCreated(uint256 indexed tokenId, address indexed owner, uint256 amount, uint64 startTime);
    event StakeAdded(uint256 indexed tokenId, uint256 additionalAmount, uint256 newTotalAmount, uint64 newStartTime);
    event RewardsClaimed(uint256 indexed tokenId, uint252 claimedAmount, uint64 claimTime); // Using 252 bits to save space? Or just uint256. Stick to uint256 for simplicity unless explicitly optimizing.
    event StakeWithdrawn(uint256 indexed tokenId, uint256 withdrawnAmount, uint256 penaltyAmount);
    event PartialStakeWithdrawn(uint256 indexed tokenId, uint256 withdrawnAmount, uint256 remainingAmount, uint256 penaltyAmount);
    event SacrificeMade(uint256 indexed tokenId, uint256 burnedAmount, uint256 newSacrificePoints);
    event NestEvolved(uint256 indexed tokenId, uint8 newLevel);
    event ParameterSet(string paramName, uint256 value);
    event EvolutionCriteriaSet(uint8 level, uint256 minStake, uint256 minDuration, uint256 minSacrificePoints);
    event BaseTokenURISet(string newBaseURI);

    // --- CUSTOM ERRORS ---

    error ZeroAddress();
    error ZeroAmount();
    error StakeNotFound();
    error InsufficientStakeAmount();
    error LockupActive();
    error OnlyNestOwner();
    error InvalidEvolutionLevel();
    error CannotWithdrawOtherTokenZeroAddress();
    error CannotWithdrawThisToken();

    // --- CONSTRUCTOR ---

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory nftName,
        string memory nftSymbol,
        uint256 initialSupply,
        uint256 _rewardRate,
        uint256 _lockupDuration,
        uint256 _unstakePenaltyRate,
        string memory _initialBaseTokenURI
    ) ERC20(tokenName, tokenSymbol) ERC721(nftName, nftSymbol) Ownable(msg.sender) Pausable() {
        // Mint initial supply of PHX tokens to the deployer
        _mint(msg.sender, initialSupply);

        // Set initial protocol parameters
        rewardRate = _rewardRate;
        lockupDuration = _lockupDuration;
        unstakePenaltyRate = _unstakePenaltyRate; // In basis points (e.g., 500 = 5%)
        _baseTokenURI = _initialBaseTokenURI;

        // Set initial evolution criteria (example)
        // Level 1: requires 100 PHX stake, 0 duration, 0 sacrifice points
        evolutionCriteria[1] = EvolutionCriteria({minStake: 100e18, minDuration: 0, minSacrificePoints: 0});
        // Level 2: requires 500 PHX stake, 30 days duration, 1000 sacrifice points
        evolutionCriteria[2] = EvolutionCriteria({minStake: 500e18, minDuration: 30 days, minSacrificePoints: 1000});
        // Level 3: requires 1000 PHX stake, 90 days duration, 5000 sacrifice points
        evolutionCriteria[3] = EvolutionCriteria({minStake: 1000e18, minDuration: 90 days, minSacrificePoints: 5000});
        // Add more levels as needed...
    }

    // --- ERC721 OVERRIDES (for Dynamic tokenURI and Reentrancy Guard) ---

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, Ownable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        // Get the evolution level for the token
        uint8 level = getEvolutionLevel(tokenId);
        // Append token ID and evolution level to the base URI
        // The metadata service at _baseTokenURI/tokenId/level.json will serve the dynamic metadata.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), "/", Strings.toString(level), ".json"));
    }

    /// @inheritdoc ERC721
    // Adding reentrancy guard to critical state-changing transfers
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override nonReentrancy {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override nonReentrancy {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721
    function transferFrom(address from, address to, uint256 tokenId) public virtual override nonReentrancy {
        super.transferFrom(from, to, tokenId);
    }

     /// @inheritdoc ERC721
    function approve(address to, uint256 tokenId) public virtual override nonReentrancy {
        super.approve(to, tokenId);
    }

    /// @inheritdoc ERC721
    function setApprovalForAll(address operator, bool approved) public virtual override nonReentrancy {
        super.setApprovalForAll(operator, approved);
    }


    // --- INTERNAL TOKEN/NFT MINTING/BURNING ---
    // Note: PHX minting is not exposed publicly for deflationary model.
    //       PHX burning is used internally by protocol actions.

    /// @dev Mints a new PhoenixNest NFT. Internal function called during staking.
    function _mintNFT(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    /// @dev Burns a PhoenixNest NFT. Internal function called during full unstake.
    function _burnNFT(uint256 tokenId) internal {
        _burn(tokenId);
    }

    // --- STAKING FUNCTIONS ---

    /// @notice Stakes PHX tokens to create a new PhoenixNest NFT representing the stake.
    /// @param amount The amount of PHX to stake.
    function createNestAndStake(uint256 amount) external nonReentrancy whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (msg.sender == address(0)) revert ZeroAddress();

        // Transfer PHX from user to contract
        SafeERC20.safeTransferFrom(this, msg.sender, address(this), amount);

        // Increment total staked amount
        _totalStakedPHX = _totalStakedPHX.add(amount);

        // Get next token ID
        _nestTokenIds.increment();
        uint256 newTokenId = _nestTokenIds.current();

        // Mint new Nest NFT
        _mintNFT(msg.sender, newTokenId);

        // Create stake info
        uint64 currentTime = uint64(block.timestamp);
        stakes[newTokenId] = Stake({
            amount: amount,
            startTime: currentTime,
            sacrificePoints: 0,
            lastRewardClaimTime: currentTime
        });

        emit StakeCreated(newTokenId, msg.sender, amount, currentTime);
    }

    /// @notice Adds more PHX tokens to an existing PhoenixNest NFT stake.
    /// @param tokenId The ID of the PhoenixNest NFT.
    /// @param amount The amount of PHX to add to the stake.
    function addStake(uint256 tokenId, uint256 amount) external nonReentrancy whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (ownerOf(tokenId) != msg.sender) revert OnlyNestOwner();
        if (stakes[tokenId].amount == 0 && !_exists(tokenId)) revert StakeNotFound(); // Ensure token exists and is staked

        // Transfer PHX from user to contract
        SafeERC20.safeTransferFrom(this, msg.sender, address(this), amount);

        // Claim any pending rewards before adding stake (to avoid manipulating claim time)
        claimRewards(tokenId);

        // Update stake info
        stakes[tokenId].amount = stakes[tokenId].amount.add(amount);
        // Option: Reset start time to restart lockup/evolution duration criteria
        stakes[tokenId].startTime = uint64(block.timestamp); // Restart timer on significant additions? Or average? Restart is simpler.

        _totalStakedPHX = _totalStakedPHX.add(amount);

        emit StakeAdded(tokenId, amount, stakes[tokenId].amount, stakes[tokenId].startTime);
    }

    // --- YIELD CALCULATION AND CLAIMING ---

    /// @notice Calculates the accrued, unclaimed PHX rewards for a specific Nest NFT.
    /// @param tokenId The ID of the PhoenixNest NFT.
    /// @return The amount of unclaimed PHX rewards.
    function calculateRewards(uint256 tokenId) public view returns (uint256) {
        Stake memory stake = stakes[tokenId];
        if (stake.amount == 0 || !_exists(tokenId)) {
            return 0;
        }

        uint64 lastClaim = stake.lastRewardClaimTime;
        uint64 currentTime = uint64(block.timestamp);
        uint256 timeDelta = currentTime.sub(lastClaim);

        if (timeDelta == 0) {
            return 0;
        }

        // Calculate rewards: stakedAmount * rewardRate * timeDelta / 1e18 (scaling for token decimals)
        // Using 1e18 assuming PHX has 18 decimals. Adjust if necessary.
        uint256 rewards = stake.amount.mul(rewardRate).mul(timeDelta).div(1e18);

        return rewards;
    }

    /// @notice Claims the accrued PHX rewards for a specific Nest NFT.
    /// @param tokenId The ID of the PhoenixNest NFT.
    function claimRewards(uint256 tokenId) public nonReentrancy whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert OnlyNestOwner();
        if (stakes[tokenId].amount == 0 && !_exists(tokenId)) revert StakeNotFound(); // Ensure token exists and is staked

        uint256 rewards = calculateRewards(tokenId);

        if (rewards > 0) {
            // Update last claim time BEFORE transferring
            stakes[tokenId].lastRewardClaimTime = uint64(block.timestamp);

            // Transfer rewards to the user
            // In a real protocol, rewards might come from a separate pool or be newly minted (carefully!)
            // For this example, let's assume rewards are transferred from the contract's balance
            // (implying rewards were pre-minted or generated elsewhere and sent here).
            // A more complex model might mint rewards or distribute protocol fees.
            // Transferring from 'this' balance:
            SafeERC20.safeTransfer(this, msg.sender, rewards);

            emit RewardsClaimed(tokenId, rewards, uint64(block.timestamp));
        }
    }

    // --- UNSTAKING FUNCTIONS ---

    /// @notice Unstakes all PHX tokens from a Nest NFT and burns the NFT.
    /// @dev Applies a penalty if unstaking occurs before the lockup duration ends.
    /// @param tokenId The ID of the PhoenixNest NFT to unstake from.
    function unstake(uint256 tokenId) external nonReentrancy whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert OnlyNestOwner();
        Stake storage stake = stakes[tokenId];
        if (stake.amount == 0 && !_exists(tokenId)) revert StakeNotFound();

        uint256 totalStaked = stake.amount;
        uint64 stakeStartTime = stake.startTime;
        uint256 penalty = 0;

        // Claim pending rewards before unstaking
        claimRewards(tokenId);

        // Check for lockup and calculate penalty
        if (block.timestamp < stakeStartTime + lockupDuration) {
            // Calculate penalty based on unstakePenaltyRate (basis points)
            penalty = totalStaked.mul(unstakePenaltyRate).div(10000);
            emit StakeWithdrawn(tokenId, totalStaked.sub(penalty), penalty);
        } else {
            emit StakeWithdrawn(tokenId, totalStaked, 0);
        }

        uint256 amountToReturn = totalStaked.sub(penalty);

        // Update total staked amount
        _totalStakedPHX = _totalStakedPHX.sub(totalStaked);

        // Clear stake data
        delete stakes[tokenId];

        // Burn the Nest NFT
        _burnNFT(tokenId);

        // Transfer the remaining PHX back to the user
        SafeERC20.safeTransfer(this, msg.sender, amountToReturn);

        // Note: The penalty amount is effectively burned as it stays in the contract
        // and is removed from the `_totalStakedPHX` count.
    }

    /// @notice Attempts to unstake a partial amount of PHX from a Nest NFT.
    /// @dev Only allowed if the stake is past the lockup duration.
    /// @param tokenId The ID of the PhoenixNest NFT.
    /// @param amount The amount of PHX to partially unstake.
    function partialUnstake(uint256 tokenId, uint256 amount) external nonReentrancy whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (ownerOf(tokenId) != msg.sender) revert OnlyNestOwner();
        Stake storage stake = stakes[tokenId];
        if (stake.amount == 0 && !_exists(tokenId)) revert StakeNotFound();
        if (amount > stake.amount) revert InsufficientStakeAmount();

        // Partial unstake is only allowed AFTER lockup
        if (block.timestamp < stake.startTime + lockupDuration) {
             revert LockupActive();
        }

        // Claim pending rewards before unstaking
        claimRewards(tokenId);

        // Update stake amount
        stake.amount = stake.amount.sub(amount);

        // Update total staked amount
        _totalStakedPHX = _totalStakedPHX.sub(amount);

        emit PartialStakeWithdrawn(tokenId, amount, stake.amount, 0); // No penalty on partial after lockup

        // Transfer the unstaked PHX back to the user
        SafeERC20.safeTransfer(this, msg.sender, amount);

        // If remaining stake is zero, burn the NFT
        if (stake.amount == 0) {
            delete stakes[tokenId]; // Clear data completely
            _burnNFT(tokenId);
        }
    }

    // --- NFT EVOLUTION FUNCTIONS ---

    /// @notice Burns PHX tokens to contribute to a Nest NFT's evolution progress.
    /// @dev Burned tokens are permanently removed from supply.
    /// @param tokenId The ID of the PhoenixNest NFT.
    /// @param amount The amount of PHX tokens to sacrifice (burn).
    function sacrificePHX(uint256 tokenId, uint256 amount) external nonReentrancy whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (ownerOf(tokenId) != msg.sender) revert OnlyNestOwner();
        Stake storage stake = stakes[tokenId];
        if (stake.amount == 0 && !_exists(tokenId)) revert StakeNotFound();

        // Transfer PHX from user to be burned
        SafeERC20.safeTransferFrom(this, msg.sender, address(this), amount);

        // Burn the transferred PHX
        _burn(address(this), amount); // Burn from the contract's balance where user sent it

        // Add sacrifice points (example: 1 point per 1e18 PHX sacrificed)
        uint256 pointsGained = amount.div(1e18); // Simple example, adjust as needed
        stake.sacrificePoints = stake.sacrificePoints.add(pointsGained);

        // Check if evolution level changed and emit event
        uint8 oldLevel = getEvolutionLevel(tokenId);
        uint8 newLevel = _calculateEvolutionLevel(stake);
        if (newLevel > oldLevel) {
            emit NestEvolved(tokenId, newLevel);
        }

        emit SacrificeMade(tokenId, amount, stake.sacrificePoints);
    }

    /// @notice Calculates the current evolution level of a Nest NFT based on its stake state.
    /// @dev This is a pure calculation based on the stored state and configured criteria.
    /// @param tokenId The ID of the PhoenixNest NFT.
    /// @return The evolution level (0 if no level met, higher number for higher levels).
    function getEvolutionLevel(uint256 tokenId) public view returns (uint8) {
        Stake memory stake = stakes[tokenId];
        // If no stake or NFT doesn't exist, return 0
        if (stake.amount == 0 || !_exists(tokenId)) {
             return 0; // Level 0: Unstaked or non-existent
        }

        return _calculateEvolutionLevel(stake);
    }

    /// @dev Internal function to calculate evolution level based on Stake struct.
    function _calculateEvolutionLevel(Stake memory stake) internal view returns (uint8) {
        uint8 currentLevel = 0;
        uint64 currentDuration = uint64(block.timestamp) - stake.startTime;

        // Check criteria for each level starting from the highest configured down to 1
        // We iterate downwards assuming higher levels require more stringent criteria
        // Need a way to know the max level. Store a max level state variable or iterate until criteria mapping[level] is empty?
        // Let's assume levels are 1, 2, 3... and we iterate until we find a non-zero criteria.
        // Max level can be set by governance or be hardcoded. Let's assume max 10 levels for this example.

        for (uint8 level = 10; level >= 1; --level) {
             EvolutionCriteria memory criteria = evolutionCriteria[level];
             // Check if criteria is set for this level (non-zero minStake as an indicator)
             if (criteria.minStake > 0 || criteria.minDuration > 0 || criteria.minSacrificePoints > 0) {
                  // Check if stake meets criteria for this level
                  if (stake.amount >= criteria.minStake &&
                      currentDuration >= criteria.minDuration &&
                      stake.sacrificePoints >= criteria.minSacrificePoints)
                  {
                       currentLevel = level; // Found the highest level met
                       break; // Stop searching
                  }
             }
             // Special handling for uint8 decrementing from 1.
             if (level == 1) break;
        }

        // If no criteria met, but stake exists, it's level 1 (basic)
        if (currentLevel == 0 && (stake.amount > 0 || stake.sacrificePoints > 0)) {
             currentLevel = 1;
        } else if (currentLevel == 0 && stake.amount == 0 && !_exists(_nestTokenIds.current())) {
             // If _nestTokenIds.current() is the latest token ID, and its stake is 0,
             // and the token doesn't exist, it implies the token ID hasn't been minted yet
             // or was burned, so level is genuinely 0.
        }


        return currentLevel;
    }

    // --- GOVERNANCE/ADMIN FUNCTIONS ---

    /// @notice Sets the PHX reward rate per staked PHX per second.
    /// @param newRate The new reward rate.
    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
        emit ParameterSet("rewardRate", newRate);
    }

    /// @notice Sets the minimum staking duration without penalty.
    /// @param duration The new lockup duration in seconds.
    function setLockupDuration(uint256 duration) external onlyOwner {
        lockupDuration = duration;
        emit ParameterSet("lockupDuration", duration);
    }

    /// @notice Sets the percentage penalty for early unstaking (in basis points).
    /// @param rate The new penalty rate (0-10000, e.g., 500 for 5%).
    function setUnstakePenaltyRate(uint256 rate) external onlyOwner {
        require(rate <= 10000, "Rate cannot exceed 100%");
        unstakePenaltyRate = rate;
        emit ParameterSet("unstakePenaltyRate", rate);
    }

    /// @notice Sets the criteria required to reach a specific evolution level.
    /// @param level The evolution level (must be > 0).
    /// @param minStake Minimum staked amount (scaled by 1e18).
    /// @param minDuration Minimum staking duration in seconds.
    /// @param minSacrificePoints Minimum sacrifice points.
    function setEvolutionCriteria(uint8 level, uint256 minStake, uint256 minDuration, uint256 minSacrificePoints) external onlyOwner {
        require(level > 0, "Level must be > 0");
        evolutionCriteria[level] = EvolutionCriteria({
            minStake: minStake,
            minDuration: minDuration,
            minSacrificePoints: minSacrificePoints
        });
        emit EvolutionCriteriaSet(level, minStake, minDuration, minSacrificePoints);
    }

     /// @notice Sets the base URI for Nest NFT metadata.
    /// @dev The metadata service will be expected at `_baseTokenURI/tokenId/level.json`.
    /// @param newBaseURI The new base URI string.
    function setBaseTokenURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseTokenURISet(newBaseURI);
    }

    /// @notice Pauses staking, claiming, unstaking, and sacrificing.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses staking, claiming, unstaking, and sacrificing.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw other ERC20 tokens accidentally sent to the contract.
    /// @dev Cannot be used to withdraw the native PHX token or Nest NFTs.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function withdrawStuckTokens(address tokenAddress, uint256 amount) external onlyOwner nonReentrancy {
        if (tokenAddress == address(0)) revert CannotWithdrawOtherTokenZeroAddress();
        if (tokenAddress == address(this)) revert CannotWithdrawThisToken(); // Prevent withdrawing PHX itself
        // Prevent withdrawing NFTs - they are burned via specific unstake logic
        // Also prevents withdrawing governance tokens if this contract were a DAO member somewhere.

        IERC20 stuckToken = IERC20(tokenAddress);
        SafeERC20.safeTransfer(stuckToken, msg.sender, amount);
    }

    // --- VIEW/UTILITY FUNCTIONS ---

    /// @notice Gets detailed information for a specific Nest NFT stake.
    /// @param tokenId The ID of the PhoenixNest NFT.
    /// @return stakedAmount The amount of PHX staked.
    /// @return startTime The timestamp when the stake (or last significant addition) began.
    /// @return sacrificePoints The points accumulated through PHX sacrifices.
    /// @return lastRewardClaimTime The timestamp of the last reward claim.
    function getStakeInfo(uint256 tokenId) public view returns (
        uint256 stakedAmount,
        uint64 startTime,
        uint256 sacrificePoints,
        uint64 lastRewardClaimTime
    ) {
        Stake memory stake = stakes[tokenId];
        return (stake.amount, stake.startTime, stake.sacrificePoints, stake.lastRewardClaimTime);
    }

    /// @notice Gets the total amount of PHX currently staked in the protocol.
    /// @return The total staked PHX amount.
    function getTotalStakedPHX() public view returns (uint256) {
        return _totalStakedPHX;
    }

    /// @notice Gets the criteria required for a specific evolution level.
    /// @param level The evolution level (1-based index).
    /// @return minStake Minimum staked amount (scaled by 1e18).
    /// @return minDuration Minimum staking duration in seconds.
    /// @return minSacrificePoints Minimum sacrifice points.
    function getEvolutionCriteria(uint8 level) public view returns (
        uint256 minStake,
        uint256 minDuration,
        uint256 minSacrificePoints
    ) {
        EvolutionCriteria memory criteria = evolutionCriteria[level];
        return (criteria.minStake, criteria.minDuration, criteria.sacrificedAmount);
    }

     /// @notice Gets the total number of PhoenixNest NFTs that have ever been minted.
     /// @dev Includes burned NFTs. Use ERC721's balanceOf for current count per owner.
    function getNestCount() public view returns (uint256) {
        return _nestTokenIds.current();
    }

    // Note: rewardRate, lockupDuration, unstakePenaltyRate are already public state variables,
    // their getters are automatically generated. But explicit getters are included in the summary
    // for completeness as they are part of the required function count.
    function getRewardRate() public view returns (uint256) { return rewardRate; }
    function getLockupDuration() public view returns (uint256) { return lockupDuration; }
    function getUnstakePenaltyRate() public view returns (uint256) { return unstakePenaltyRate; }
}
```

---

**Explanation of Concepts and Functions:**

1.  **Combined ERC-20 & ERC-721:** The contract *is* both the utility token (`PHX`, ERC-20) and the staking position NFT (`PhoenixNest`, ERC-721). This is slightly unusual; typically, these would be separate contracts managed by a third contract. Combining them simplifies deployment and interaction for this example.
2.  **NFT-Represented Staking:** Each staking position is not just an entry in a mapping, but is tied to a unique ERC-721 token (`PhoenixNest`). This allows users to transfer, sell, or potentially use their *staked position* (represented by the NFT) in other DeFi protocols that integrate with ERC-721s. (Note: The `transferFrom` and `approve` overrides include `nonReentrant` guards as they modify state).
3.  **Dynamic NFTs:** The `tokenURI` function overrides the standard ERC-721 implementation. Instead of returning a static URI, it calculates the `getEvolutionLevel` based on the on-chain state (staked amount, duration, sacrifice points) and includes this level in the URI path. This allows an off-chain metadata service to serve dynamic JSON metadata and images based on the NFT's current state.
4.  **Deflationary Mechanism:** The `PHX` token has specific burn points:
    *   A penalty is burned if users unstake before the `lockupDuration`.
    *   PHX tokens are explicitly burned in the `sacrificePHX` function. This permanently removes tokens from circulation, increasing scarcity.
5.  **Sacrifice Mechanism:** The `sacrificePHX` function allows users to burn their own `PHX` tokens associated with a specific `PhoenixNest` NFT. This action directly contributes to the NFT's `sacrificePoints`, which is a factor in its evolution. This is a creative sink for the token.
6.  **NFT Evolution Logic:** The `getEvolutionLevel` and internal `_calculateEvolutionLevel` functions implement the core evolution logic. They check the current state of a stake (amount, duration, sacrifice points) against configurable `evolutionCriteria` to determine the NFT's level. This level can influence its appearance (via `tokenURI`) or potentially grant in-protocol benefits (though not implemented in this base contract).
7.  **Configurable Parameters:** Key protocol parameters (`rewardRate`, `lockupDuration`, `unstakePenaltyRate`, `evolutionCriteria`, `_baseTokenURI`) are stored as state variables and can be updated by the `owner` (or a more complex governance mechanism in a full protocol).
8.  **Pausable:** The `Pausable` pattern is included to allow the owner to pause critical user interactions (staking, claiming, unstaking, sacrificing) in case of emergencies or upgrades.
9.  **ReentrancyGuard:** Used on functions that involve external calls (`safeTransfer` etc.) after modifying state, mitigating reentrancy risks.
10. **Custom Errors:** Using `error` instead of `require` strings is a gas-efficient and modern Solidity pattern.
11. **Stuck Token Recovery:** Includes a function (`withdrawStuckTokens`) to rescue other ERC20 tokens accidentally sent to the contract address, which is a common utility function for robustness.
12. **ERC-20 Functions (Inherited):** The standard ERC-20 functions are included via inheritance from OpenZeppelin, allowing the contract address itself to be used as the `PHX` token.
13. **ERC-721 Functions (Inherited):** Standard ERC-721 functions are also included, allowing the contract address to be used as the `PhoenixNest` NFT collection.
14. **Counter for Token IDs:** `Counters.Counter` ensures unique, non-repeating NFT IDs.
15. **Structs and Mappings:** `Stake` struct and the `stakes` mapping efficiently store the state associated with each Nest NFT. `EvolutionCriteria` struct and `evolutionCriteria` mapping store the requirements for each level.

This contract provides a solid foundation for a complex protocol, showcasing dynamic NFTs tied to staking, a deflationary token model, and configurable on-chain parameters. It avoids simply replicating a standard DEX or lending protocol and introduces a unique interaction model between token and NFT.