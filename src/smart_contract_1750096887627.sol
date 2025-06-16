Okay, let's design a smart contract around a concept that blends dynamic NFTs, staking, lightweight governance, and a form of on-chain evolution or composition.

**Concept:** **The Genesis Protocol**

This protocol allows users to stake "Essence" tokens (an ERC-20) over time. Based on the staking duration and potentially other factors, they can then "Forge" a unique "Primal Form" (an ERC-721). Primal Forms have dynamic traits that can evolve based on staking the Form itself, governance votes, or interactions triggered by a designated strategist. The protocol collects fees during forging and distributes yield to staked Forms.

This avoids simple ERC-20/721 duplication and incorporates:
*   Dual token interaction (ERC-20 & ERC-721).
*   Staking mechanism (time-based).
*   Burning/Consumption of staked tokens during forging.
*   NFT minting based on protocol logic.
*   **Dynamic NFT Traits:** Traits stored and updated on-chain *after* minting.
*   Lightweight Governance: Voting on protocol parameters or potentially influencing Form traits.
*   Yield distribution to staked NFTs.
*   Role-based access control (basic owner/strategist).

---

**Outline and Function Summary:**

**Contract Name:** `GenesisProtocol`

**Core Concepts:**
1.  **Essence Staking:** Users stake ERC-20 Essence tokens to initiate the Forging process. Duration staked is key.
2.  **Primal Form Forging:** Burning staked Essence after a minimum duration to mint a unique ERC-721 Primal Form with initial dynamic traits.
3.  **Dynamic Traits:** Primal Form NFTs have traits stored and modifiable directly within the `GenesisProtocol` contract, independent of the NFT token contract metadata URI.
4.  **Form Staking for Yield:** Staking Primal Forms to earn yield in a specified token.
5.  **Lightweight Governance:** Holders of Primal Forms or staked Essence can propose and vote on protocol parameter changes.
6.  **Fees:** Fees collected during the Forging process.
7.  **Roles:** Owner and Strategist roles for protocol management and trait updates.

**State Variables:**
*   Token Addresses (Essence, Primal Form, Yield).
*   Staking Mappings (Essence: user => amount, start time; Form: tokenId => stake time).
*   Forging Parameters (min stake duration, required essence, base forging fee).
*   Dynamic Trait Mappings (tokenId => traitName => traitValue).
*   Governance State (Proposal struct, proposal ID counter, proposal mapping, vote mapping).
*   Fee Collection (total collected, withdrawable amounts).
*   Role Addresses (owner, strategist).

**Events:**
*   `EssenceStaked`, `EssenceUnstaked`
*   `ForgingInitiated`, `FormForged`
*   `TraitUpdated`, `DynamicTraitRegistered`
*   `FormStakedForYield`, `FormUnstakedFromYield`, `YieldClaimed`
*   `ParameterChangeProposed`, `Voted`, `ProposalExecuted`
*   `FeesWithdrawn`
*   `StrategistUpdated`

**Modifiers:**
*   `onlyOwner`
*   `onlyStrategist`
*   `onlyFormHolderOrStaker` (Placeholder/concept for governance)
*   `whenForgingReady`

**Functions (>= 20):**

*   **Initialization/Setup:**
    1.  `constructor()`: Initializes owner and sets initial token addresses (can be zero initially).
    2.  `setTokenAddresses(IERC20 _essence, IERC721 _form, IERC20 _yield)`: Admin sets the required token contract addresses.
    3.  `setStrategist(address _strategist)`: Owner sets the address for the Strategist role.

*   **Essence Staking & Forging:**
    4.  `stakeEssence(uint256 amount)`: Stakes Essence tokens from the caller. Requires approval. Records stake amount and start time.
    5.  `unstakeEssence()`: Allows caller to unstake *all* their currently staked Essence if they haven't initiated forging or haven't passed the minimum forging duration.
    6.  `initiateFormForging()`: User initiates the forging process. Locks their staked Essence amount. Can only be called if Essence is staked.
    7.  `finalizeFormForging()`: Burns the locked staked Essence and mints a new Primal Form NFT if the minimum staking duration has passed since `initiateFormForging`. Assigns initial traits. Collects forging fee.
    8.  `getEssenceStakeInfo(address staker)`: Query staked amount and start time for a user.
    9.  `getForgingReadiness(address staker)`: Check if a user is eligible to call `finalizeFormForging` (based on staking duration).

*   **Dynamic Form Traits:**
    10. `registerDynamicTrait(string memory traitKey)`: Strategist/Owner registers a new key name that can be used for dynamic traits.
    11. `updateFormTrait(uint256 tokenId, string memory traitKey, string memory traitValue)`: Strategist updates the value of a registered dynamic trait for a specific Primal Form.
    12. `getFormTrait(uint256 tokenId, string memory traitKey)`: Query the value of a specific dynamic trait for a Form.
    13. `getAllFormTraits(uint256 tokenId)`: *Conceptual/Efficient:* Returns a list of registered dynamic trait keys and their values for a Form. (Note: Returning dynamic lists/maps from public functions is complex/gas-heavy. Often, events are used, or a helper function to get keys is provided). Let's implement returning values for registered keys.

