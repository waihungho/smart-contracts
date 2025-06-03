Okay, let's design a sophisticated smart contract system. We'll create a "Solidity Fusion Protocol" where users can deposit certain tokens, receive a unique stateful NFT ("Fusion Capsule") representing their deposit and progress, and accrue a reward token ("FUSION") based on dynamic protocol parameters, their Capsule's state, and interactions with other NFTs ("Catalyst NFTs"). The Fusion Capsules can be evolved/upgraded, unlocking potentially higher yield rates or other benefits.

This combines concepts like:
1.  **Stateful NFTs:** Fusion Capsules (ERC-721) store data like deposit amount, deposit token, evolution level, last claim time, and accumulated yield.
2.  **Dynamic Parameters:** Protocol parameters (`fusionEfficiency`, `claimCooldown`, `evolutionCosts`) can be adjusted by the owner, influencing yield calculation and evolution requirements.
3.  **Conditional Yield Accrual:** Yield isn't uniform; it depends on the Capsule's evolution level, potentially ownership of specific Catalyst NFTs, and other factors.
4.  **NFT-Based Yield Claiming:** Yield is claimed specifically *for* a given Capsule NFT, not just the user's address in aggregate.
5.  **NFT Evolution/Burning:** Fusion Capsules can be upgraded by burning specific tokens or meeting conditions, increasing their value and yield potential. This is a form of NFT utility and progression.
6.  **Inter-NFT Dependency:** Catalyst NFTs influence the yield or evolution process of Fusion Capsules.
7.  **Role-Based Access Control:** Simple `Ownable` for critical admin functions, with potential for more granular control.
8.  **Pausability:** Essential for potential upgrades or emergency stops.
9.  **Batch Operations:** Allowing users to claim yield for multiple NFTs to save Gas.

Let's outline the contract structure and functions.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For checking owner of NFT by address

// --- Outline and Function Summary ---
// Contract: SolidityFusionProtocol
// Description: A protocol allowing users to deposit allowed ERC-20 tokens,
//              receive a stateful Fusion Capsule NFT representing their position,
//              accrue and claim FUSION reward tokens, and evolve their Capsules.
//
// Components:
// - FUSION Token (ERC-20): The reward token distributed by the protocol.
// - Fusion Capsule NFT (ERC-721): Represents a user's deposit and state within the protocol. Holds yield data, evolution level, etc.
// - Catalyst NFT (ERC-721): Optional NFTs that can influence Fusion Capsule yield or evolution.
// - Allowed Deposit Tokens (ERC-20): Tokens that can be deposited into the protocol.
//
// State Variables:
// - Token addresses (FUSION, Fusion Capsule NFT, Catalyst NFT).
// - Allowed deposit tokens mapping.
// - Global parameters (Fusion Efficiency, Claim Cooldown, Deposit Caps).
// - Per-Capsule state (deposit info, accumulated yield, evolution level, timestamps).
// - Evolution requirements per level.
// - Protocol-wide token balances (pooled deposits).
//
// Events:
// - Deposit: When a user deposits and receives a Capsule.
// - WithdrawDeposit: When a user withdraws their deposit and burns a Capsule.
// - YieldClaimed: When FUSION yield is claimed for a Capsule.
// - CapsuleEvolved: When a Fusion Capsule is upgraded.
// - CapsuleCharged: When a Fusion Capsule is charged.
// - ParameterSet: When a protocol parameter is changed.
// - AllowedDepositTokenAdded/Removed: When deposit tokens list is updated.
//
// Modifiers:
// - isValidCapsule: Ensures a given capsuleId is valid and owned by the caller.
// - onlyAllowedDepositToken: Ensures a token is on the allowed list.
//
// Functions (Total >= 20):
//
// Admin/Setup (Inherited from Ownable/Pausable + Protocol Specific):
// 1. constructor(): Initializes contract with token addresses and owner.
// 2. setFusionToken(): Sets the address of the FUSION reward token (Owner).
// 3. setFusionCapsuleNFT(): Sets the address of the Fusion Capsule NFT contract (Owner).
// 4. setCatalystNFT(): Sets the address of the Catalyst NFT contract (Owner).
// 5. addAllowedDepositToken(): Adds an ERC-20 token to the list of allowed deposit tokens (Owner).
// 6. removeAllowedDepositToken(): Removes an ERC-20 token from the allowed list (Owner).
// 7. setFusionEfficiency(): Sets the global yield efficiency parameter (Owner).
// 8. setClaimCooldown(): Sets the minimum time between yield claims for a Capsule (Owner).
// 9. setEvolutionRequirements(): Sets the costs/requirements for a specific evolution level (Owner).
// 10. setDepositCap(): Sets the maximum deposit amount for a specific token (Owner).
// 11. pause(): Pauses protocol operations (Owner).
// 12. unpause(): Unpauses protocol operations (Owner).
// 13. emergencyWithdraw(): Allows owner to withdraw specific tokens in emergencies (Owner).
// 14. transferOwnership(): Transfers ownership (Ownable).
// 15. renounceOwnership(): Renounces ownership (Ownable).
//
// User Interactions:
// 16. deposit(): Deposits an allowed ERC-20 token, receives a new Fusion Capsule NFT.
// 17. withdrawDeposit(): Burns a Fusion Capsule NFT and withdraws the original deposited amount (requires no pending yield).
// 18. claimFusionYield(): Claims accrued FUSION yield for a specific Fusion Capsule NFT.
// 19. claimFusionYieldBatch(): Claims accrued FUSION yield for multiple Fusion Capsule NFTs.
// 20. evolveCapsule(): Upgrades a Fusion Capsule NFT to the next level by burning required tokens/meeting conditions.
// 21. chargeCapsule(): Performs a 'charge' action on a Capsule, potentially affecting cooldowns or yield accrual (example implementation: resets claim cooldown).
//
// View/Read Functions:
// 22. estimateFusionYield(): Estimates the currently claimable yield for a specific Capsule.
// 23. getDepositInfo(): Gets the original deposit details for a Capsule.
// 24. getCapsuleState(): Gets the current state (evolution level, timestamps) of a Capsule.
// 25. getAllowedDepositTokens(): Gets the list of allowed deposit tokens.
// 26. getFusionEfficiency(): Gets the current global fusion efficiency.
// 27. getClaimCooldown(): Gets the current claim cooldown period.
// 28. getEvolutionRequirements(): Gets the requirements for a specific evolution level.
// 29. getDepositCap(): Gets the deposit cap for a specific token.
// 30. getUserCapsules(): Returns a list of Capsule IDs owned by an address (requires helper mapping).
// 31. getCapsuleLastCharged(): Gets the timestamp of the last charge action for a Capsule.
// 32. getProtocolTokenBalance(): Gets the balance of an allowed deposit token held by the protocol.
//
// Internal/Helper Functions:
// - _calculateYieldAmount(): Calculates the yield accrued for a capsule based on time, state, and parameters.
// - _updateCapsuleYieldAccumulation(): Helper to update accumulated yield before calculation/claim.
// - _checkEvolutionRequirements(): Helper to check if requirements for a level are met.

