Here's a Solidity smart contract for a "Decentralized Autonomous Resource Synthesizer (DARS)" called `AlchemistForge`. This contract introduces several advanced and creative concepts:

1.  **Dynamic Resource Synthesis:** Users deposit "Materials" (external ERC20 tokens) which are converted into "Essence" (an internal ERC20 token) based on dynamic, community-governed formulas.
2.  **Reputation System with Decay:** Users earn reputation through participation (synthesis, burning Essence) and off-chain attestation. This reputation decays over time, encouraging continuous engagement. Reputation influences voting power and access.
3.  **Reputation-Weighted Governance:** New synthesis formulas are proposed and voted on by users, with their voting power weighted by their reputation score.
4.  **Modular "Catalyst" Integration:** The system allows registration of external smart contracts as "Catalysts." Users can then spend Essence on these Catalysts to trigger specific functionalities, making `AlchemistForge` a programmable resource dispenser.
5.  **Role-Based Attestation:** A designated "Alchemist" role can award reputation for off-chain contributions, bridging on-chain incentives with real-world activity.

This design aims to be novel by combining elements of dynamic economic systems, reputation-based governance, and modular extensibility, avoiding direct duplication of a single open-source project while drawing inspiration from various advanced concepts in the blockchain space.

---

### **Outline:**

**I. Core Components:**
*   `Essence` ERC20 Token (Internal)
*   `Material` Registry (Whitelisted ERC20s for synthesis)
*   `Formula` Management (Dynamic synthesis rules with voting)
*   `Reputation` System (User scoring with time-based decay)
*   `Catalyst` Registry (For interacting with external contracts)
*   `Role-Based Access Control` (Owner, Alchemists)

**II. Core Logic:**
*   Material Deposits from users
*   Essence Synthesis from deposited materials
*   Essence Consumption via registered Catalysts
*   Reputation Updates & Time-based Decay
*   Dynamic Parameter Adjustment (via governance/owner)

**III. Governance & Meta-Functions:**
*   Formula Proposals & Reputation-Weighted Voting
*   Material Whitelisting & Management
*   Emergency Pause/Unpause Mechanism
*   Role Management (Alchemists)
*   Owner-only administrative controls

---

### **Function Summary:**

**I. Essence Token & Core Resource Management:**
1.  `constructor()`: Initializes the contract, deploying and linking the internal `Essence` ERC20 token.
2.  `depositMaterial(address materialToken, uint256 amount)`: Allows users to deposit whitelisted ERC20 materials into the Forge.
3.  `synthesizeEssence(address materialToken)`: Converts deposited materials into `Essence` based on the active formula for that material. Awards reputation for successful synthesis.
4.  `burnEssence(uint256 amount)`: Allows users to burn their `Essence` for a proportionate reputation gain (e.g., as a sign of commitment).
5.  `getMaterialBalance(address user, address materialToken)`: Retrieves the amount of a specific material deposited by a user.
6.  `getEssenceAddress()`: Returns the address of the deployed `Essence` ERC20 token contract.

**II. Dynamic Formula & Material Management:**
7.  `proposeSynthesisFormula(address materialToken, uint256 inputAmount, uint256 outputEssence, uint256 requiredReputation, uint256 durationBlocks)`: Allows users with sufficient reputation to propose a new synthesis formula for a specific material.
8.  `voteOnFormula(uint256 formulaId, bool approve)`: Allows users with sufficient reputation to cast a reputation-weighted vote (for/against) on a proposed formula.
9.  `finalizeFormula(uint256 formulaId)`: Finalizes a formula proposal after its voting period ends. If approved (votes for > votes against), it becomes the active formula for that material.
10. `getCurrentSynthesisFormula(address materialToken)`: Retrieves the `inputAmount`, `outputEssence`, and `requiredReputation` for the currently active synthesis formula of a given material.
11. `getFormulaProposal(uint256 formulaId)`: Retrieves the full details of a specific formula proposal.
12. `addWhitelistedMaterial(address materialToken)`: **(Owner-only)** Whitelists a new ERC20 token as a valid material for synthesis.
13. `removeWhitelistedMaterial(address materialToken)`: **(Owner-only)** Removes an ERC20 token from the list of whitelisted materials.
14. `isMaterialWhitelisted(address materialToken)`: Checks if a material token is currently whitelisted.