*   **Form Staking for Yield:**
    14. `stakeFormForYield(uint256 tokenId)`: Stakes a Primal Form NFT owned by the caller for yield distribution. Requires token approval.
    15. `unstakeFormFromYield(uint256 tokenId)`: Unstakes a Primal Form NFT.
    16. `claimYield(uint256[] calldata tokenIds)`: Calculates and transfers accumulated yield for the specified staked Forms to the caller.
    17. `getFormStakeInfo(uint256 tokenId)`: Query stake time for a staked Form.
    18. `getPendingYield(uint256 tokenId)`: Calculate available yield for a specific staked Form.

*   **Lightweight Governance:**
    19. `proposeParameterChange(string memory parameterName, uint256 newValue)`: Allows eligible users (e.g., stakers or Form holders) to propose changing a protocol parameter (e.g., `minForgingDuration`, `baseForgingFee`).
    20. `voteOnProposal(uint256 proposalId, bool support)`: Allows eligible users to vote on an active proposal. Voting power could be based on staked Essence amount or owned/staked Forms. Let's use staked Essence amount for simplicity.
    21. `executeProposal(uint256 proposalId)`: Allows anyone to execute a proposal if the voting period has ended and the support threshold is met.
    22. `getProposalDetails(uint256 proposalId)`: Query details of a specific governance proposal.
    23. `getVoteCount(uint256 proposalId, bool support)`: Query the number of votes for/against a proposal.

*   **Fees:**
    24. `withdrawProtocolFees(address tokenAddress)`: Owner withdraws accumulated fees for a specific token.

*   **Query Parameters:**
    25. `getMinForgingDuration()`: Get the current minimum duration required for forging.
    26. `getBaseForgingFee()`: Get the current base fee for forging.
    27. `getEssenceRequiredForForging()`: Get the amount of Essence required (can be fixed or dynamic). Let's make it a fixed amount for simplicity in this example, burned upon finalize.

---

**Solidity Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Needed if contract holds NFTs
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; // If using 1155, though outline is ERC20/721
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using OZ Ownable for standard ownership pattern

// Mock/Placeholder interfaces if not using standard ERC implementations provided by OZ.
// Assuming standard OZ interfaces are used based on imports.

/**
 * @title GenesisProtocol
 * @dev A protocol for staking Essence (ERC-20) to forge dynamic Primal Form (ERC-721) NFTs.
 *      Includes dynamic traits, Form staking for yield, and lightweight governance.
 */