// --- Smart Contract Code ---

contract SolidityFusionProtocol is Ownable, Pausable {

    // --- State Variables ---

    address public fusionToken;
    address public fusionCapsuleNFT;
    address public catalystNFT; // Address of the Catalyst NFT contract

    // Mapping of allowed deposit tokens => isAllowed
    mapping(address => bool) public allowedDepositTokens;
    // Mapping of allowed deposit tokens => deposit cap
    mapping(address => uint256) public depositCaps;
    // Array to easily list allowed tokens (managed manually on add/remove)
    address[] public allowedDepositTokenList;

    // Global parameters
    uint256 public fusionEfficiency = 1e16; // Base yield rate per unit of time/value (example: 1e18 = 1 FUSION per token-second base)
    uint256 public claimCooldown = 1 days; // Minimum time between yield claims for a single capsule

    // Structure to hold deposit details for a capsule
    struct DepositInfo {
        address token;
        uint256 amount;
        uint64 depositTimestamp; // Use uint64 for efficiency if fits (seconds since epoch)
    }
    mapping(uint256 => DepositInfo) public capsuleDepositInfo; // capsuleId => DepositInfo

    // Structure to hold state details for a capsule
    struct CapsuleState {
        uint8 evolutionLevel; // Starting at 0
        uint64 lastClaimTimestamp; // Last time yield was claimed
        uint64 lastChargedTimestamp; // Last time capsule was charged
    }
    mapping(uint256 => CapsuleState) public capsuleState; // capsuleId => CapsuleState

    // Accumulated yield not yet claimed for a capsule
    mapping(uint256 => uint256) public capsuleYieldAccumulated; // capsuleId => accumulated FUSION yield

    // Structure for evolution requirements
    struct EvolutionRequirements {
        uint256 requiredFusionToken; // FUSION tokens to burn
        uint256 requiredDepositTokenAmount; // Original deposit amount must be >= this
        // Add more requirements here, e.g., specific Catalyst NFT ownership
        uint256 requiredCatalystNFTId; // Set to 0 if no specific NFT required, otherwise requires ownership of this ID
    }
    // mapping(uint8 evolutionLevel => EvolutionRequirements) - Evolution from level-1 to level
    mapping(uint8 => EvolutionRequirements) public evolutionRequirements;

    // Helper mapping to get capsule IDs for a user (ERC721 doesn't provide this easily)
    mapping(address => uint256[]) private userCapsules;
    mapping(uint256 => uint256) private userCapsuleIndex; // capsuleId => index in userCapsules array

    // Protocol's pooled token balances
    mapping(address => uint256) public protocolTokenBalances;

    // Yield calculation constants
    uint256 private constant YIELD_MULTIPLIER_DECIMALS = 18; // For base yield calculation
    uint256 private constant TIME_UNIT = 1; // 1 second

    // Evolution bonuses (example: simple multiplier based on level)
    mapping(uint8 => uint256) public evolutionYieldBonus; // evolutionLevel => bonus multiplier (e.g., 1e18 = 1x, 2e18 = 2x)

    // --- Events ---

    event Deposit(address indexed user, uint256 indexed capsuleId, address indexed token, uint256 amount, uint64 timestamp);
    event WithdrawDeposit(address indexed user, uint256 indexed capsuleId, address indexed token, uint256 amount, uint64 timestamp);
    event YieldClaimed(address indexed user, uint256 indexed capsuleId, uint256 amount, uint64 timestamp);
    event CapsuleEvolved(address indexed user, uint256 indexed capsuleId, uint8 oldLevel, uint8 newLevel, uint64 timestamp);
    event CapsuleCharged(address indexed user, uint256 indexed capsuleId, uint64 timestamp);
    event ParameterSet(string paramName, uint256 oldValue, uint256 newValue);
    event TokenAddressSet(string tokenName, address indexed oldAddress, address indexed newAddress);
    event AllowedDepositTokenAdded(address indexed token);
    event AllowedDepositTokenRemoved(address indexed token);
    event DepositCapSet(address indexed token, uint256 cap);
    event EvolutionRequirementsSet(uint8 indexed level, EvolutionRequirements reqs);
    event EvolutionYieldBonusSet(uint8 indexed level, uint256 bonus);

    // --- Modifiers ---

    modifier isValidCapsule(uint256 _capsuleId) {
        require(IERC721(fusionCapsuleNFT).ownerOf(_capsuleId) == msg.sender, "Not the capsule owner");
        // Optional: check if capsuleId exists in internal mapping if needed, but ownerOf check implies existence.
        _;
    }

    modifier onlyAllowedDepositToken(address _token) {
        require(allowedDepositTokens[_token], "Token not allowed for deposit");
        _;
    }

    // --- Constructor ---

    constructor(address _fusionToken, address _fusionCapsuleNFT, address _catalystNFT) Ownable(msg.sender) Pausable(false) {
        fusionToken = _fusionToken;
        fusionCapsuleNFT = _fusionCapsuleNFT;
        catalystNFT = _catalystNFT;

        // Set initial evolution bonuses (example)
        evolutionYieldBonus[0] = 1e18; // Base level (1x)
        evolutionYieldBonus[1] = 1.2e18; // Level 1 (1.2x)
        evolutionYieldBonus[2] = 1.5e18; // Level 2 (1.5x)
        evolutionYieldBonus[3] = 2e18; // Level 3 (2x)
        // Add more levels as needed...
    }

    // --- Admin Functions (Owner Only) ---

    function setFusionToken(address _fusionToken) external onlyOwner {
        emit TokenAddressSet("fusionToken", fusionToken, _fusionToken);
        fusionToken = _fusionToken;
    }

    function setFusionCapsuleNFT(address _fusionCapsuleNFT) external onlyOwner {
        emit TokenAddressSet("fusionCapsuleNFT", fusionCapsuleNFT, _fusionCapsuleNFT);
        fusionCapsuleNFT = _fusionCapsuleNFT;
    }

    function setCatalystNFT(address _catalystNFT) external onlyOwner {
        emit TokenAddressSet("catalystNFT", catalystNFT, _catalystNFT);
        catalystNFT = _catalystNFT;
    }

    function addAllowedDepositToken(address _token, uint256 _cap) external onlyOwner {
        require(_token != address(0), "Invalid address");
        if (!allowedDepositTokens[_token]) {
            allowedDepositTokens[_token] = true;
            allowedDepositTokenList.push(_token);
            emit AllowedDepositTokenAdded(_token);
        }
        depositCaps[_token] = _cap;
        emit DepositCapSet(_token, _cap);
    }

    function removeAllowedDepositToken(address _token) external onlyOwner {
        require(allowedDepositTokens[_token], "Token not in allowed list");
        allowedDepositTokens[_token] = false;
        depositCaps[_token] = 0; // Reset cap

        // Remove from dynamic array (inefficient, but required if order doesn't matter)
        for (uint i = 0; i < allowedDepositTokenList.length; i++) {
            if (allowedDepositTokenList[i] == _token) {
                allowedDepositTokenList[i] = allowedDepositTokenList[allowedDepositTokenList.length - 1];
                allowedDepositTokenList.pop();
                break;
            }
        }
        emit AllowedDepositTokenRemoved(_token);
    }

    function setFusionEfficiency(uint256 _fusionEfficiency) external onlyOwner {
        emit ParameterSet("fusionEfficiency", fusionEfficiency, _fusionEfficiency);
        fusionEfficiency = _fusionEfficiency;
    }

    function setClaimCooldown(uint256 _claimCooldown) external onlyOwner {
         emit ParameterSet("claimCooldown", claimCooldown, _claimCooldown);
        claimCooldown = _claimCooldown;
    }

     function setDepositCap(address _token, uint256 _cap) external onlyOwner onlyAllowedDepositToken(_token) {
        uint256 oldCap = depositCaps[_token];
        depositCaps[_token] = _cap;
        emit DepositCapSet(_token, _cap);
    }

    function setEvolutionRequirements(uint8 _level, EvolutionRequirements calldata _reqs) external onlyOwner {
        evolutionRequirements[_level] = _reqs;
        emit EvolutionRequirementsSet(_level, _reqs);
    }

    function setEvolutionYieldBonus(uint8 _level, uint256 _bonus) external onlyOwner {
        require(_bonus >= 1e18, "Bonus must be >= 1x (1e18)");
        uint256 oldBonus = evolutionYieldBonus[_level];
        evolutionYieldBonus[_level] = _bonus;
        emit EvolutionYieldBonusSet(_level, _bonus);
    }

    // emergencyWithdraw: allows owner to withdraw specific tokens from the contract
    // Use with caution - meant for stuck tokens or protocol treasury management in emergency
    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner {
        // Ensure it's not the FUSION token or Capsule NFT token itself unless specific case
        // Or restrict which tokens can be withdrawn this way
        // Example: Only withdraw allowed deposit tokens or other arbitrary tokens
        // require(allowedDepositTokens[_token], "Can only withdraw allowed deposit tokens this way"); // Or different logic
        IERC20(_token).transfer(owner(), _amount);
    }

    // Pausable inherited functions: pause(), unpause()

    // Ownable inherited functions: transferOwnership(), renounceOwnership()

    // --- User Interaction Functions ---

    // Deposit an allowed token and mint a new Fusion Capsule NFT
    function deposit(address _token, uint256 _amount) external payable whenNotPaused onlyAllowedDepositToken(_token) {
        require(_amount > 0, "Amount must be greater than 0");
        require(depositCaps[_token] == 0 || protocolTokenBalances[_token] + _amount <= depositCaps[_token], "Deposit exceeds cap");

        // Transfer tokens to the protocol
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Update protocol balance tracker
        protocolTokenBalances[_token] += _amount;

        // Mint a new Fusion Capsule NFT for the user
        uint256 newItemId = IERC721(fusionCapsuleNFT).totalSupply(); // Assuming NFT contract uses incrementing IDs
        // Note: A production system might need a more robust way to get a unique, non-sequential ID
        // Or the NFT contract might handle ID generation internally on mint.
        // For this example, we'll assume a simple minting function taking recipient and ID.
        // Requires FusionCapsuleNFT contract to have a mint function callable by this contract.
        // Example requires ERC721 standard interface + a custom mint function or minter role setup.
        // Assuming a function like `mint(address recipient, uint256 tokenId)` exists or using ERC721 standard minting (more complex setup needed).
        // Let's assume the NFT contract has a `mintTo(address recipient)` function that returns the new token ID.
        uint256 capsuleId = IERC721(fusionCapsuleNFT).mintTo(msg.sender);

        // Store deposit and capsule state information
        capsuleDepositInfo[capsuleId] = DepositInfo({
            token: _token,
            amount: _amount,
            depositTimestamp: uint64(block.timestamp)
        });

        capsuleState[capsuleId] = CapsuleState({
            evolutionLevel: 0,
            lastClaimTimestamp: uint64(block.timestamp), // Initialize claim timestamp
            lastChargedTimestamp: uint64(block.timestamp) // Initialize charged timestamp
        });

        capsuleYieldAccumulated[capsuleId] = 0; // Start with 0 accumulated yield

        // Add capsule to user's list
        userCapsules[msg.sender].push(capsuleId);
        userCapsuleIndex[capsuleId] = userCapsules[msg.sender].length - 1; // Store index

        emit Deposit(msg.sender, capsuleId, _token, _amount, uint64(block.timestamp));
    }

    // Withdraw the original deposit amount by burning the Capsule NFT
    function withdrawDeposit(uint256 _capsuleId) external whenNotPaused isValidCapsule(_capsuleId) {
        // Ensure no pending yield before withdrawal
        require(capsuleYieldAccumulated[_capsuleId] == 0, "Claim yield before withdrawing deposit");
        // Also estimate any yield accrued *since* last accumulation/claim check
        // Need to update accumulated yield before checking...
        _updateCapsuleYieldAccumulation(_capsuleId);
        require(capsuleYieldAccumulated[_capsuleId] == 0, "Yield accrued since last check. Claim yield before withdrawing.");

        DepositInfo memory deposit = capsuleDepositInfo[_capsuleId];
        address depositToken = deposit.token;
        uint256 depositAmount = deposit.amount;

        // Burn the Fusion Capsule NFT
        // Requires FusionCapsuleNFT contract to have a burn function callable by this contract or owner
        // Example assumes `burn(uint256 tokenId)`
        IERC721(fusionCapsuleNFT).burn(_capsuleId);

        // Transfer deposited tokens back to the user
        IERC20(depositToken).transfer(msg.sender, depositAmount);

        // Update protocol balance tracker
        protocolTokenBalances[depositToken] -= depositAmount;

        // Clean up state
        delete capsuleDepositInfo[_capsuleId];
        delete capsuleState[_capsuleId];
        // capsuleYieldAccumulated should already be 0 at this point

        // Remove capsule from user's list (inefficient array removal)
        uint256 lastIndex = userCapsules[msg.sender].length - 1;
        uint256 capsuleIndex = userCapsuleIndex[_capsuleId];
        uint256 lastCapsuleId = userCapsules[msg.sender][lastIndex];

        userCapsules[msg.sender][capsuleIndex] = lastCapsuleId; // Move last element to current position
        userCapsuleIndex[lastCapsuleId] = capsuleIndex; // Update index of moved element
        userCapsules[msg.sender].pop(); // Remove last element
        delete userCapsuleIndex[_capsuleId]; // Clean up index mapping for burned capsule

        emit WithdrawDeposit(msg.sender, _capsuleId, depositToken, depositAmount, uint64(block.timestamp));
    }

    // Claim accumulated FUSION yield for a single Fusion Capsule NFT
    function claimFusionYield(uint256 _capsuleId) external whenNotPaused isValidCapsule(_capsuleId) {
        // Check cooldown
        require(block.timestamp >= capsuleState[_capsuleId].lastClaimTimestamp + claimCooldown, "Claim cooldown active");

        // Calculate and update accumulated yield first
        _updateCapsuleYieldAccumulation(_capsuleId);

        uint256 yieldAmount = capsuleYieldAccumulated[_capsuleId];
        require(yieldAmount > 0, "No yield to claim");

        // Reset accumulated yield for this capsule
        capsuleYieldAccumulated[_capsuleId] = 0;
        capsuleState[_capsuleId].lastClaimTimestamp = uint64(block.timestamp); // Update last claim time

        // Transfer FUSION tokens to the user
        IERC20(fusionToken).transfer(msg.sender, yieldAmount);

        emit YieldClaimed(msg.sender, _capsuleId, yieldAmount, uint64(block.timestamp));
    }

    // Claim accumulated FUSION yield for multiple Fusion Capsule NFTs
    function claimFusionYieldBatch(uint256[] calldata _capsuleIds) external whenNotPaused {
        uint256 totalClaimed = 0;
        uint64 currentTimestamp = uint64(block.timestamp);

        for (uint i = 0; i < _capsuleIds.length; i++) {
            uint256 capsuleId = _capsuleIds[i];
            // Check ownership and cooldown for each capsule
            require(IERC721(fusionCapsuleNFT).ownerOf(capsuleId) == msg.sender, "Batch contains non-owned capsule");
            require(currentTimestamp >= capsuleState[capsuleId].lastClaimTimestamp + claimCooldown, "Batch contains capsule with active cooldown");

            // Calculate and update accumulated yield
            _updateCapsuleYieldAccumulation(capsuleId);

            uint256 yieldAmount = capsuleYieldAccumulated[capsuleId];

            if (yieldAmount > 0) {
                totalClaimed += yieldAmount;
                // Reset accumulated yield and update last claim time
                capsuleYieldAccumulated[capsuleId] = 0;
                capsuleState[capsuleId].lastClaimTimestamp = currentTimestamp;

                emit YieldClaimed(msg.sender, capsuleId, yieldAmount, currentTimestamp);
            }
        }

        require(totalClaimed > 0, "No yield to claim from batch");

        // Transfer total FUSION tokens to the user
        IERC20(fusionToken).transfer(msg.sender, totalClaimed);
    }


    // Evolve a Fusion Capsule to the next level
    function evolveCapsule(uint256 _capsuleId) external whenNotPaused isValidCapsule(_capsuleId) {
        uint8 currentLevel = capsuleState[_capsuleId].evolutionLevel;
        uint8 nextLevel = currentLevel + 1;
        EvolutionRequirements memory reqs = evolutionRequirements[nextLevel];

        // Check if requirements for the next level are set
        require(reqs.requiredFusionToken > 0 || reqs.requiredDepositTokenAmount > 0 || reqs.requiredCatalystNFTId > 0, "No evolution requirements set for next level");

        // Check requirements
        require(capsuleDepositInfo[_capsuleId].amount >= reqs.requiredDepositTokenAmount, "Original deposit amount too low");

        // Check and burn required FUSION tokens
        if (reqs.requiredFusionToken > 0) {
            require(IERC20(fusionToken).balanceOf(msg.sender) >= reqs.requiredFusionToken, "Insufficient FUSION tokens");
            IERC20(fusionToken).transferFrom(msg.sender, address(this), reqs.requiredFusionToken);
            // Note: FUSION tokens transferred here could be burned or sent to a treasury/governance module
            // For simplicity, they are held by the protocol contract. A burn mechanism is more typical.
            // To burn: require(IERC20(fusionToken).transferFrom(msg.sender, address(0), reqs.requiredFusionToken));
        }

        // Check Catalyst NFT ownership (does *not* burn the Catalyst NFT, just requires ownership)
        if (reqs.requiredCatalystNFTId > 0) {
             require(IERC721(catalystNFT).ownerOf(reqs.requiredCatalystNFTId) == msg.sender, "Required Catalyst NFT not owned");
        }

        // Perform the evolution
        capsuleState[_capsuleId].evolutionLevel = nextLevel;
        // Optional: Reset claim/charge timestamps on evolution? Depends on desired game mechanics.
        // For now, they are not reset.

        emit CapsuleEvolved(msg.sender, _capsuleId, currentLevel, nextLevel, uint64(block.timestamp));
    }

    // Perform a 'charge' action on a Capsule (resets claim cooldown for this example)
    // Could be extended to cost a token, add temporary yield boost, etc.
    function chargeCapsule(uint256 _capsuleId) external whenNotPaused isValidCapsule(_capsuleId) {
        // Example simple charge: Resets the claim cooldown without cost
        // In a real system, this would likely cost something (tokens, NFT burn, etc.)
        // Example with a cost (requires a specific token, e.g., the deposited token itself, or a separate 'Charge' token)
        // uint256 chargeCost = 1e16; // Example cost (0.01 units)
        // address chargeToken = capsuleDepositInfo[_capsuleId].token; // Use deposit token as charge token
        // require(IERC20(chargeToken).transferFrom(msg.sender, address(this), chargeCost), "Failed to pay charge cost");
        // protocolTokenBalances[chargeToken] += chargeCost; // Update protocol balance

        // For this example, we just reset the cooldown without cost.
        capsuleState[_capsuleId].lastChargedTimestamp = uint64(block.timestamp);
        // Resetting claim timestamp allows immediate claim after charge, overriding cooldown
        capsuleState[_capsuleId].lastClaimTimestamp = uint64(block.timestamp);


        emit CapsuleCharged(msg.sender, _capsuleId, uint64(block.timestamp));
    }


    // --- View/Read Functions ---

    // Estimate the currently claimable yield for a specific Capsule
    function estimateFusionYield(uint256 _capsuleId) public view returns (uint256) {
        require(capsuleDepositInfo[_capsuleId].token != address(0), "Invalid capsule ID"); // Check if capsule exists
        // Owner check is omitted for view function, anyone can estimate.
        // But the data must be valid.

        // Calculate yield accrued since last update/claim/charge
        uint64 lastYieldUpdateTime = capsuleState[_capsuleId].lastClaimTimestamp; // Or lastChargedTimestamp if that triggers yield accrual
        // Let's use the latest of lastClaimTimestamp and lastChargedTimestamp as the starting point for new accrual
        uint64 accrualStartTime = capsuleState[_capsuleId].lastClaimTimestamp > capsuleState[_capsuleId].lastChargedTimestamp
            ? capsuleState[_capsuleId].lastClaimTimestamp
            : capsuleState[_capsuleId].lastChargedTimestamp;

        if (block.timestamp <= accrualStartTime) {
            return capsuleYieldAccumulated[_capsuleId]; // No new time has passed
        }

        uint256 timeElapsed = block.timestamp - accrualStartTime;
        return capsuleYieldAccumulated[_capsuleId] + _calculateYieldAmount(_capsuleId, timeElapsed);
    }

     // Get the original deposit details for a Capsule
    function getDepositInfo(uint256 _capsuleId) public view returns (DepositInfo memory) {
        require(capsuleDepositInfo[_capsuleId].token != address(0), "Invalid capsule ID");
        return capsuleDepositInfo[_capsuleId];
    }

    // Get the current state (evolution level, timestamps) of a Capsule
    function getCapsuleState(uint256 _capsuleId) public view returns (CapsuleState memory) {
         require(capsuleDepositInfo[_capsuleId].token != address(0), "Invalid capsule ID");
        return capsuleState[_capsuleId];
    }

    // Get the list of allowed deposit tokens
    function getAllowedDepositTokens() external view returns (address[] memory) {
        return allowedDepositTokenList;
    }

    // Get the current global fusion efficiency
    function getFusionEfficiency() external view returns (uint256) {
        return fusionEfficiency;
    }

    // Get the current claim cooldown period
    function getClaimCooldown() external view returns (uint256) {
        return claimCooldown;
    }

    // Gets the requirements for a specific evolution level
    function getEvolutionRequirements(uint8 _level) external view returns (EvolutionRequirements memory) {
        return evolutionRequirements[_level];
    }

    // Gets the deposit cap for a specific token
    function getDepositCap(address _token) external view returns (uint256) {
        return depositCaps[_token];
    }

    // Returns a list of Capsule IDs owned by an address
    function getUserCapsules(address _user) external view returns (uint256[] memory) {
        return userCapsules[_user];
    }

     // Gets the timestamp of the last charge action for a Capsule
    function getCapsuleLastCharged(uint256 _capsuleId) external view returns (uint64) {
        require(capsuleDepositInfo[_capsuleId].token != address(0), "Invalid capsule ID");
        return capsuleState[_capsuleId].lastChargedTimestamp;
    }

     // Gets the balance of an allowed deposit token held by the protocol
    function getProtocolTokenBalance(address _token) external view returns (uint256) {
        require(allowedDepositTokens[_token], "Token not allowed for deposit");
        return protocolTokenBalances[_token];
    }


    // --- Internal Helper Functions ---

    // Calculates the yield accrued for a capsule based on time elapsed
    // This is the core "Fusion Process" calculation
    function _calculateYieldAmount(uint256 _capsuleId, uint256 _timeElapsed) internal view returns (uint256) {
        DepositInfo memory deposit = capsuleDepositInfo[_capsuleId];
        CapsuleState memory state = capsuleState[_capsuleId];

        // Base yield calculation: time * efficiency * deposit amount
        // Need to handle fixed point arithmetic carefully.
        // (time * efficiency * amount) / (TIME_UNIT * 1e18)
        // Assume efficiency is scaled by 1e18
        uint256 baseYield = (_timeElapsed * fusionEfficiency * deposit.amount) / (TIME_UNIT * 1e18);

        // Apply evolution bonus
        uint256 bonusMultiplier = evolutionYieldBonus[state.evolutionLevel];
        // Ensure bonusMultiplier exists, default to 1x (1e18) if not set
        if (bonusMultiplier == 0) {
             bonusMultiplier = 1e18;
        }
        uint256 yieldAfterEvolution = (baseYield * bonusMultiplier) / 1e18;

        // Apply Catalyst NFT bonus (Example: 10% bonus if owner owns ANY Catalyst NFT)
        uint256 catalystBonus = 1e18; // Default 1x multiplier
        address ownerAddress = IERC721(fusionCapsuleNFT).ownerOf(_capsuleId); // Get current owner of the Capsule
        // A more complex check could verify ownership of a specific Catalyst NFT ID
        // For simplicity, let's just check if the owner has *any* balance of Catalyst NFTs.
        // This requires the Catalyst NFT contract to implement ERC721Enumerable or a custom balance check.
        // Assuming IERC721Metadata supports `balanceOf` (which it does via inheritance from IERC165/IERC721)
        if (IERC721Metadata(catalystNFT).balanceOf(ownerAddress) > 0) {
            // Example: Add a fixed percentage bonus (e.g., 10%)
            catalystBonus = 1.1e18; // 1.1x multiplier
        }
        uint256 totalYield = (yieldAfterEvolution * catalystBonus) / 1e18;

        return totalYield;
    }

    // Helper to calculate and add newly accrued yield to the accumulated amount
    // Called before claiming or checking accumulated yield for withdrawal
    function _updateCapsuleYieldAccumulation(uint256 _capsuleId) internal {
        // Calculate yield accrued since last update/claim/charge
        // Use the latest of lastClaimTimestamp and lastChargedTimestamp as the starting point for new accrual
        uint64 accrualStartTime = capsuleState[_capsuleId].lastClaimTimestamp > capsuleState[_capsuleId].lastChargedTimestamp
            ? capsuleState[_capsuleId].lastClaimTimestamp
            : capsuleState[_capsuleId].lastChargedTimestamp;

        if (block.timestamp <= accrualStartTime) {
            return; // No new time has passed, nothing to update
        }

        uint256 timeElapsed = block.timestamp - accrualStartTime;
        uint256 newlyAccrued = _calculateYieldAmount(_capsuleId, timeElapsed);

        capsuleYieldAccumulated[_capsuleId] += newlyAccrued;

        // Update the timestamp used for the *next* calculation
        // This prevents double counting time
        // Set the starting point for the next accrual period
        capsuleState[_capsuleId].lastClaimTimestamp = uint64(block.timestamp);
         // Note: lastChargedTimestamp is only updated by chargeCapsule, doesn't represent yield calculation checkpoint here
         // Reverting to simpler logic: Always use lastClaimTimestamp as accrual start point.
         // Let's stick to lastClaimTimestamp being the sole accrual checkpoint. Charge just affects cooldown.
         // Correcting accrualStartTime logic:
         // uint64 accrualStartTime = capsuleState[_capsuleId].lastClaimTimestamp;
         // If (block.timestamp > accrualStartTime)... rest of logic is same.
         // Ok, let's stick to lastClaimTimestamp as the sole point. This makes `chargeCapsule`'s effect (resetting lastClaimTimestamp) clearer.
         // The code as written above correctly uses the *updated* lastClaimTimestamp for the *next* calculation.

    }

    // Helper function to check evolution requirements (less critical as done inline)
    // function _checkEvolutionRequirements(...) internal view returns (bool) { ... }

}