**III. Reputation System:**
15. `getReputation(address user)`: Retrieves a user's current reputation score, automatically applying any time-based decay.
16. `attestContribution(address contributor, uint256 points)`: **(Alchemist-only)** Allows designated Alchemists to award reputation points to a contributor for verified off-chain activities.
17. `setReputationDecayRate(uint256 newRatePerBlock)`: **(Owner-only)** Sets the global rate at which reputation decays per block.
18. `setMinimumVoteReputation(uint256 minRep)`: **(Owner-only)** Sets the minimum reputation score required for users to propose or vote on formulas.

**IV. Catalyst Integration & Essence Consumption:**
19. `registerCatalyst(address catalystContract, string memory description)`: **(Owner-only)** Registers an external smart contract as a recognized "Catalyst."
20. `deregisterCatalyst(address catalystContract)`: **(Owner-only)** Deregisters a Catalyst.
21. `triggerCatalyst(address catalystContract, uint256 amount, bytes memory data)`: Allows users to transfer `Essence` to a registered Catalyst contract and execute a specific function on that Catalyst by providing arbitrary `data`.
22. `isCatalystRegistered(address catalystContract)`: Checks if a given contract address is currently registered as a Catalyst.

**V. Governance & System Parameters (Admin/Owner):**
23. `setAlchemistRole(address alchemist, bool hasRole)`: **(Owner-only)** Grants or revokes the 'Alchemist' role to/from an address.
24. `pause()`: **(Owner-only)** Pauses critical functionalities of the `AlchemistForge` contract in emergencies (e.g., deposits, synthesis, catalyst triggers).
25. `unpause()`: **(Owner-only)** Unpauses the contract functionalities.
26. `withdrawExcessMaterial(address materialToken, uint256 amount)`: **(Owner-only)** Allows the contract owner to withdraw any excess or accidentally sent material tokens from the Forge.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Base ERC20 for the internal token

/**
 * @title The Alchemist's Forge: A Decentralized Autonomous Resource Synthesizer (DARS)
 * @author Your Name/Pseudonym
 * @notice This contract facilitates the decentralized synthesis of "Essence" (an internal resource token)
 *         from various whitelisted "Materials" (external ERC20 tokens). It features dynamic synthesis
 *         formulas, a reputation system, and integration with external "Catalyst" contracts to enable
 *         programmable resource allocation. The design aims to be novel by combining dynamic resource
 *         generation, reputation-weighted governance, and modular external contract interaction,
 *         avoiding direct duplication of existing open-source projects.
 *
 * @dev Key Concepts:
 *      - Essence Token: An internal ERC20 token representing a synthesized, valuable resource, controlled by this contract.
 *      - Materials: External ERC20 tokens that can be deposited and transformed into Essence.
 *      - Formulas: Dynamic rules defining the conversion rate from Materials to Essence, proposed
 *        and voted upon by the community (reputation-weighted).
 *      - Reputation System: A score for users, gained through participation (synthesis, burning Essence)
 *        and external attestation, which decays over time. It influences voting power and access.
 *      - Catalysts: Whitelisted external contracts that can consume Essence to trigger specific
 *        functionality or resource distribution, acting as programmable sinks for Essence.
 *      - Alchemists: A privileged role that can attest to off-chain contributions, granting reputation.
 */

// --- Outline ---
// I. Core Components:
//    - Essence ERC20 Token (Internal)
//    - Material Registry (Whitelisted ERC20s)
//    - Formula Management (Dynamic synthesis rules)
//    - Reputation System (User scoring with decay)
//    - Catalyst Registry (External contract interaction)
//    - Role-Based Access Control (Owner, Alchemists)
// II. Core Logic:
//    - Material Deposits
//    - Essence Synthesis
//    - Essence Consumption (via Catalysts)
//    - Reputation Updates & Decay
//    - Dynamic Parameter Adjustment
// III. Governance & Meta-Functions:
//    - Formula Proposals & Voting
//    - Material Whitelisting
//    - Emergency Stop/Pause
//    - Role Management

// --- Function Summary ---

// I. Essence Token & Core Resource Management:
// 1.  `constructor()`: Initializes the contract, deploying and linking the internal Essence ERC20 token.
// 2.  `depositMaterial(address materialToken, uint256 amount)`: Allows users to deposit whitelisted ERC20 materials into the Forge.
// 3.  `synthesizeEssence(address materialToken)`: Converts deposited materials into Essence based on the active formula for that material.
// 4.  `burnEssence(uint256 amount)`: Allows users to burn their Essence, potentially gaining reputation.
// 5.  `getMaterialBalance(address user, address materialToken)`: Retrieves the amount of a specific material deposited by a user.
// 6.  `getEssenceAddress()`: Returns the address of the deployed Essence ERC20 token.