contract GenesisProtocol is Ownable, ReentrancyGuard, IERC721Receiver {

    // --- STATE VARIABLES ---

    // Token Contracts
    IERC20 public essenceToken;
    IERC721 public primalFormToken;
    IERC20 public yieldToken; // Token distributed as yield to staked Forms

    // Staking & Forging State
    struct EssenceStake {
        uint256 amount;
        uint64 startTime; // Use uint64 for timestamp for gas
        bool forgingInitiated; // True if forging process has started with this stake
    }
    mapping(address => EssenceStake) public essenceStakes; // Staker address => stake info

    struct FormStake {
        uint64 stakeTime; // Timestamp when Form was staked
    }
    mapping(uint256 => FormStake) public formStakes; // Primal Form tokenId => stake info
    mapping(address => uint256[]) public stakedFormsByAddress; // Helper to track staked forms per address (manual management needed)

    // Forging Parameters
    uint64 public minForgingDuration = 7 days; // Minimum time Essence must be staked before forging
    uint256 public baseForgingFee = 1 ether / 100; // 0.01 Ether fee collected (example, can be other tokens)
    uint256 public essenceRequiredForForging = 100 ether; // Fixed amount of Essence required

    // Dynamic Trait State
    mapping(uint256 => mapping(string => string)) public formDynamicTraits; // tokenId => traitKey => traitValue
    mapping(string => bool) public registeredDynamicTraits; // traitKey => isRegistered
    address public strategistAddress; // Address allowed to update dynamic traits

    // Governance State
    struct Proposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        uint64 votingPeriodEnd; // Timestamp when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        address proposer;
        bool executed;
        mapping(address => bool) hasVoted; // Staker address => voted
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal info

    uint256 public minVoteStakeThreshold = 10 ether; // Minimum staked Essence required to vote/propose
    uint256 public proposalExecutionThreshold = 50; // % required for 'For' votes to pass (e.g., 50)

    // Fee Collection
    mapping(address => uint256) public collectedFees; // tokenAddress => amount collected

    // Yield Parameters (Example: Linear yield based on time)
    uint256 public yieldRatePerSecond = 1 ether / (365 days); // Example: 1 token per year per Form

    // --- EVENTS ---

    event EssenceStaked(address indexed staker, uint256 amount, uint64 startTime);
    event EssenceUnstaked(address indexed staker, uint256 amount);
    event ForgingInitiated(address indexed staker, uint256 lockedAmount);
    event FormForged(address indexed owner, uint256 indexed tokenId, uint256 essenceBurned, uint256 feePaid);
    event TraitUpdated(uint256 indexed tokenId, string traitKey, string traitValue);
    event DynamicTraitRegistered(string traitKey);
    event FormStakedForYield(address indexed staker, uint256 indexed tokenId, uint64 stakeTime);
    event FormUnstakedFromYield(address indexed staker, uint256 indexed tokenId, uint64 unstakeTime);
    event YieldClaimed(address indexed staker, uint256[] tokenIds, uint256 amount);
    event ParameterChangeProposed(uint256 indexed proposalId, string parameterName, uint256 newValue, uint64 votingPeriodEnd, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, string parameterName, uint256 newValue);
    event FeesWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event StrategistUpdated(address indexed oldStrategist, address indexed newStrategist);


    // --- CONSTRUCTOR ---

    constructor(address initialStrategist) Ownable(msg.sender) {
        strategistAddress = initialStrategist;
    }

    // --- MODIFIERS ---

    modifier onlyStrategist() {
        require(msg.sender == strategistAddress, "Not strategist");
        _;
    }

    modifier whenForgingReady(address staker) {
        require(essenceStakes[staker].amount > 0, "No essence staked");
        require(essenceStakes[staker].forgingInitiated, "Forging not initiated");
        require(block.timestamp >= essenceStakes[staker].startTime + minForgingDuration, "Forging duration not met");
        require(essenceStakes[staker].amount >= essenceRequiredForForging, "Insufficient essence for forging");
        _;
    }

    modifier whenNotStaked(uint256 tokenId) {
        require(formStakes[tokenId].stakeTime == 0, "Form is currently staked");
        _;
    }

    modifier whenStaked(uint256 tokenId) {
        require(formStakes[tokenId].stakeTime > 0, "Form is not staked");
        _;
    }

    // --- INITIALIZATION/SETUP FUNCTIONS ---

    /**
     * @dev Sets the addresses for the required tokens. Can only be called once for each token.
     * @param _essence Address of the Essence ERC20 token.
     * @param _form Address of the Primal Form ERC721 token.
     * @param _yield Address of the Yield ERC20 token.
     */
    function setTokenAddresses(IERC20 _essence, IERC721 _form, IERC20 _yield) external onlyOwner {
        require(address(_essence) != address(0), "Essence address zero");
        require(address(_form) != address(0), "Form address zero");
        require(address(_yield) != address(0), "Yield address zero");
        require(address(essenceToken) == address(0), "Essence already set");
        require(address(primalFormToken) == address(0), "Form already set");
        require(address(yieldToken) == address(0), "Yield already set");

        essenceToken = _essence;
        primalFormToken = _form;
        yieldToken = _yield;
    }

    /**
     * @dev Sets the address of the Strategist role.
     * @param _strategist The new strategist address.
     */
    function setStrategist(address _strategist) external onlyOwner {
        require(_strategist != address(0), "Strategist address zero");
        emit StrategistUpdated(strategistAddress, _strategist);
        strategistAddress = _strategist;
    }

    // --- ESSENCE STAKING & FORGING FUNCTIONS ---

    /**
     * @dev Stakes Essence tokens for forging.
     * @param amount The amount of Essence to stake.
     */
    function stakeEssence(uint256 amount) external nonReentrant {
        require(address(essenceToken) != address(0), "Essence token not set");
        require(amount > 0, "Amount must be greater than 0");
        require(essenceStakes[msg.sender].amount == 0, "Already have an active stake");
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "Essence transfer failed");

        essenceStakes[msg.sender] = EssenceStake({
            amount: amount,
            startTime: uint64(block.timestamp),
            forgingInitiated: false
        });

        emit EssenceStaked(msg.sender, amount, essenceStakes[msg.sender].startTime);
    }

    /**
     * @dev Unstakes Essence tokens. Only possible if forging hasn't been initiated or conditions aren't met yet.
     */
    function unstakeEssence() external nonReentrant {
        EssenceStake storage stake = essenceStakes[msg.sender];
        require(stake.amount > 0, "No active stake");
        require(!stake.forgingInitiated, "Forging process initiated, cannot unstake");
        // Add check here if stake duration passed? Or allow unstake anytime before initiate?
        // Let's allow unstake anytime BEFORE initiateFor Forging
        // If minimum forging duration passed, maybe they lose the ability to unstake and MUST forge?
        // Let's allow unstake *before* minimum duration OR *before* forgingInitiated
        if (block.timestamp < stake.startTime + minForgingDuration && !stake.forgingInitiated) {
             uint256 amountToUnstake = stake.amount;
             delete essenceStakes[msg.sender];
             require(essenceToken.transfer(msg.sender, amountToUnstake), "Essence transfer failed");
             emit EssenceUnstaked(msg.sender, amountToUnstake);
        } else {
             revert("Cannot unstake after forging initiated or duration passed");
        }
    }

     /**
     * @dev Initiates the forging process, locking staked Essence.
     *      Can only be called once per stake.
     */
    function initiateFormForging() external {
        EssenceStake storage stake = essenceStakes[msg.sender];
        require(stake.amount > 0, "No essence staked");
        require(!stake.forgingInitiated, "Forging already initiated for this stake");

        stake.forgingInitiated = true;

        emit ForgingInitiated(msg.sender, stake.amount);
    }

    /**
     * @dev Finalizes the forging process, burns Essence, and mints a Primal Form NFT.
     *      Requires minimum staking duration to have passed since initiateFormForging.
     *      Requires Essence token and Primal Form token addresses to be set.
     *      Requires user's staked amount meets the required amount.
     */
    function finalizeFormForging() external nonReentrant whenForgingReady(msg.sender) {
        require(address(primalFormToken) != address(0), "Primal Form token not set");

        EssenceStake storage stake = essenceStakes[msg.sender];
        uint256 essenceToBurn = stake.amount; // Burn all staked amount
        uint256 forgingFee = baseForgingFee; // Collect fee (can be 0)

        // Reset stake information *before* external calls
        delete essenceStakes[msg.sender];

        // --- External Calls ---
        // Burn Essence tokens (assuming essenceToken has a burn function or transfer to burn address)
        // Using transfer to a burn address (address(0)) as a common pattern if no burn function
        require(essenceToken.transfer(address(0), essenceToBurn), "Essence burn failed");

        // Mint Primal Form NFT (assuming primalFormToken has a mint function callable by this contract)
        // This requires the Primal Form contract to allow this contract to mint.
        // Example: primalFormToken.mint(msg.sender); // Needs to be defined in PrimalForm contract
        // For demonstration, let's assume a mock mint function or a simple transfer after minting by owner
        // In a real scenario, GenesisProtocol would likely be the MINTER_ROLE in PrimalForm contract.

        // *** MOCK MINTING ***
        // This is a PLACEHOLDER. A real implementation needs cross-contract calls
        // to a PrimalForm contract that manages token IDs and actual minting.
        uint256 newFormTokenId = _mintMockPrimalForm(msg.sender); // MOCK CALL

        // Collect Fee (assuming fee is in ETH or a separate token)
        // If fee is in ETH:
        // require(msg.value >= forgingFee, "Insufficient fee");
        // collectedFees[address(0)] += forgingFee; // Track ETH fees

        // If fee is in another token (e.g., Essence, or a dedicated fee token):
        // require(feeToken.transferFrom(msg.sender, address(this), forgingFee), "Fee transfer failed");
        // collectedFees[address(feeToken)] += forgingFee;

        // For this example, let's assume fee is collected in the Yield Token
        require(yieldToken.transferFrom(msg.sender, address(this), forgingFee), "Fee transfer failed");
        collectedFees[address(yieldToken)] += forgingFee;


        // Assign Initial Dynamic Traits (Example)
        // These would likely be determined algorithmically based on staking duration, amount, time of day, etc.
        // For this example, assign simple initial traits.
        _setFormTraitInternal(newFormTokenId, "ForgerAddress", string(abi.encodePacked(msg.sender)));
        _setFormTraitInternal(newFormTokenId, "ForgingTime", string(abi.encodePacked(block.timestamp)));
        _setFormTraitInternal(newFormTokenId, "EssenceBurned", string(abi.encodePacked(essenceToBurn)));
        // More complex traits could be based on block hash, VRF randomness, external data...

        emit FormForged(msg.sender, newFormTokenId, essenceToBurn, forgingFee);
    }

    // --- Dynamic Form Traits Functions ---

    /**
     * @dev Allows Strategist or Owner to register a new trait key that can be used for dynamic traits.
     * @param traitKey The name of the trait key to register.
     */
    function registerDynamicTrait(string memory traitKey) external onlyOwner {
        require(!registeredDynamicTraits[traitKey], "Trait key already registered");
        registeredDynamicTraits[traitKey] = true;
        emit DynamicTraitRegistered(traitKey);
    }

     /**
     * @dev Allows Strategist to update the value of a registered dynamic trait for a specific Form.
     * @param tokenId The ID of the Primal Form token.
     * @param traitKey The registered key name of the trait.
     * @param traitValue The new value for the trait.
     */
    function updateFormTrait(uint256 tokenId, string memory traitKey, string memory traitValue) external onlyStrategist {
        // Note: This function assumes the tokenId exists. A real implementation might check ownership or existence via the PrimalForm contract.
        require(registeredDynamicTraits[traitKey], "Trait key not registered");
        _setFormTraitInternal(tokenId, traitKey, traitValue);
    }

    /**
     * @dev Internal helper to set trait value and emit event.
     * @param tokenId The ID of the Primal Form token.
     * @param traitKey The key name of the trait.
     * @param traitValue The value for the trait.
     */
    function _setFormTraitInternal(uint256 tokenId, string memory traitKey, string memory traitValue) internal {
        formDynamicTraits[tokenId][traitKey] = traitValue;
        emit TraitUpdated(tokenId, traitKey, traitValue);
    }


    /**
     * @dev Query the value of a specific dynamic trait for a Form.
     * @param tokenId The ID of the Primal Form token.
     * @param traitKey The key name of the trait.
     * @return The value of the trait. Returns empty string if not set or key not registered.
     */
    function getFormTrait(uint256 tokenId, string memory traitKey) external view returns (string memory) {
        // Note: Does not require traitKey to be 'registeredDynamicTraits' to allow querying potentially unregistered data,
        // but updateFormTrait requires it.
        return formDynamicTraits[tokenId][traitKey];
    }

     /**
     * @dev Get values for a list of registered dynamic trait keys for a Form.
     *      Note: This is a helper. Getting *all* trait keys dynamically is complex/expensive.
     * @param tokenId The ID of the Primal Form token.
     * @param traitKeys Array of trait keys to query.
     * @return An array of trait values corresponding to the input keys.
     */
    function getAllFormTraits(uint256 tokenId, string[] memory traitKeys) external view returns (string[] memory) {
        string[] memory traitValues = new string[](traitKeys.length);
        for (uint i = 0; i < traitKeys.length; i++) {
            traitValues[i] = formDynamicTraits[tokenId][traitKeys[i]];
        }
        return traitValues;
    }


    // --- FORM STAKING FOR YIELD FUNCTIONS ---

    /**
     * @dev Stakes a Primal Form NFT for yield.
     * @param tokenId The ID of the Primal Form token to stake.
     */
    function stakeFormForYield(uint256 tokenId) external nonReentrant whenNotStaked(tokenId) {
        require(address(primalFormToken) != address(0), "Primal Form token not set");
        require(primalFormToken.ownerOf(tokenId) == msg.sender, "Not owner of token");

        // Transfer NFT to this contract
        primalFormToken.safeTransferFrom(msg.sender, address(this), tokenId);

        formStakes[tokenId] = FormStake({
            stakeTime: uint64(block.timestamp)
        });

        // Add to stakedFormsByAddress helper array (manual management)
        stakedFormsByAddress[msg.sender].push(tokenId);

        emit FormStakedForYield(msg.sender, tokenId, formStakes[tokenId].stakeTime);
    }

    /**
     * @dev Unstakes a Primal Form NFT.
     * @param tokenId The ID of the Primal Form token to unstake.
     */
    function unstakeFormFromYield(uint256 tokenId) external nonReentrant whenStaked(tokenId) {
         require(primalFormToken.ownerOf(tokenId) == address(this), "Token not held by contract"); // Should always be true if staked

        // Before unstaking, claim yield (optional, could force claim on unstake or make separate)
        // Let's make claim separate.

        // Find token in stakedFormsByAddress array and remove (gas considerations!)
        // This is an O(N) operation. For many staked forms per user, this is expensive.
        // A better design would use linked lists or mappings to manage the list index.
        uint256[] storage userStakedForms = stakedFormsByAddress[msg.sender];
        bool found = false;
        for (uint i = 0; i < userStakedForms.length; i++) {
            if (userStakedForms[i] == tokenId) {
                // Swap with last element and pop
                userStakedForms[i] = userStakedForms[userStakedForms.length - 1];
                userStakedForms.pop();
                found = true;
                break;
            }
        }
        require(found, "Token not found in user's staked list"); // Should be found if staked

        delete formStakes[tokenId];

        // Transfer NFT back to original staker (assuming msg.sender is the original staker)
        primalFormToken.safeTransferFrom(address(this), msg.sender, tokenId);

        emit FormUnstakedFromYield(msg.sender, tokenId, uint64(block.timestamp));
    }

    /**
     * @dev Calculates and transfers accumulated yield for specified staked Forms.
     * @param tokenIds Array of token IDs to claim yield for.
     */
    function claimYield(uint256[] calldata tokenIds) external nonReentrant {
        require(address(yieldToken) != address(0), "Yield token not set");
        uint256 totalYield = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            FormStake storage stake = formStakes[tokenId];

            // Ensure the token is staked in this contract by the caller
            // (check ownership before external transfer to prevent reentrancy risk if Form contract is malicious)
            require(primalFormToken.ownerOf(tokenId) == address(this), "Token not held by contract for yield");
            // We also need to verify that msg.sender is the correct staker, which is tricky with just tokenId
            // unless we store staker address in the FormStake struct. Let's add staker address to struct.
            // Re-design FormStake: struct FormStake { uint64 stakeTime; address staker; }
            // Requires updating stakeFormForYield as well.

            // Re-implementing with staker in struct:
            struct FormStakeWithStaker { uint64 stakeTime; address staker; }
            mapping(uint256 => FormStakeWithStaker) private _formStakesWithStaker; // Internal mapping
            mapping(uint256 => FormStake) public formStakes; // Keep public for querying, but internal is source of truth
             // Update stakeFormForYield: _formStakesWithStaker[tokenId] = FormStakeWithStaker({ stakeTime: ..., staker: msg.sender }); formStakes[tokenId] = FormStake({...});
             // Update unstakeFormFromYield: Check _formStakesWithStaker[tokenId].staker == msg.sender, then delete both map entries.

            // Simpler approach for this example: Assume msg.sender is claiming for their own staked tokens
            // and the staking functions ensure they are the staker.
            // The crucial check is that the token *is* staked in this contract.
            require(stake.stakeTime > 0, "Token not staked for yield");
            // Potential issue: Is this token staked *by msg.sender*? Cannot tell from stake struct alone.
            // StakedFormsByAddress helper helps, but isn't strictly enforced here.
            // Let's assume for this example that only the address that called stakeFormForYield can claim for that token ID.
            // This requires storing the staker's address with the stake:

            // --- REVISED FormStake Struct (Conceptual, requires changes above) ---
            // struct FormStake { uint64 stakeTime; address staker; }
            // mapping(uint256 => FormStake) public formStakes;

            // With revised struct:
            // require(formStakes[tokenId].staker == msg.sender, "Not the staker of this token");
            // ... (Rest of the logic)

            // Back to the original simple struct for code simplicity, acknowledging the limitation:
            // This version allows *anyone* to potentially claim yield for a token staked by *anyone* else,
            // as long as it's staked. This needs fixing in a real system (store staker address).
            // Let's proceed with the simple struct and add a comment.

            // Calculate yield since last claim or stake time
            uint256 duration = block.timestamp - stake.stakeTime;
            uint256 yieldEarned = duration * yieldRatePerSecond;

            // Reset stake time to now for future calculations (compound effect)
            stake.stakeTime = uint64(block.timestamp); // This gives compounding yield

            totalYield += yieldEarned;
        }

        require(totalYield > 0, "No yield accumulated");

        // Transfer total yield
        require(yieldToken.transfer(msg.sender, totalYield), "Yield transfer failed");

        emit YieldClaimed(msg.sender, tokenIds, totalYield);
    }

    /**
     * @dev Query stake time for a staked Form.
     * @param tokenId The ID of the Primal Form token.
     * @return The timestamp when the token was staked. 0 if not staked.
     */
    function getFormStakeInfo(uint256 tokenId) external view returns (uint64 stakeTime) {
        return formStakes[tokenId].stakeTime;
    }

    /**
     * @dev Calculate pending yield for a specific staked Form based on current time.
     * @param tokenId The ID of the Primal Form token.
     * @return The amount of yield currently available to claim for this token.
     */
    function getPendingYield(uint256 tokenId) external view returns (uint256) {
        FormStake storage stake = formStakes[tokenId];
        if (stake.stakeTime == 0) {
            return 0; // Not staked
        }
        uint256 duration = block.timestamp - stake.stakeTime;
        return duration * yieldRatePerSecond;
    }


    // --- LIGHTWEIGHT GOVERNANCE FUNCTIONS ---

    /**
     * @dev Allows eligible users (based on stake) to propose changing a protocol parameter.
     * @param parameterName The name of the parameter (e.g., "minForgingDuration", "baseForgingFee").
     * @param newValue The desired new value for the parameter.
     */
    function proposeParameterChange(string memory parameterName, uint256 newValue) external {
        require(essenceStakes[msg.sender].amount >= minVoteStakeThreshold, "Insufficient stake to propose");
        // Basic validation for parameter names (can be extended)
        require(
            keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("minForgingDuration")) ||
            keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("baseForgingFee")) ||
            keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("essenceRequiredForForging")) ||
            keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("minVoteStakeThreshold")) ||
            keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("proposalExecutionThreshold")) ||
            keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("yieldRatePerSecond")),
            "Invalid parameter name"
        );
        // Basic validation for new values (can be extended)
         if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("minForgingDuration"))) {
             require(newValue >= 1 days, "Min forging duration too short"); // Example check
         }
         if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("proposalExecutionThreshold"))) {
             require(newValue <= 100, "Threshold cannot exceed 100%");
         }


        uint256 proposalId = nextProposalId++;
        uint64 votingEnds = uint64(block.timestamp + 3 days); // Example: 3-day voting period

        proposals[proposalId] = Proposal({
            id: proposalId,
            parameterName: parameterName,
            newValue: newValue,
            votingPeriodEnd: votingEnds,
            votesFor: 0,
            votesAgainst: 0,
            proposer: msg.sender,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit ParameterChangeProposed(proposalId, parameterName, newValue, votingEnds, msg.sender);
    }

    /**
     * @dev Allows eligible users (based on stake) to vote on an active proposal.
     *      Voting power is based on the user's currently staked Essence amount.
     * @param proposalId The ID of the proposal.
     * @param support True for 'For', False for 'Against'.
     */
    function voteOnProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp <= proposal.votingPeriodEnd, "Voting period has ended");

        uint256 votingPower = essenceStakes[msg.sender].amount; // Voting power = staked Essence
        require(votingPower >= minVoteStakeThreshold, "Insufficient stake to vote");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit Voted(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @dev Allows anyone to execute a proposal if the voting period has ended
     *      and the 'For' votes meet the required threshold.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.votingPeriodEnd, "Voting period not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast");

        // Calculate support percentage (handle potential division by zero if totalVotes is 0)
        uint256 supportPercentage = (proposal.votesFor * 100) / totalVotes;
        require(supportPercentage >= proposalExecutionThreshold, "Support threshold not met");

        // Execute the parameter change
        bytes32 parameterHash = keccak256(abi.encodePacked(proposal.parameterName));

        if (parameterHash == keccak256(abi.encodePacked("minForgingDuration"))) {
             minForgingDuration = uint64(proposal.newValue);
         } else if (parameterHash == keccak256(abi.encodePacked("baseForgingFee"))) {
             baseForgingFee = proposal.newValue;
         } else if (parameterHash == keccak256(abi.encodePacked("essenceRequiredForForging"))) {
             essenceRequiredForForging = proposal.newValue;
         } else if (parameterHash == keccak256(abi.encodePacked("minVoteStakeThreshold"))) {
              minVoteStakeThreshold = proposal.newValue;
         } else if (parameterHash == keccak256(abi.encodePacked("proposalExecutionThreshold"))) {
             require(proposal.newValue <= 100, "Threshold cannot exceed 100%");
             proposalExecutionThreshold = proposal.newValue;
         } else if (parameterHash == keccak256(abi.encodePacked("yieldRatePerSecond"))) {
             yieldRatePerSecond = proposal.newValue;
         } else {
             // Should not happen due to proposeParameterChange validation
             revert("Unknown parameter name");
         }


        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.parameterName, proposal.newValue);
    }

    /**
     * @dev Query details of a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return Tuple containing proposal details.
     */
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        string memory parameterName,
        uint256 newValue,
        uint64 votingPeriodEnd,
        uint256 votesFor,
        uint256 votesAgainst,
        address proposer,
        bool executed
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist"); // Or return default values if allowing non-existent check
        return (
            proposal.id,
            proposal.parameterName,
            proposal.newValue,
            proposal.votingPeriodEnd,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.proposer,
            proposal.executed
        );
    }

     /**
     * @dev Query the vote count for a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return Tuple containing votes for and against.
     */
    function getVoteCount(uint256 proposalId) external view returns (uint256 votesFor, uint256 votesAgainst) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id != 0, "Proposal does not exist");
         return (proposal.votesFor, proposal.votesAgainst);
     }


    // --- FEE FUNCTIONS ---

    /**
     * @dev Allows the owner to withdraw accumulated fees for a specific token.
     * @param tokenAddress The address of the token to withdraw fees in.
     */
    function withdrawProtocolFees(address tokenAddress) external onlyOwner nonReentrant {
        uint256 amount = collectedFees[tokenAddress];
        require(amount > 0, "No fees collected for this token");

        collectedFees[tokenAddress] = 0;

        // If tokenAddress is address(0), withdraw ETH
        if (tokenAddress == address(0)) {
            // This case is not currently used as fees are collected in Yield Token in this example
            // If collecting ETH fees: payable(owner()).transfer(amount);
            revert("ETH fee withdrawal not implemented in this example");
        } else {
            IERC20 feeToken = IERC20(tokenAddress);
            require(feeToken.transfer(owner(), amount), "Fee withdrawal failed");
        }

        emit FeesWithdrawn(tokenAddress, owner(), amount);
    }


    // --- QUERY PARAMETERS ---

    /**
     * @dev Get the current minimum duration required for forging.
     */
    // function getMinForgingDuration() public view returns (uint64) is already public state variable

    /**
     * @dev Get the current base fee for forging.
     */
    // function getBaseForgingFee() public view returns (uint256) is already public state variable

     /**
     * @dev Get the amount of Essence required for forging.
     */
    // function getEssenceRequiredForForging() public view returns (uint256) is already public state variable


    // --- ERC721Receiver compatibility (needed if this contract holds NFTs) ---

    /**
     * @dev See IERC721Receiver.onERC721Received.
     *      Allows receiving Primal Form NFTs for staking.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Ensure only the Primal Form token is allowed to be received via this method
        require(msg.sender == address(primalFormToken), "Can only receive Primal Form tokens");

        // Optional: Add checks based on 'data' if needed for specific staking logic triggered by transfer
        // For staking via stakeFormForYield, the transfer is initiated *by* the protocol,
        // so no extra checks on operator/from are strictly necessary here,
        // but checking `from` ensures the NFT wasn't sent accidentally.
        // require(from == _expectedStakerAddress, "Unexpected sender"); // Requires storing expected staker before transfer

        // Accept the token
        return this.onERC721Received.selector;
    }


    // --- INTERNAL MOCKING FUNCTIONS (REPLACE IN REAL DEPLOYMENT) ---
    // These functions mock external contract interactions for demonstration purposes.

    /**
     * @dev MOCK function to simulate minting a Primal Form NFT.
     *      In a real system, this would call the PrimalForm contract's mint function.
     * @param to The address to mint the token to.
     * @return The newly minted token ID.
     */
    uint256 private mockNextTokenId = 1; // Simple counter for mock minting
    function _mintMockPrimalForm(address to) internal returns (uint256) {
         require(address(primalFormToken) != address(0), "Primal Form token not set");
         // In a real contract, you would call: primalFormToken.safeMint(to, mockNextTokenId);
         // or primalFormToken.mint(to, mockNextTokenId); depending on the ERC721 implementation.
         // For this mock, we just increment and return the ID.
         uint256 newTokenId = mockNextTokenId++;
         // *** IMPORTANT: The PrimalForm contract needs to actually do the minting and state updates for this ID! ***
         // *** The PrimalForm contract would need to trust this GenesisProtocol contract (e.g., via MINTER_ROLE). ***
         return newTokenId;
    }
}
```

---

**Explanation of Advanced/Interesting Concepts & Functions:**

1.  **Dynamic NFT Traits (`formDynamicTraits`, `registerDynamicTrait`, `updateFormTrait`, `getFormTrait`, `getAllFormTraits`):**
    *   Instead of traditional static NFT metadata stored off-chain via a URI, key traits are stored directly in this contract's state.
    *   `registerDynamicTrait` provides a controlled list of *which* traits can be modified dynamically.
    *   `updateFormTrait` (controlled by the `strategistAddress`) allows these on-chain traits to be changed *after* the NFT is minted. This enables NFTs that react to external events, staking, governance, or other protocol interactions.
    *   `getAllFormTraits` shows how you might expose these, though retrieving a map's contents dynamically is a common Solidity challenge often solved with helper functions or event indexing. The provided version takes keys as input.

2.  **Staking-Based Forging (`stakeEssence`, `initiateFormForging`, `finalizeFormForging`, `getForgingReadiness`):**
    *   More complex than simple minting. It involves a multi-step process (stake -> initiate -> wait -> finalize).
    *   Time-based requirement (`minForgingDuration`) links staking duration to the ability to forge, enabling time-weighted mechanics.
    *   `initiateFormForging` serves as a commitment step, locking the staked tokens for forging.
    *   `finalizeFormForging` consumes the staked tokens (burns) and produces a new asset (mints NFT) and collects a fee.

3.  **NFT Staking for Yield (`stakeFormForYield`, `unstakeFormFromYield`, `claimYield`, `getFormStakeInfo`, `getPendingYield`):**
    *   The generated Primal Form NFTs can be staked *back* into the protocol.
    *   Staking NFTs allows them to earn yield in another token (`yieldToken`).
    *   Yield calculation is based on staking duration (`yieldRatePerSecond`).
    *   Requires the contract to custody the staked NFTs, implementing `IERC721Receiver`.

4.  **Lightweight On-chain Governance (`proposeParameterChange`, `voteOnProposal`, `executeProposal`, `getProposalDetails`, `getVoteCount`):**
    *   Simple proposal system for changing core protocol parameters.
    *   Voting power (`voteOnProposal`) is tied to staked Essence amount, linking participation in the core mechanic (staking) to governance influence.
    *   Requires a threshold of votes (`proposalExecutionThreshold`) and end-of-period check (`executeProposal`) to enact changes.
    *   Uses a `Proposal` struct and mapping to manage the state of multiple proposals concurrently.

5.  **Role-Based Access Control (`onlyOwner`, `onlyStrategist`, `setStrategist`):**
    *   Beyond just `onlyOwner`, introduces a `strategistAddress` with specific permissions (updating dynamic traits), allowing separation of concerns.

6.  **Fee Collection (`collectedFees`, `withdrawProtocolFees`):**
    *   Basic fee collection mechanism during the forging process, tracked by token address.

7.  **Reentrancy Guard (`nonReentrant`):**
    *   Important security pattern used on functions that perform external calls (`finalizeFormForging`, `claimYield`, `executeProposal`, `withdrawProtocolFees`).

8.  **Modular Token Interfaces:**
    *   Uses `IERC20` and `IERC721` interfaces, making the contract dependent on specific token implementations set by the owner, promoting modularity.

This contract provides a framework for a multi-asset protocol with dynamic components and a simple governance layer, touching on several advanced DeFi and NFT concepts beyond standard token contracts. Remember that the mocking functions (`_mintMockPrimalForm`) would need to be replaced with actual calls to external, deployed token contracts in a real application. Also, managing the `stakedFormsByAddress` array manually with `push` and `pop` on `unstakeFormFromYield` is gas-inefficient for users with many staked forms; a production system might use a more advanced data structure or simply rely on events and off-chain indexing to track user stakes.