// --- Placeholder Interfaces and Mock Contracts ---
// These would be separate deployed contracts in a real system

interface IFusionCapsuleNFT is IERC721Metadata {
    // Add custom functions needed by FusionProtocol, e.g. minting/burning functions callable by protocol
    // Example:
    function mintTo(address recipient) external returns (uint256 newItemId);
    function burn(uint256 tokenId) external;
}

interface ICatalystNFT is IERC721Metadata {
    // Add custom functions if needed, otherwise standard IERC721Metadata is enough
    // (Especially if checking specific token ID ownership)
}

// Example Mock ERC20 for deposit tokens
// contract MockDAI is IERC20 { ... standard ERC20 implementation ... }
// contract MockUSDC is IERC20 { ... }

// Example Fusion Reward Token
// contract FusionToken is ERC20 { ... standard ERC20 implementation, maybe with minting/burning logic ... }
// The FusionProtocol contract needs allowance/minter role to transfer/mint FusionToken
// In this example, we assume FusionToken is pre-minted and transferred to FusionProtocol,
// or FusionProtocol has a MINTER role on FusionToken.
// For this contract to work, the FusionToken contract must allow transfers *from* the FusionProtocol address.
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Stateful NFTs (Fusion Capsules):** Unlike typical profile picture NFTs or simple collectibles, these NFTs hold dynamic state (`evolutionLevel`, `lastClaimTimestamp`, `lastChargedTimestamp`, linked `DepositInfo`, `capsuleYieldAccumulated`). This state directly influences their utility (yield potential) and interaction possibilities (evolution, charging).
2.  **NFT as a Position/Yield Instrument:** The Fusion Capsule NFT is not just ownership; it *is* the user's position in the yield-generating protocol. Yield accrual and claiming are tied to the specific NFT instance.
3.  **Dynamic Parameterization & Protocol Evolution:** The protocol isn't static. `fusionEfficiency`, `claimCooldown`, `depositCaps`, and `evolutionRequirements`/`evolutionYieldBonus` can be adjusted by the owner. This allows the protocol to adapt to market conditions, incentivize/disincentivize certain behaviors, and manage the tokenomics of `FUSION`.
4.  **Conditional & Layered Yield Calculation:** The `_calculateYieldAmount` function demonstrates how yield isn't a simple linear function of deposit amount/time. It incorporates multiple factors: base efficiency, evolution level multiplier, and a bonus based on ownership of a *different* type of NFT (Catalyst). This creates complex interdependencies within the ecosystem.
5.  **NFT Evolution Mechanics:** The `evolveCapsule` function introduces a progression system. Users invest (burn tokens, possibly hold other NFTs) to permanently upgrade their Fusion Capsule, increasing its yield potential. This adds a gamified element and a sink for the `FUSION` token or other required assets.
6.  **Inter-Protocol/Inter-NFT Interaction (Conceptual):** While all within one system here, the design simulates interaction between different token types (ERC-20 deposits, ERC-721 Capsule NFTs, ERC-721 Catalyst NFTs, ERC-20 FUSION token). A Capsule's performance depends on owning a Catalyst NFT *outside* of the Capsule itself.
7.  **Per-NFT Yield Claiming & Batching:** The `claimFusionYield` and `claimFusionYieldBatch` functions highlight that yield is tracked and claimed per individual NFT, offering more granular control than a single pool-based claim. Batching addresses a common Gas cost issue in per-item operations.
8.  **Charge Mechanic:** The `chargeCapsule` function, even in its simple form here, demonstrates a non-standard user action tied to a specific NFT instance that can influence the protocol mechanics (resetting cooldown). This opens the door for more complex interactions like temporary boosts, energy systems, etc.
9.  **Managed Allowed Tokens & Caps:** The protocol controls which tokens can be deposited and enforces caps, which is crucial for managing risk and liquidity in a real DeFi protocol.
10. **Manual User Capsule Tracking:** The `userCapsules` mapping is added because standard ERC-721 does not easily provide a list of tokens owned by an address without enumerability extensions, which can be Gas-intensive for large numbers of tokens. This manual tracking is a common pattern in complex NFT-interacting contracts.

This contract structure provides a foundation for a novel DeFi/NFT interaction protocol that goes beyond standard staking or farming models, incorporating state, progression, and inter-token dependencies.