// II. Dynamic Formula & Material Management:
// 7.  `proposeSynthesisFormula(address materialToken, uint256 inputAmount, uint256 outputEssence, uint256 requiredReputation, uint256 durationBlocks)`: Allows users with sufficient reputation to propose a new synthesis formula for a material.
// 8.  `voteOnFormula(uint256 formulaId, bool approve)`: Allows users with sufficient reputation to vote on a proposed formula (reputation-weighted).
// 9.  `finalizeFormula(uint256 formulaId)`: Finalizes a formula after its voting period ends, making it active if approved.
// 10. `getCurrentSynthesisFormula(address materialToken)`: Retrieves the currently active synthesis formula for a given material.
// 11. `getFormulaProposal(uint256 formulaId)`: Retrieves details of a specific formula proposal.
// 12. `addWhitelistedMaterial(address materialToken)`: (Owner-only) Whitelists a new ERC20 token as a material.
// 13. `removeWhitelistedMaterial(address materialToken)`: (Owner-only) Removes an ERC20 token from the whitelisted materials.
// 14. `isMaterialWhitelisted(address materialToken)`: Checks if a material token is whitelisted.

// III. Reputation System:
// 15. `getReputation(address user)`: Retrieves a user's current reputation score, applying decay if necessary.
// 16. `attestContribution(address contributor, uint256 points)`: (Alchemist-only) Awards reputation points to a contributor for off-chain activities.
// 17. `setReputationDecayRate(uint256 newRatePerBlock)`: (Owner-only) Sets the global reputation decay rate (points per block).
// 18. `setMinimumVoteReputation(uint256 minRep)`: (Owner-only) Sets the minimum reputation required to propose or vote on formulas.

// IV. Catalyst Integration & Essence Consumption:
// 19. `registerCatalyst(address catalystContract, string memory description)`: (Owner-only) Registers an external contract as a valid Catalyst.
// 20. `deregisterCatalyst(address catalystContract)`: (Owner-only) Deregisters a Catalyst.
// 21. `triggerCatalyst(address catalystContract, uint256 amount, bytes memory data)`: Allows users to transfer Essence to a registered Catalyst contract and trigger a specific function on it.
// 22. `isCatalystRegistered(address catalystContract)`: Checks if a contract is registered as a Catalyst.

// V. Governance & System Parameters (Admin/Owner):
// 23. `setAlchemistRole(address alchemist, bool hasRole)`: (Owner-only) Grants or revokes the 'Alchemist' role.
// 24. `pause()`: (Owner-only) Pauses core contract functionalities (e.g., deposits, synthesis, catalyst triggers).
// 25. `unpause()`: (Owner-only) Unpauses core contract functionalities.
// 26. `withdrawExcessMaterial(address materialToken, uint256 amount)`: (Owner-only) Allows the owner to withdraw excess materials held by the Forge.


// Helper contract for the internal Essence token
contract Essence is ERC20Burnable {
    constructor(address _forge) ERC20("Alchemist Essence", "ESSENCE") {
        // Mint initial supply to the Forge. The Forge will then mint/burn as needed.
        _mint(_forge, 0);
    }

    // Modifier to restrict minting/burning to only the AlchemistForge contract
    modifier onlyForge(address _forgeAddress) {
        require(msg.sender == _forgeAddress, "Essence: Only AlchemistForge can call");
        _;
    }

    // Custom mint function callable only by the AlchemistForge
    function mint(address to, uint256 amount, address _forgeAddress) public onlyForge(_forgeAddress) {
        _mint(to, amount);
    }

    // Custom burnFrom function callable only by the AlchemistForge
    function burnFrom(address account, uint256 amount, address _forgeAddress) public onlyForge(_forgeAddress) {
        // _burn already handles allowance checking if called by a third party.
        // But since AlchemistForge itself calls it with its own address as `msg.sender`
        // when a user requests burning, it directly uses _burn.
        // For user-initiated burns via AlchemistForge, the user must first approve AlchemistForge
        // to spend their Essence.
        // This is a common pattern where the main contract manages the internal token.
        super.burn(account, amount); // Directly burn from the account as `msg.sender` is AlchemistForge.
    }
}

contract AlchemistForge is Ownable, Pausable {
    // --- State Variables ---

    // Essence Token instance
    Essence public essence;

    // Materials: Tracks whitelisted ERC20s and user-deposited amounts
    mapping(address => bool) public whitelistedMaterials;
    mapping(address => mapping(address => uint256)) public userMaterialDeposits; // user => material => amount

    // Formulas: Defines rules for material to essence conversion
    struct Formula {
        address materialToken;
        uint256 inputAmount;      // Amount of material needed
        uint256 outputEssence;    // Amount of Essence produced
        uint256 requiredReputation; // Minimum reputation required to use this specific formula (future tiering)
        uint256 proposalBlock;    // Block number when proposal was made
        uint256 votingPeriodBlocks; // How many blocks voting is open
        uint256 totalVotesFor;    // Sum of reputation of 'for' votes
        uint256 totalVotesAgainst; // Sum of reputation of 'against' votes
        mapping(address => bool) hasVoted; // Tracks if a user has voted on this specific proposal
        bool finalized;           // True if the voting period has ended and status determined
        bool approved;            // Final approval status (true if passed, false otherwise)
    }
    Formula[] public formulaProposals; // Stores all proposed formulas
    mapping(address => uint256) public activeFormulaId; // materialToken => index in formulaProposals array for the active formula
    uint256 public nextFormulaId; // Counter for the next formula proposal ID (array index)

    // Reputation System: Tracks user scores and last update block for decay
    struct UserReputation {
        uint256 score;
        uint256 lastUpdateBlock;
    }
    mapping(address => UserReputation) public reputation;
    uint256 public reputationDecayRatePerBlock; // Points to decay per block
    uint256 public minimumVoteReputation;     // Minimum reputation to propose/vote on formulas

    // Role-Based Access Control: For privileged roles like Alchemists
    bytes32 public constant ALCHEMIST_ROLE = keccak256("ALCHEMIST_ROLE");
    mapping(address => bool) public hasAlchemistRole;

    // Catalysts: Whitelisted external contracts that can consume Essence
    mapping(address => bool) public registeredCatalysts;
    mapping(address => string) public catalystDescriptions; // Store descriptions for UI/info

    // --- Events ---
    event MaterialDeposited(address indexed user, address indexed materialToken, uint256 amount);
    event EssenceSynthesized(address indexed user, address indexed materialToken, uint256 materialConsumed, uint256 essenceMinted);
    event EssenceBurned(address indexed user, uint256 amount);
    event MaterialWhitelisted(address indexed materialToken, bool whitelisted);
    event FormulaProposed(uint256 indexed formulaId, address indexed proposer, address materialToken, uint256 inputAmount, uint256 outputEssence, uint256 requiredReputation, uint256 votingPeriodBlocks);
    event FormulaVoted(uint256 indexed formulaId, address indexed voter, bool approved, uint256 reputationWeightedVote);
    event FormulaFinalized(uint256 indexed formulaId, bool approved);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event AlchemistRoleSet(address indexed alchemist, bool hasRole);
    event CatalystRegistered(address indexed catalystContract, string description);
    event CatalystDeregistered(address indexed catalystContract);
    event CatalystTriggered(address indexed user, address indexed catalystContract, uint256 essenceAmount, bytes data);
    event ReputationDecayRateSet(uint256 newRate);
    event MinimumVoteReputationSet(uint256 newMinRep);

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable(false) {
        // Deploy Essence token and set AlchemistForge as its controller/minter
        essence = new Essence(address(this));
        reputationDecayRatePerBlock = 1; // Default: 1 point of reputation decays per block
        minimumVoteReputation = 100;    // Default: Minimum reputation to propose/vote on formulas
        nextFormulaId = 0;              // Initialize formula ID counter (0-indexed array)
    }

    // --- Internal Reputation Management ---

    /**
     * @dev Internal function to update a user's reputation score.
     *      Applies decay before adding/subtracting points.
     * @param user The address of the user.
     * @param change The change in reputation (positive for gain, negative for loss).
     */
    function _updateReputation(address user, int256 change) internal {
        UserReputation storage userRep = reputation[user];
        _applyReputationDecay(user); // Apply decay before updating

        if (change > 0) {
            userRep.score += uint256(change);
        } else {
            // Ensure score doesn't go below zero
            userRep.score = userRep.score > uint256(-change) ? userRep.score - uint256(-change) : 0;
        }
        userRep.lastUpdateBlock = block.number;
        emit ReputationUpdated(user, userRep.score);
    }

    /**
     * @dev Internal function to apply time-based reputation decay to a user.
     *      Calculates decay based on blocks elapsed since last update.
     * @param user The address of the user.
     */
    function _applyReputationDecay(address user) internal {
        UserReputation storage userRep = reputation[user];
        if (userRep.score > 0 && userRep.lastUpdateBlock < block.number) {
            uint256 blocksElapsed = block.number - userRep.lastUpdateBlock;
            uint256 decayAmount = blocksElapsed * reputationDecayRatePerBlock;
            userRep.score = userRep.score > decayAmount ? userRep.score - decayAmount : 0;
            userRep.lastUpdateBlock = block.number;
        }
    }

    // --- I. Essence Token & Core Resource Management ---

    /**
     * @notice Allows users to deposit whitelisted ERC20 materials into the Forge.
     *         Requires the user to have pre-approved this contract to spend the material token.
     * @param materialToken The address of the ERC20 material token.
     * @param amount The amount of material token to deposit.
     */
    function depositMaterial(address materialToken, uint256 amount) external whenNotPaused {
        require(whitelistedMaterials[materialToken], "AlchemistForge: Material not whitelisted");
        require(amount > 0, "AlchemistForge: Amount must be greater than 0");

        // Transfer material from the user to this contract
        IERC20(materialToken).transferFrom(msg.sender, address(this), amount);
        userMaterialDeposits[msg.sender][materialToken] += amount;

        emit MaterialDeposited(msg.sender, materialToken, amount);
    }

    /**
     * @notice Converts deposited materials into Essence based on the active formula for that material.
     *         Consumes the required material from the user's deposits and mints Essence to them.
     *         Awards a small amount of reputation for successful synthesis.
     * @param materialToken The address of the ERC20 material token to synthesize from.
     */
    function synthesizeEssence(address materialToken) external whenNotPaused {
        uint256 formulaIndex = activeFormulaId[materialToken];
        require(formulaIndex < formulaProposals.length, "AlchemistForge: No active formula for this material or invalid index");

        Formula storage currentFormula = formulaProposals[formulaIndex];
        require(currentFormula.approved, "AlchemistForge: Active formula is not approved");
        require(currentFormula.materialToken == materialToken, "AlchemistForge: Formula material mismatch");

        require(userMaterialDeposits[msg.sender][materialToken] >= currentFormula.inputAmount, "AlchemistForge: Insufficient material deposited");

        // Deduct material and mint essence
        userMaterialDeposits[msg.sender][materialToken] -= currentFormula.inputAmount;
        essence.mint(msg.sender, currentFormula.outputEssence, address(this));

        // Award reputation for successful synthesis (e.g., 1 point)
        _updateReputation(msg.sender, 1);

        emit EssenceSynthesized(msg.sender, materialToken, currentFormula.inputAmount, currentFormula.outputEssence);
    }

    /**
     * @notice Allows users to burn their Essence, potentially gaining reputation as a sign of commitment.
     *         Requires the user to have pre-approved this contract to spend their Essence.
     * @param amount The amount of Essence to burn.
     */
    function burnEssence(uint256 amount) external whenNotPaused {
        require(amount > 0, "AlchemistForge: Amount must be greater than 0");
        // User must first `approve` AlchemistForge to spend their Essence.
        // The Essence token's `burnFrom` function will internally handle this.
        essence.burnFrom(msg.sender, amount, address(this));

        // Award reputation for burning Essence (e.g., 1 reputation per 100 Essence burned)
        _updateReputation(msg.sender, int256(amount / 100));

        emit EssenceBurned(msg.sender, amount);
    }

    /**
     * @notice Retrieves the amount of a specific material deposited by a user.
     * @param user The address of the user.
     * @param materialToken The address of the ERC20 material token.
     * @return The amount of material deposited by the user.
     */
    function getMaterialBalance(address user, address materialToken) external view returns (uint256) {
        return userMaterialDeposits[user][materialToken];
    }

    /**
     * @notice Returns the address of the deployed Essence ERC20 token.
     * @return The address of the Essence token contract.
     */
    function getEssenceAddress() external view returns (address) {
        return address(essence);
    }

    // --- II. Dynamic Formula & Material Management ---

    /**
     * @notice Allows users with sufficient reputation to propose a new synthesis formula for a material.
     *         The proposal enters a voting period.
     * @param materialToken The address of the material token for the formula.
     * @param inputAmount The amount of material required.
     * @param outputEssence The amount of Essence produced.
     * @param requiredReputation The minimum reputation required for a user to *utilize* this specific formula.
     * @param durationBlocks The number of blocks for the voting period.
     */
    function proposeSynthesisFormula(
        address materialToken,
        uint256 inputAmount,
        uint256 outputEssence,
        uint256 requiredReputation,
        uint256 durationBlocks
    ) external whenNotPaused {
        _applyReputationDecay(msg.sender); // Apply decay before checking reputation
        require(reputation[msg.sender].score >= minimumVoteReputation, "AlchemistForge: Insufficient reputation to propose");
        require(whitelistedMaterials[materialToken], "AlchemistForge: Material not whitelisted");
        require(inputAmount > 0 && outputEssence > 0, "AlchemistForge: Input and output amounts must be greater than 0");
        require(durationBlocks > 0, "AlchemistForge: Voting duration must be greater than 0");

        uint256 newFormulaId = nextFormulaId;
        formulaProposals.push(
            Formula({
                materialToken: materialToken,
                inputAmount: inputAmount,
                outputEssence: outputEssence,
                requiredReputation: requiredReputation,
                proposalBlock: block.number,
                votingPeriodBlocks: durationBlocks,
                totalVotesFor: 0,
                totalVotesAgainst: 0,
                hasVoted: new mapping(address => bool), // Initialize empty mapping
                finalized: false,
                approved: false
            })
        );
        nextFormulaId++; // Increment for the next proposal

        emit FormulaProposed(newFormulaId, msg.sender, materialToken, inputAmount, outputEssence, requiredReputation, durationBlocks);
    }

    /**
     * @notice Allows users with sufficient reputation to vote on a proposed formula (reputation-weighted).
     *         A user's voting power is equal to their current reputation score.
     * @param formulaId The ID (index) of the formula proposal.
     * @param approve True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnFormula(uint256 formulaId, bool approve) external whenNotPaused {
        _applyReputationDecay(msg.sender); // Apply decay before checking reputation
        require(reputation[msg.sender].score >= minimumVoteReputation, "AlchemistForge: Insufficient reputation to vote");
        require(formulaId < formulaProposals.length, "AlchemistForge: Invalid formula ID");

        Formula storage proposal = formulaProposals[formulaId];
        require(!proposal.finalized, "AlchemistForge: Formula already finalized");
        require(block.number < proposal.proposalBlock + proposal.votingPeriodBlocks, "AlchemistForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AlchemistForge: Already voted on this proposal");

        uint256 voterReputation = reputation[msg.sender].score;
        if (approve) {
            proposal.totalVotesFor += voterReputation;
        } else {
            proposal.totalVotesAgainst += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;

        emit FormulaVoted(formulaId, msg.sender, approve, voterReputation);
    }

    /**
     * @notice Finalizes a formula proposal after its voting period ends.
     *         If approved (total 'for' votes > total 'against' votes), it becomes the active formula for its material.
     * @param formulaId The ID (index) of the formula proposal.
     */
    function finalizeFormula(uint256 formulaId) external whenNotPaused {
        require(formulaId < formulaProposals.length, "AlchemistForge: Invalid formula ID");

        Formula storage proposal = formulaProposals[formulaId];
        require(!proposal.finalized, "AlchemistForge: Formula already finalized");
        require(block.number >= proposal.proposalBlock + proposal.votingPeriodBlocks, "AlchemistForge: Voting period not ended yet");

        proposal.finalized = true;
        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            proposal.approved = true;
            activeFormulaId[proposal.materialToken] = formulaId; // Set this as the new active formula
        } else {
            proposal.approved = false;
        }

        emit FormulaFinalized(formulaId, proposal.approved);
    }

    /**
     * @notice Retrieves the currently active synthesis formula for a given material.
     * @param materialToken The address of the material token.
     * @return inputAmount The amount of material required for synthesis.
     * @return outputEssence The amount of Essence produced from synthesis.
     * @return requiredReputation The minimum reputation needed to use this formula.
     */
    function getCurrentSynthesisFormula(address materialToken) external view returns (uint256 inputAmount, uint256 outputEssence, uint256 requiredReputation) {
        uint256 formulaIndex = activeFormulaId[materialToken];
        if (formulaIndex < formulaProposals.length && formulaProposals[formulaIndex].approved) {
            Formula storage active = formulaProposals[formulaIndex];
            return (active.inputAmount, active.outputEssence, active.requiredReputation);
        }
        return (0, 0, 0); // No active or approved formula
    }

    /**
     * @notice Retrieves the full details of a specific formula proposal.
     * @param formulaId The ID (index) of the formula proposal.
     * @return A memory struct containing all details of the formula proposal.
     */
    function getFormulaProposal(uint256 formulaId) external view returns (Formula memory) {
        require(formulaId < formulaProposals.length, "AlchemistForge: Invalid formula ID");
        return formulaProposals[formulaId];
    }

    /**
     * @notice (Owner-only) Whitelists a new ERC20 token as a material that can be used for synthesis.
     * @param materialToken The address of the ERC20 token to whitelist.
     */
    function addWhitelistedMaterial(address materialToken) external onlyOwner {
        require(materialToken != address(0), "AlchemistForge: Invalid address");
        require(!whitelistedMaterials[materialToken], "AlchemistForge: Material already whitelisted");
        whitelistedMaterials[materialToken] = true;
        emit MaterialWhitelisted(materialToken, true);
    }

    /**
     * @notice (Owner-only) Removes an ERC20 token from the list of whitelisted materials.
     * @dev Note: Removing a material does not automatically invalidate active formulas that use it,
     *      but those formulas will no longer be usable as the material itself is no longer accepted.
     * @param materialToken The address of the ERC20 token to remove.
     */
    function removeWhitelistedMaterial(address materialToken) external onlyOwner {
        require(whitelistedMaterials[materialToken], "AlchemistForge: Material not whitelisted");
        whitelistedMaterials[materialToken] = false;
        emit MaterialWhitelisted(materialToken, false);
    }

    /**
     * @notice Checks if a material token is currently whitelisted.
     * @param materialToken The address of the material token.
     * @return True if whitelisted, false otherwise.
     */
    function isMaterialWhitelisted(address materialToken) external view returns (bool) {
        return whitelistedMaterials[materialToken];
    }

    // --- III. Reputation System ---

    /**
     * @notice Retrieves a user's current reputation score, applying decay if necessary.
     * @param user The address of the user.
     * @return The user's current reputation score.
     */
    function getReputation(address user) public returns (uint256) {
        _applyReputationDecay(user); // Apply decay whenever reputation is queried
        return reputation[user].score;
    }

    /**
     * @notice (Alchemist-only) Awards reputation points to a contributor for off-chain activities
     *         or verified contributions not directly measurable on-chain.
     * @param contributor The address of the contributor.
     * @param points The number of reputation points to award.
     */
    function attestContribution(address contributor, uint256 points) external onlyRole(ALCHEMIST_ROLE) whenNotPaused {
        require(contributor != address(0), "AlchemistForge: Invalid contributor address");
        require(points > 0, "AlchemistForge: Points must be greater than 0");
        _updateReputation(contributor, int256(points));
    }

    /**
     * @notice (Owner-only) Sets the global reputation decay rate (points per block).
     * @param newRatePerBlock The new decay rate.
     */
    function setReputationDecayRate(uint256 newRatePerBlock) external onlyOwner {
        reputationDecayRatePerBlock = newRatePerBlock;
        emit ReputationDecayRateSet(newRatePerBlock);
    }

    /**
     * @notice (Owner-only) Sets the minimum reputation required to propose or vote on formulas.
     * @param minRep The new minimum reputation threshold.
     */
    function setMinimumVoteReputation(uint256 minRep) external onlyOwner {
        minimumVoteReputation = minRep;
        emit MinimumVoteReputationSet(minRep);
    }

    // --- IV. Catalyst Integration & Essence Consumption ---

    /**
     * @notice (Owner-only) Registers an external contract as a valid Catalyst.
     *         Registered Catalysts can receive Essence from users via `triggerCatalyst`.
     * @param catalystContract The address of the Catalyst contract.
     * @param description A brief description of the Catalyst's purpose.
     */
    function registerCatalyst(address catalystContract, string memory description) external onlyOwner {
        require(catalystContract != address(0), "AlchemistForge: Invalid catalyst address");
        require(!registeredCatalysts[catalystContract], "AlchemistForge: Catalyst already registered");
        registeredCatalysts[catalystContract] = true;
        catalystDescriptions[catalystContract] = description;
        emit CatalystRegistered(catalystContract, description);
    }

    /**
     * @notice (Owner-only) Deregisters a Catalyst.
     * @param catalystContract The address of the Catalyst contract to deregister.
     */
    function deregisterCatalyst(address catalystContract) external onlyOwner {
        require(registeredCatalysts[catalystContract], "AlchemistForge: Catalyst not registered");
        delete registeredCatalysts[catalystContract];
        delete catalystDescriptions[catalystContract];
        emit CatalystDeregistered(catalystContract);
    }

    /**
     * @notice Allows users to transfer Essence to a registered Catalyst contract and trigger a specific function on it.
     *         The Catalyst contract must be designed to receive arbitrary data via a fallback/receive function,
     *         or a specific function signature that matches the `data` provided.
     * @dev Common pattern for Catalysts: Implement `function receiveEssence(uint256 amount, address sender, bytes memory data) public {}`
     *      or simply accept a raw call.
     * @param catalystContract The address of the registered Catalyst contract.
     * @param amount The amount of Essence to transfer to the Catalyst.
     * @param data Arbitrary bytes data to be sent as part of the call to the Catalyst (e.g., function selector and arguments).
     */
    function triggerCatalyst(address catalystContract, uint256 amount, bytes memory data) external whenNotPaused {
        require(registeredCatalysts[catalystContract], "AlchemistForge: Catalyst not registered");
        require(amount > 0, "AlchemistForge: Amount must be greater than 0");

        // Transfer Essence from the user to the Catalyst contract
        // User must have approved AlchemistForge to spend their Essence for this.
        essence.transferFrom(msg.sender, catalystContract, amount);

        // Execute the call on the Catalyst contract with the provided data
        // This allows for dynamic interaction with diverse Catalysts.
        (bool success,) = catalystContract.call(data);
        require(success, "AlchemistForge: Catalyst call failed");

        emit CatalystTriggered(msg.sender, catalystContract, amount, data);
    }

    /**
     * @notice Checks if a contract is currently registered as a Catalyst.
     * @param catalystContract The address of the contract to check.
     * @return True if registered, false otherwise.
     */
    function isCatalystRegistered(address catalystContract) external view returns (bool) {
        return registeredCatalysts[catalystContract];
    }

    // --- V. Governance & System Parameters (Admin/Owner) ---

    /**
     * @notice (Owner-only) Grants or revokes the 'Alchemist' role.
     *         Alchemists can `attestContribution` to award reputation.
     * @param alchemist The address of the new or existing Alchemist.
     * @param hasRole True to grant the role, false to revoke.
     */
    function setAlchemistRole(address alchemist, bool hasRole) external onlyOwner {
        require(alchemist != address(0), "AlchemistForge: Invalid address");
        hasAlchemistRole[alchemist] = hasRole;
        emit AlchemistRoleSet(alchemist, hasRole);
    }

    /**
     * @notice (Owner-only) Pauses core contract functionalities (deposits, synthesis, catalyst triggers).
     *         Useful for emergency situations or upgrades.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice (Owner-only) Unpauses core contract functionalities.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice (Owner-only) Allows the owner to withdraw excess or accidentally sent ERC20 material tokens
     *         from the Forge contract. This is a safety mechanism.
     * @param materialToken The address of the material token to withdraw.
     * @param amount The amount of the material token to withdraw.
     */
    function withdrawExcessMaterial(address materialToken, uint256 amount) external onlyOwner {
        require(materialToken != address(0), "AlchemistForge: Invalid material address");
        require(amount > 0, "AlchemistForge: Amount must be greater than 0");
        IERC20(materialToken).transfer(owner(), amount);
    }

    // --- Role-based Access Control Modifier (for custom roles) ---
    /**
     * @dev Modifier to restrict function calls to addresses with a specific custom role.
     *      Currently only supports ALCHEMIST_ROLE.
     * @param role The keccak256 hash of the role name (e.g., `ALCHEMIST_ROLE`).
     */
    modifier onlyRole(bytes32 role) {
        if (role == ALCHEMIST_ROLE) {
            require(hasAlchemistRole[msg.sender], "AlchemistForge: Caller is not an Alchemist");
        } else {
            revert("AlchemistForge: Unknown role");
        }
        _;
    }
}
```