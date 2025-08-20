Here's a Solidity smart contract for "GaiaGenesis: Eco-Sentient NFTs," incorporating advanced concepts, dynamic features, and a blend of gamification with real-world impact. It aims to avoid direct duplication of common open-source projects by combining unique mechanics.

The contract includes **29 custom functions** (excluding inherited ERC721 basics like `balanceOf`, `ownerOf`, `transferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, which are standard and always present).

---

## Outline: GaiaGenesis - Eco-Sentient NFTs

**Concept:** GaiaGenesis is a decentralized ecosystem centered around "Gaia-Beings," which are unique NFTs representing digital life forms. Their traits, rarity, and well-being are dynamically influenced by on-chain simulated environmental factors and user actions aimed at sustainability. Holders are incentivized to nurture their Gaia-Beings, participate in eco-challenges, and contribute to a community fund that supports real-world environmental initiatives, creating a symbiotic relationship between digital assets and ecological impact.

**Key Innovative Features:**
1.  **Dynamic NFT Traits:** Gaia-Beings possess mutable traits (e.g., health, purity, adaptability) that change based on user interactions and global environmental shifts.
2.  **AI-Driven (Algorithmic) Rarity:** Rarity is not static but a real-time calculation influenced by a Gaia-Being's dynamic traits, its interaction history, and the simulated global environmental health index.
3.  **Eco-Gamification & Pledges:** Users can pledge to perform real-world eco-actions. These pledges can be attested by the community, leading to in-game rewards and a positive feedback loop for their NFTs.
4.  **Decentralized Environmental Fund (EcoFund):** A community-governed fund that collects donations and allocates them to real-world environmental initiatives proposed and voted on by NFT holders.
5.  **Internal Resource Economy (Vitality Points):** A staking mechanism allows users to earn "Vitality Points" (VP), a crucial in-game resource required for nurturing, evolving, and mutating Gaia-Beings.
6.  **Multi-Stage Evolution & Mutation:** Gaia-Beings can evolve through different stages and undergo mutations, adding depth and replayability.

---

## Function Summary:

**I. Core NFT & Ownership:**
*   `mintInitialGaiaBeing()`: Mints a new Gaia-Being NFT to the caller, requiring a ETH payment. Assigns initial health and creation timestamp.
*   `getCurrentBeingState(uint256 tokenId)`: Retrieves all dynamic attributes (health, vitality, evolution stage, mutation count, purity, adaptability, etc.) of a specific Gaia-Being.
*   `tokenURI(uint256 tokenId)`: Generates a dynamic metadata URI for the NFT, reflecting its current on-chain state. This would typically point to an off-chain API for visual representation.

**II. Dynamic Traits & Evolution:**
*   `nurtureGaiaBeing(uint256 tokenId)`: Allows an owner to "nurture" their Gaia-Being, improving its health and vitality by spending Vitality Points.
*   `evolveGaiaBeing(uint256 tokenId)`: Enables a Gaia-Being to evolve to a new form if specific conditions (e.g., health threshold, minimum age) are met, consuming Vitality Points.
*   `mutateGaiaBeing(uint256 tokenId)`: Triggers a random mutation on a Gaia-Being, potentially altering its traits based on a chance factor influenced by environmental conditions and costing Vitality Points.
*   `rejuvenateGaiaBeing(uint256 tokenId)`: Restores a Gaia-Being's health to a higher level, costing Vitality Points.
*   `setDynamicTrait(uint256 tokenId, string memory traitName, uint256 value)`: An internal/admin function to directly update specific dynamic traits of an NFT (e.g., used by complex internal logic or for administrative adjustments).

**III. Environmental Simulation & Rarity:**
*   `simulateGlobalEnvironmentalShift(uint256 newGlobalHealthIndex)`: An admin/oracle function to update the simulated global environmental health index (0-100), influencing all Gaia-Beings' well-being and rarity.
*   `calculateDynamicRarity(uint256 tokenId)`: Computes the real-time rarity score of a Gaia-Being based on its current health, evolution stage, mutation count, specific dynamic traits (purity, adaptability), and the global environmental health.
*   `getGlobalEnvironmentalState()`: Retrieves the current simulated global environmental health index.
*   `updateRarityAlgorithmFactor(uint256 newFactor)`: A DAO-governed function allowing the community to fine-tune a parameter within the dynamic rarity calculation algorithm.

**IV. Eco-Gamification & Impact:**
*   `pledgeEcoAction(string memory actionDetails, uint256 tokenIdForPledge)`: Allows users to formally pledge to perform a real-world eco-friendly action, optionally linking it to a specific Gaia-Being.
*   `attestEcoActionCompletion(uint256 pledgeId)`: Enables other users (or designated validators) to attest to the completion of a pledged eco-action, validating it. A minimum number of attestations might be required.
*   `claimEcoActionReward(uint256 pledgeId)`: Allows pledgers to claim rewards (e.g., Vitality Points) once their eco-action pledge is sufficiently attested.
*   `donateToEcoFund()`: A payable function for anyone to donate Ether directly to the community-managed environmental fund (EcoFund).
*   `proposeEcoInitiative(string memory initiativeDetails, uint256 requestedAmount)`: Allows authorized proposers (e.g., NFT holders or community roles) to suggest real-world environmental projects for funding from the EcoFund.
*   `voteOnEcoInitiative(uint256 initiativeId, bool support)`: Enables Gaia-Being NFT holders to vote on proposed environmental initiatives, with each NFT acting as voting power.
*   `executeEcoInitiativeFunding(uint256 initiativeId)`: Executes the distribution of funds from the EcoFund to a successfully voted-on and approved environmental initiative, callable after the voting period ends and quorum/approval thresholds are met.

**V. Internal Resource & Staking:**
*   `stakeForVitalityPoints(uint256 amount)`: Users stake a specified ERC20 token to passively earn "Vitality Points" over time, increasing their utility within the ecosystem.
*   `claimVitalityPoints()`: Allows stakers to claim their accumulated Vitality Points.
*   `spendVitalityPoints(uint256 amount, string memory purpose)`: A general function for users to spend their Vitality Points for various in-contract actions (e.g., nurturing, evolution, mutation).
*   `unstakeERC20Tokens(uint256 amount)`: Allows users to unstake their previously staked ERC20 tokens and retrieve them.

**VI. Governance & Administration:**
*   `updateDAOParameter(bytes32 paramName, uint256 newValue)`: A generalized function for the DAO (represented by the owner in this example) to update various configurable numerical parameters of the contract (e.g., mint cost, nurture cost, thresholds).
*   `setEcoFundRecipient(address newRecipient)`: Sets the authorized wallet address that can receive funds for approved initiatives from the EcoFund (e.g., a multisig or a dedicated DAO treasury).
*   `togglePledgeVerificationStatus(bool required)`: An admin/DAO function to enable or disable the requirement for external attestation of eco-action pledges (if false, pledges are considered immediately verified).
*   `addEcoInitiativeProposer(address proposerAddress)`: Adds an address to a whitelist of entities allowed to propose eco-initiatives.
*   `removeEcoInitiativeProposer(address proposerAddress)`: Removes an address from the whitelist of eco-initiative proposers.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Outline: GaiaGenesis - Eco-Sentient NFTs
// A collection of NFTs representing digital life forms (Gaia-Beings) whose traits, rarity,
// and well-being are dynamically influenced by on-chain simulated environmental factors
// and user pledges/actions towards sustainability. Holders can nurture their Gaia-Being,
// participate in eco-challenges, and contribute to a community fund for real-world environmental initiatives.

// Function Summary:
// I. Core NFT & Ownership:
//    - `mintInitialGaiaBeing()`: Mints a new Gaia-Being NFT, assigning initial traits.
//    - `getCurrentBeingState(uint256 tokenId)`: Retrieves all dynamic attributes of a specific Gaia-Being.
//    - `tokenURI(uint256 tokenId)`: Generates a dynamic metadata URI for the NFT, reflecting its current state.
//
// II. Dynamic Traits & Evolution:
//    - `nurtureGaiaBeing(uint256 tokenId)`: Allows an owner to "nurture" their Gaia-Being, improving its health and vitality using Vitality Points.
//    - `evolveGaiaBeing(uint256 tokenId)`: Enables a Gaia-Being to evolve to a new form upon meeting conditions, potentially consuming Vitality Points.
//    - `mutateGaiaBeing(uint256 tokenId)`: Triggers a random mutation on a Gaia-Being, influencing its traits based on its current state and global environmental conditions.
//    - `rejuvenateGaiaBeing(uint256 tokenId)`: Restores a Gaia-Being's health or vitality to a higher level, costing Vitality Points.
//    - `setDynamicTrait(uint256 tokenId, string memory traitName, uint256 value)`: Internal/admin function to update specific dynamic traits.
//
// III. Environmental Simulation & Rarity:
//    - `simulateGlobalEnvironmentalShift(uint256 newGlobalHealthIndex)`: Admin/Oracle function to update the simulated global environmental health index, affecting all Gaia-Beings.
//    - `calculateDynamicRarity(uint256 tokenId)`: Computes the real-time rarity score of a Gaia-Being based on its traits, evolution stage, and the global environmental state.
//    - `getGlobalEnvironmentalState()`: Retrieves the current simulated global environmental conditions.
//    - `updateRarityAlgorithmFactor(uint256 newFactor)`: DAO-governed function to fine-tune a parameter within the dynamic rarity calculation algorithm.
//
// IV. Eco-Gamification & Impact:
//    - `pledgeEcoAction(string memory actionDetails, uint256 tokenIdForPledge)`: Allows users to formally pledge to perform a real-world eco-friendly action.
//    - `attestEcoActionCompletion(uint256 pledgeId)`: Enables other users (or designated validators) to attest to the completion of a pledged eco-action, validating it.
//    - `claimEcoActionReward(uint256 pledgeId)`: Allows users to claim rewards after their pledged eco-action is successfully attested.
//    - `donateToEcoFund()`: Facilitates direct Ether donations to a community-managed environmental fund.
//    - `proposeEcoInitiative(string memory initiativeDetails, uint256 requestedAmount)`: Allows authorized proposers (e.g., NFT holders) to suggest real-world environmental projects for funding from the EcoFund.
//    - `voteOnEcoInitiative(uint256 initiativeId, bool support)`: Enables NFT holders to vote on proposed environmental initiatives, using their NFTs as voting power.
//    - `executeEcoInitiativeFunding(uint256 initiativeId)`: Executes the distribution of funds from the EcoFund to a successfully voted-on and approved environmental initiative.
//
// V. Internal Resource & Staking:
//    - `stakeForVitalityPoints(uint256 amount)`: Users stake a specified ERC20 token to passively earn "Vitality Points".
//    - `claimVitalityPoints()`: Users claim accumulated Vitality Points.
//    - `spendVitalityPoints(uint256 amount, string memory purpose)`: Allows spending Vitality Points for various in-contract actions (e.g., nurturing, mutation).
//    - `unstakeERC20Tokens(uint256 amount)`: Allows users to unstake their previously staked ERC20 tokens.
//
// VI. Governance & Administration:
//    - `updateDAOParameter(bytes32 paramName, uint256 newValue)`: A general DAO function to update various configurable numerical parameters of the contract.
//    - `setEcoFundRecipient(address newRecipient)`: Sets the authorized wallet address that can receive funds for approved initiatives from the EcoFund (e.g., a multisig).
//    - `togglePledgeVerificationStatus(bool required)`: Admin/DAO function to enable or disable attestation requirements for eco-actions.
//    - `addEcoInitiativeProposer(address proposerAddress)`: Adds an address to the whitelist of eco-initiative proposers.
//    - `removeEcoInitiativeProposer(address proposerAddress)`: Removes an address from the whitelist of eco-initiative proposers.

contract GaiaGenesis is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIdCounter;

    // --- Core NFT Data Structures ---
    struct GaiaBeing {
        uint256 creationTime;
        uint256 lastInteractionTime;
        uint256 health; // 0-100, impacts rarity and evolution
        uint256 vitality; // Internal resource for this specific being, distinct from global Vitality Points
        uint256 evolutionStage; // 1, 2, 3...
        uint256 mutationCount; // How many times it has mutated
        mapping(bytes32 => uint256) dynamicTraits; // Generic dynamic traits (e.g., 'purity', 'adaptability')
    }
    mapping(uint256 => GaiaBeing) public gaiaBeings;

    // --- Environmental Simulation & Rarity ---
    uint256 public globalEnvironmentalHealthIndex; // 0-100, 100 is pristine
    uint256 public rarityAlgorithmFactor = 100; // Factor for rarity calculation, adjustable by DAO

    // --- Eco-Gamification & Impact ---
    struct EcoPledge {
        address pledger;
        string details;
        uint256 pledgedTime;
        bool isAttested;
        uint256 attestationsReceived; // Number of attestations received
        bool isClaimed;
        uint256 tokenIdAssociated; // Which NFT this pledge is for, optional
    }
    Counters.Counter private _ecoPledgeIdCounter;
    mapping(uint256 => EcoPledge) public ecoPledges;
    mapping(uint256 => mapping(address => bool)) public pledgeAttestedBy; // pledgeId => attesterAddress => bool
    uint256 public constant MIN_ATTESTATIONS_FOR_REWARD = 3;
    bool public ecoPledgeVerificationRequired = true; // Toggle for requiring attestations

    address public ecoFundRecipient; // Address to send funds for approved initiatives
    mapping(address => bool) public isEcoInitiativeProposer; // Addresses allowed to propose initiatives

    struct EcoInitiative {
        string details;
        uint256 requestedAmount;
        address proposer;
        uint256 proposalTime;
        bool isApproved;
        bool isExecuted;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(uint256 => bool) hasVoted; // tokenId => true if voted
    }
    Counters.Counter private _ecoInitiativeIdCounter;
    mapping(uint256 => EcoInitiative) public ecoInitiatives;
    uint256 public constant MIN_VOTES_FOR_APPROVAL_PERCENT = 60; // 60% approval needed
    uint256 public voteDuration = 7 days; // Duration for voting on initiatives

    // --- Internal Resource (Vitality Points) & Staking ---
    IERC20 public stakeToken; // The ERC20 token users stake
    uint256 public vitalityPointsPerTokenPerSecond = 100; // Scaled value: e.g., 100 means 0.01 VP per token per second
    uint256 public constant VP_DECIMALS = 18; // Vitality Points use 18 decimals for precision

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastClaimTime;
        uint256 unclaimedPoints;
    }
    mapping(address => StakerInfo) public stakers;
    mapping(address => uint256) public userVitalityPoints; // User's spendable Vitality Points balance

    // --- DAO & Configurable Parameters ---
    mapping(bytes32 => uint256) public daoParameters; // Flexible DAO-controlled parameters

    // Events
    event GaiaBeingMinted(uint256 indexed tokenId, address indexed owner, uint256 initialHealth);
    event GaiaBeingNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 newHealth, uint256 vitalitySpent);
    event GaiaBeingEvolved(uint256 indexed tokenId, uint256 newStage);
    event GaiaBeingMutated(uint256 indexed tokenId, uint256 mutationType);
    event GlobalEnvironmentalShift(uint256 newIndex);
    event EcoPledgeMade(uint256 indexed pledgeId, address indexed pledger, string details);
    event EcoActionAttested(uint256 indexed pledgeId, address indexed attester, uint256 currentAttestations);
    event EcoActionRewardClaimed(uint256 indexed pledgeId, address indexed pledger, uint256 amount);
    event DonationToEcoFund(address indexed donor, uint256 amount);
    event EcoInitiativeProposed(uint256 indexed initiativeId, address indexed proposer, uint256 requestedAmount);
    event EcoInitiativeVoted(uint256 indexed initiativeId, uint256 indexed tokenId, bool support);
    event EcoInitiativeExecuted(uint256 indexed initiativeId, uint256 amount);
    event TokensStaked(address indexed staker, uint256 amount);
    event VitalityPointsClaimed(address indexed staker, uint256 amount);
    event VitalityPointsSpent(address indexed spender, uint256 amount, string purpose);
    event TokensUnstaked(address indexed staker, uint256 amount);
    event DAOParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event EcoFundRecipientSet(address indexed newRecipient);


    constructor(address _stakeTokenAddress, address _ecoFundRecipient)
        ERC721("GaiaGenesis", "GAIA")
        Ownable(msg.sender)
    {
        stakeToken = IERC20(_stakeTokenAddress);
        ecoFundRecipient = _ecoFundRecipient;

        // Initialize some DAO parameters (can be updated later by DAO)
        daoParameters[keccak256("mintCost")] = 0.01 ether; // Example mint cost in ETH
        daoParameters[keccak256("nurtureCostVP")] = 100 * (10**VP_DECIMALS); // 100 VP
        daoParameters[keccak256("evolveCostVP")] = 500 * (10**VP_DECIMALS); // 500 VP
        daoParameters[keccak256("rejuvenateCostVP")] = 200 * (10**VP_DECIMALS); // 200 VP
        daoParameters[keccak256("initialHealth")] = 50; // Initial health for new Gaia-Beings
        daoParameters[keccak256("maxHealth")] = 100; // Max health for Gaia-Beings
        daoParameters[keccak256("pledgeRewardVP")] = 500 * (10**VP_DECIMALS); // 500 VP reward for attested pledges
        daoParameters[keccak256("mutationChance")] = 10; // 10% chance of mutation (out of 100)
        daoParameters[keccak256("evolveHealthThreshold")] = 80; // Health needed to evolve
        daoParameters[keccak256("minAgeToEvolve")] = 30 days; // Minimum age in seconds to evolve
        daoParameters[keccak256("votingQuorumPct")] = 10; // 10% of total supply needed for quorum
        daoParameters[keccak256("minVoteThreshold")] = 1; // Minimum votes for an initiative (in case of very small supply)

        // Set initial global environmental state
        globalEnvironmentalHealthIndex = 75; // Starting with a decent state (0-100)
    }

    // --- Modifiers ---
    modifier onlyEcoInitiativeProposer() {
        require(isEcoInitiativeProposer[msg.sender], "Not an authorized proposer");
        _;
    }

    // This modifier represents a DAO in a simplified manner.
    // In a full DAO implementation, this would check against a governance contract
    // that verifies a passed proposal or multisig signature.
    modifier onlyDAO() {
        require(owner() == msg.sender, "Caller is not the DAO (or owner in this example)");
        _;
    }

    // --- I. Core NFT & Ownership ---

    /**
     * @notice Mints a new Gaia-Being NFT to the caller.
     * @dev Requires a mint cost to be paid in ETH. Assigns initial health and sets creation time.
     */
    function mintInitialGaiaBeing() public payable nonReentrant {
        uint256 mintCost = daoParameters[keccak256("mintCost")];
        require(msg.value >= mintCost, "Insufficient ETH for minting");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);

        gaiaBeings[newItemId] = GaiaBeing({
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            health: daoParameters[keccak256("initialHealth")],
            vitality: 0, // Individual GaiaBeing vitality, not user's VP
            evolutionStage: 1,
            mutationCount: 0
        });

        // Initialize some default dynamic traits (e.g., 'purity', 'adaptability')
        gaiaBeings[newItemId].dynamicTraits[keccak256("purity")] = 50;
        gaiaBeings[newItemId].dynamicTraits[keccak256("adaptability")] = 50;

        emit GaiaBeingMinted(newItemId, msg.sender, gaiaBeings[newItemId].health);

        // Refund any excess ETH
        if (msg.value > mintCost) {
            payable(msg.sender).transfer(msg.value - mintCost);
        }
    }

    /**
     * @notice Retrieves all dynamic attributes of a specific Gaia-Being.
     * @param tokenId The ID of the Gaia-Being NFT.
     * @return health Current health of the being.
     * @return vitality Current individual vitality of the being.
     * @return evolutionStage Current evolution stage.
     * @return mutationCount Number of mutations.
     * @return creationTime Timestamp of creation.
     * @return lastInteractionTime Timestamp of last user interaction.
     * @return purityTrait Value of the 'purity' dynamic trait.
     * @return adaptabilityTrait Value of the 'adaptability' dynamic trait.
     */
    function getCurrentBeingState(uint256 tokenId)
        public
        view
        returns (
            uint256 health,
            uint256 vitality,
            uint256 evolutionStage,
            uint256 mutationCount,
            uint256 creationTime,
            uint256 lastInteractionTime,
            uint256 purityTrait,
            uint256 adaptabilityTrait
        )
    {
        require(_exists(tokenId), "GaiaBeing does not exist");
        GaiaBeing storage being = gaiaBeings[tokenId];
        return (
            being.health,
            being.vitality,
            being.evolutionStage,
            being.mutationCount,
            being.creationTime,
            being.lastInteractionTime,
            being.dynamicTraits[keccak256("purity")],
            being.dynamicTraits[keccak256("adaptability")]
        );
    }

    /**
     * @notice Generates a dynamic metadata URI for the NFT, reflecting its current state.
     * @dev This is a placeholder; in a real dapp, this would point to an API that generates
     *      JSON metadata and potentially an SVG image based on the on-chain data.
     * @param tokenId The ID of the Gaia-Being NFT.
     * @return A data URI or HTTP/HTTPS URI for the NFT's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        GaiaBeing storage being = gaiaBeings[tokenId];
        uint256 purity = being.dynamicTraits[keccak256("purity")];
        uint256 adaptability = being.dynamicTraits[keccak256("adaptability")];

        // This is a simplified base64-encoded JSON. In a real project,
        // this would be served by an off-chain API with richer visuals.
        string memory json = string.
            // solhint-disable-next-line
            concat(
                '{"name": "Gaia-Being #',
                tokenId.toString(),
                '", "description": "A dynamic eco-sentient being. Its state is influenced by global environmental health and user actions.", ',
                '"image": "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iI2U2ZTZlNiIvPjxjaXJjbGUgY3g9IjEwMCIgY3k9IjEwMCIgcj0iNTAiIGZpbGw9IiM',
                Base64.toHexColor(being.health, being.evolutionStage), // Example: Dynamic color based on health/evolution
                'Ii8+PHRleHQgeD0iMTAwIiB5PSIxMDUiIGZvbnQtZmFtaWx5PSJzYW5zLXNlcmlmIiBmb250LXNpemU9IjEyIiBmaWxsPSJ3aGl0ZSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+S:' ,
                being.health.toString(), ', E:', being.evolutionStage.toString(), '</dGV4dD48L3N2Zz4=', // Simplified SVG with dynamic color and text
                '", "attributes": [',
                '{"trait_type": "Health", "value": "',
                being.health.toString(),
                '"},',
                '{"trait_type": "Evolution Stage", "value": "',
                being.evolutionStage.toString(),
                '"},',
                '{"trait_type": "Mutation Count", "value": "',
                being.mutationCount.toString(),
                '"},',
                '{"trait_type": "Purity", "value": "',
                purity.toString(),
                '"},',
                '{"trait_type": "Adaptability", "value": "',
                adaptability.toString(),
                '"},',
                '{"trait_type": "Global Health Index", "value": "',
                globalEnvironmentalHealthIndex.toString(),
                '"}',
                ']}'
            );

        string memory baseURI = "data:application/json;base64,";
        bytes memory encoded = Base64.encode(bytes(json));
        return string(abi.encodePacked(baseURI, encoded));
    }


    // --- II. Dynamic Traits & Evolution ---

    /**
     * @notice Allows an owner to "nurture" their Gaia-Being, improving its health.
     * @dev Costs Vitality Points. Improves health up to a maximum.
     * @param tokenId The ID of the Gaia-Being to nurture.
     */
    function nurtureGaiaBeing(uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to nurture this GaiaBeing");
        uint256 costVP = daoParameters[keccak256("nurtureCostVP")];
        require(userVitalityPoints[msg.sender] >= costVP, "Insufficient Vitality Points");

        GaiaBeing storage being = gaiaBeings[tokenId];
        uint256 maxHealth = daoParameters[keccak256("maxHealth")];
        require(being.health < maxHealth, "GaiaBeing is already at max health");

        _spendVitalityPoints(msg.sender, costVP, "Nurture");
        being.health = Math.min(being.health + 5, maxHealth); // Increase health by 5 points
        being.lastInteractionTime = block.timestamp;

        emit GaiaBeingNurtured(tokenId, msg.sender, being.health, costVP);
    }

    /**
     * @notice Enables a Gaia-Being to evolve to a new form.
     * @dev Requires certain health, age, and costs Vitality Points.
     * @param tokenId The ID of the Gaia-Being to evolve.
     */
    function evolveGaiaBeing(uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to evolve this GaiaBeing");
        GaiaBeing storage being = gaiaBeings[tokenId];

        uint256 evolveCostVP = daoParameters[keccak256("evolveCostVP")];
        uint256 evolveHealthThreshold = daoParameters[keccak256("evolveHealthThreshold")];
        uint256 minAgeToEvolve = daoParameters[keccak256("minAgeToEvolve")];

        require(userVitalityPoints[msg.sender] >= evolveCostVP, "Insufficient Vitality Points");
        require(being.health >= evolveHealthThreshold, "Health too low to evolve");
        require(block.timestamp - being.creationTime >= minAgeToEvolve, "GaiaBeing is too young to evolve");

        _spendVitalityPoints(msg.sender, evolveCostVP, "Evolve");
        being.evolutionStage += 1;
        being.health = Math.min(being.health + 10, daoParameters[keccak256("maxHealth")]); // Minor health boost
        being.lastInteractionTime = block.timestamp;

        emit GaiaBeingEvolved(tokenId, being.evolutionStage);
    }

    /**
     * @notice Triggers a random mutation on a Gaia-Being.
     * @dev Chance of mutation is influenced by global environmental health and internal logic.
     *      Can affect various dynamic traits. Costs Vitality Points.
     * @param tokenId The ID of the Gaia-Being to mutate.
     */
    function mutateGaiaBeing(uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to mutate this GaiaBeing");
        uint256 costVP = daoParameters[keccak256("rejuvenateCostVP")]; // Using rejuvenate cost as a proxy
        require(userVitalityPoints[msg.sender] >= costVP, "Insufficient Vitality Points");

        GaiaBeing storage being = gaiaBeings[tokenId];
        uint256 mutationChance = daoParameters[keccak256("mutationChance")]; // e.g., 10 for 10%
        // Using block properties for pseudo-randomness. For production, consider Chainlink VRF.
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, tokenId, block.difficulty))) % 100;

        // Mutation is more likely if environmental health is low, or by chance
        if (randomValue < mutationChance || globalEnvironmentalHealthIndex < 30) {
            // Apply a random mutation
            uint256 mutationType = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tokenId))) % 3; // 0=health, 1=purity, 2=adaptability

            if (mutationType == 0) { // Affect health
                being.health = Math.min(Math.max(being.health + (randomValue % 10) - 5, 1), daoParameters[keccak256("maxHealth")]); // +/- 5 health
            } else if (mutationType == 1) { // Affect purity
                uint256 purity = being.dynamicTraits[keccak256("purity")];
                being.dynamicTraits[keccak256("purity")] = Math.min(Math.max(purity + (randomValue % 20) - 10, 0), 100); // +/- 10 purity
            } else { // Affect adaptability
                uint256 adaptability = being.dynamicTraits[keccak256("adaptability")];
                being.dynamicTraits[keccak256("adaptability")] = Math.min(Math.max(adaptability + (randomValue % 20) - 10, 0), 100); // +/- 10 adaptability
            }
            being.mutationCount++;
            _spendVitalityPoints(msg.sender, costVP, "Mutate");
            emit GaiaBeingMutated(tokenId, mutationType);
        } else {
            // No mutation, refund cost or return
            revert("No mutation occurred, try again later or under different conditions");
        }
        being.lastInteractionTime = block.timestamp;
    }

    /**
     * @notice Restores a Gaia-Being's health or vitality to a higher level.
     * @dev Costs Vitality Points.
     * @param tokenId The ID of the Gaia-Being to rejuvenate.
     */
    function rejuvenateGaiaBeing(uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to rejuvenate this GaiaBeing");
        uint256 costVP = daoParameters[keccak256("rejuvenateCostVP")];
        require(userVitalityPoints[msg.sender] >= costVP, "Insufficient Vitality Points");

        GaiaBeing storage being = gaiaBeings[tokenId];
        uint256 maxHealth = daoParameters[keccak256("maxHealth")];
        require(being.health < maxHealth, "GaiaBeing is already at max health");

        _spendVitalityPoints(msg.sender, costVP, "Rejuvenate");
        being.health = Math.min(being.health + 15, maxHealth); // Restore health by 15 points
        being.lastInteractionTime = block.timestamp;

        emit GaiaBeingNurtured(tokenId, msg.sender, being.health, costVP); // Re-use nurture event
    }

    /**
     * @notice Internal function to update specific dynamic traits. Accessible by owner for admin purposes or internal logic.
     * @dev This function could be called internally by other mechanics (e.g., evolution, environmental shifts).
     *      Exposed as owner-only for testing/admin, but a real system would have more complex triggers.
     * @param tokenId The ID of the Gaia-Being.
     * @param traitName The name of the trait (e.g., "purity", "adaptability").
     * @param value The new value for the trait.
     */
    function setDynamicTrait(uint256 tokenId, string memory traitName, uint256 value) public onlyOwner {
        require(_exists(tokenId), "GaiaBeing does not exist");
        bytes32 traitKey = keccak256(abi.encodePacked(traitName));
        gaiaBeings[tokenId].dynamicTraits[traitKey] = value;
        // Consider emitting an event for trait changes if this is frequently updated externally
    }

    // --- III. Environmental Simulation & Rarity ---

    /**
     * @notice Admin/Oracle function to update the simulated global environmental health index.
     * @dev This simulates external events affecting all Gaia-Beings.
     * @param newGlobalHealthIndex The new value for the global environmental health index (0-100).
     */
    function simulateGlobalEnvironmentalShift(uint256 newGlobalHealthIndex) public onlyOwner {
        require(newGlobalHealthIndex <= 100, "Health index cannot exceed 100");
        globalEnvironmentalHealthIndex = newGlobalHealthIndex;
        emit GlobalEnvironmentalShift(newGlobalHealthIndex);

        // Potentially trigger health degradation/boost for all NFTs based on this shift
        // (This would be in a separate, more complex, iterated function or off-chain process for gas efficiency)
    }

    /**
     * @notice Computes the real-time rarity score of a Gaia-Being.
     * @dev Rarity is a dynamic calculation based on health, evolution stage, and global environmental health.
     * @param tokenId The ID of the Gaia-Being NFT.
     * @return The calculated rarity score (higher is rarer).
     */
    function calculateDynamicRarity(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "GaiaBeing does not exist");
        GaiaBeing storage being = gaiaBeings[tokenId];

        uint256 healthFactor = being.health; // Directly contributes to rarity
        uint256 evolutionFactor = being.evolutionStage * 50; // Higher stages significantly increase rarity
        uint256 mutationFactor = being.mutationCount * 10; // Mutations add some rarity
        uint256 purityFactor = being.dynamicTraits[keccak256("purity")];
        uint256 adaptabilityFactor = being.dynamicTraits[keccak256("adaptability")];

        // Global environment impact: A pristine environment makes 'pure' beings rarer,
        // a degraded environment makes 'adaptable' beings rarer.
        uint256 environmentImpact = 0;
        if (globalEnvironmentalHealthIndex > 75) { // Good environment
            environmentImpact = purityFactor * (globalEnvironmentalHealthIndex / 10);
        } else if (globalEnvironmentalHealthIndex < 25) { // Bad environment
            environmentImpact = adaptabilityFactor * ((100 - globalEnvironmentalHealthIndex) / 10);
        } else { // Neutral environment
            environmentImpact = (purityFactor + adaptabilityFactor) / 2;
        }

        uint256 baseRarity = (healthFactor + evolutionFactor + mutationFactor + environmentImpact + rarityAlgorithmFactor);
        
        // Add a time-decay or activity-boost component
        uint256 timeSinceLastInteraction = block.timestamp - being.lastInteractionTime;
        if (timeSinceLastInteraction < 7 days) { // Recently interacted, slight boost
            baseRarity += 5;
        } else if (timeSinceLastInteraction > 30 days) { // Inactive, slight penalty
            baseRarity = baseRarity > 10 ? baseRarity - 10 : 0;
        }

        return baseRarity;
    }

    /**
     * @notice Retrieves the current simulated global environmental health index.
     * @return The current global environmental health index (0-100).
     */
    function getGlobalEnvironmentalState() public view returns (uint256) {
        return globalEnvironmentalHealthIndex;
    }

    /**
     * @notice DAO-governed function to fine-tune a parameter within the dynamic rarity calculation algorithm.
     * @param newFactor The new value for the rarity algorithm factor.
     */
    function updateRarityAlgorithmFactor(uint256 newFactor) public onlyDAO {
        rarityAlgorithmFactor = newFactor;
        emit DAOParameterUpdated(keccak256("rarityAlgorithmFactor"), newFactor);
    }

    // --- IV. Eco-Gamification & Impact ---

    /**
     * @notice Allows users to formally pledge to perform a real-world eco-friendly action.
     * @param actionDetails A string describing the pledged action (e.g., "planted 5 trees", "reduced carbon footprint by 10%").
     * @param tokenIdForPledge Optional: The ID of the Gaia-Being NFT associated with this pledge. 0 if not linked.
     */
    function pledgeEcoAction(string memory actionDetails, uint256 tokenIdForPledge) public nonReentrant {
        if (tokenIdForPledge != 0) {
            require(_exists(tokenIdForPledge), "Associated GaiaBeing does not exist");
            require(_isApprovedOrOwner(msg.sender, tokenIdForPledge), "Not owner/approved for this GaiaBeing");
        }
        
        _ecoPledgeIdCounter.increment();
        uint256 newPledgeId = _ecoPledgeIdCounter.current();

        ecoPledges[newPledgeId] = EcoPledge({
            pledger: msg.sender,
            details: actionDetails,
            pledgedTime: block.timestamp,
            isAttested: !ecoPledgeVerificationRequired, // Auto-attest if verification is disabled
            attestationsReceived: !ecoPledgeVerificationRequired ? MIN_ATTESTATIONS_FOR_REWARD : 0,
            isClaimed: false,
            tokenIdAssociated: tokenIdForPledge
        });

        emit EcoPledgeMade(newPledgeId, msg.sender, actionDetails);
    }

    /**
     * @notice Enables other users (or designated validators) to attest to the completion of a pledged eco-action.
     * @dev A certain number of attestations are required for a pledge to be considered verified.
     * @param pledgeId The ID of the eco-action pledge to attest.
     */
    function attestEcoActionCompletion(uint256 pledgeId) public nonReentrant {
        EcoPledge storage pledge = ecoPledges[pledgeId];
        require(pledge.pledger != address(0), "Pledge does not exist");
        require(pledge.pledger != msg.sender, "Cannot attest your own pledge");
        require(!pledgeAttestedBy[pledgeId][msg.sender], "Already attested this pledge");
        require(!pledge.isAttested, "Pledge already fully attested");
        require(ecoPledgeVerificationRequired, "Pledge verification is currently disabled");

        pledgeAttestedBy[pledgeId][msg.sender] = true;
        pledge.attestationsReceived++;

        if (pledge.attestationsReceived >= MIN_ATTESTATIONS_FOR_REWARD) {
             pledge.isAttested = true;
        }

        emit EcoActionAttested(pledgeId, msg.sender, pledge.attestationsReceived);
    }

    /**
     * @notice Allows users to claim rewards after their pledged eco-action is successfully attested.
     * @param pledgeId The ID of the eco-action pledge to claim rewards for.
     */
    function claimEcoActionReward(uint256 pledgeId) public nonReentrant {
        EcoPledge storage pledge = ecoPledges[pledgeId];
        require(pledge.pledger == msg.sender, "Only pledger can claim reward");
        require(pledge.isAttested, "Pledge not yet attested or verification required"); // Must be attested
        require(!pledge.isClaimed, "Reward already claimed for this pledge");

        pledge.isClaimed = true;
        uint256 rewardAmountVP = daoParameters[keccak256("pledgeRewardVP")];
        userVitalityPoints[msg.sender] += rewardAmountVP;

        // Optionally, boost associated GaiaBeing
        if (pledge.tokenIdAssociated != 0 && _exists(pledge.tokenIdAssociated)) {
            GaiaBeing storage being = gaiaBeings[pledge.tokenIdAssociated];
            being.health = Math.min(being.health + 2, daoParameters[keccak256("maxHealth")]); // Small health boost
            being.dynamicTraits[keccak256("purity")] = Math.min(being.dynamicTraits[keccak256("purity")] + 1, 100);
            being.lastInteractionTime = block.timestamp;
        }

        emit VitalityPointsClaimed(msg.sender, rewardAmountVP);
        emit EcoActionRewardClaimed(pledgeId, msg.sender, rewardAmountVP);
    }

    /**
     * @notice Facilitates direct Ether donations to a community-managed environmental fund.
     */
    function donateToEcoFund() public payable nonReentrant {
        require(msg.value > 0, "Donation amount must be greater than zero");
        emit DonationToEcoFund(msg.sender, msg.value);
    }

    /**
     * @notice Allows authorized proposers (e.g., NFT holders) to suggest real-world environmental projects for funding.
     * @param initiativeDetails A description of the environmental initiative.
     * @param requestedAmount The amount of Ether requested from the EcoFund.
     */
    function proposeEcoInitiative(string memory initiativeDetails, uint256 requestedAmount) public nonReentrant onlyEcoInitiativeProposer {
        require(requestedAmount > 0, "Requested amount must be greater than zero");

        _ecoInitiativeIdCounter.increment();
        uint256 newInitiativeId = _ecoInitiativeIdCounter.current();

        ecoInitiatives[newInitiativeId] = EcoInitiative({
            details: initiativeDetails,
            requestedAmount: requestedAmount,
            proposer: msg.sender,
            proposalTime: block.timestamp,
            isApproved: false,
            isExecuted: false,
            votesFor: 0,
            votesAgainst: 0
        });

        emit EcoInitiativeProposed(newInitiativeId, msg.sender, requestedAmount);
    }

    /**
     * @notice Enables NFT holders to vote on proposed environmental initiatives, using their NFTs as voting power.
     * @param initiativeId The ID of the initiative to vote on.
     * @param support True for 'for', false for 'against'.
     */
    function voteOnEcoInitiative(uint256 initiativeId, bool support) public nonReentrant {
        EcoInitiative storage initiative = ecoInitiatives[initiativeId];
        require(initiative.proposer != address(0), "Initiative does not exist");
        require(!initiative.isApproved && !initiative.isExecuted, "Voting for this initiative has ended or already executed");
        require(block.timestamp <= initiative.proposalTime + voteDuration, "Voting period has ended");

        uint256 totalNFTsOwned = balanceOf(msg.sender);
        require(totalNFTsOwned > 0, "Must own at least one GaiaBeing to vote");

        // Simple voting: each NFT counts as 1 vote
        // Iterate through owned tokens to ensure each NFT votes only once
        for (uint256 i = 0; i < totalNFTsOwned; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i); // Assumes OpenZeppelin's Enumerable ERC721
            if (!initiative.hasVoted[tokenId]) {
                if (support) {
                    initiative.votesFor++;
                } else {
                    initiative.votesAgainst++;
                }
                initiative.hasVoted[tokenId] = true;
                emit EcoInitiativeVoted(initiativeId, tokenId, support);
            }
        }
    }

    /**
     * @notice Executes the distribution of funds from the EcoFund to a successfully voted-on and approved environmental initiative.
     * @dev Only callable after voting period ends and sufficient votes are accumulated.
     * @param initiativeId The ID of the initiative to execute.
     */
    function executeEcoInitiativeFunding(uint256 initiativeId) public nonReentrant {
        EcoInitiative storage initiative = ecoInitiatives[initiativeId];
        require(initiative.proposer != address(0), "Initiative does not exist");
        require(!initiative.isExecuted, "Initiative already executed");
        require(block.timestamp > initiative.proposalTime + voteDuration, "Voting period has not ended");

        uint256 totalVotes = initiative.votesFor + initiative.votesAgainst;
        uint256 totalGaiaBeings = _tokenIdCounter.current(); // Total minted NFTs
        uint256 votingQuorum = (totalGaiaBeings * daoParameters[keccak256("votingQuorumPct")]) / 100;

        require(totalVotes >= votingQuorum || totalVotes >= daoParameters[keccak256("minVoteThreshold")], "Voting quorum or minimum vote threshold not met");

        uint256 approvalPercentage = (initiative.votesFor * 100) / totalVotes;
        require(approvalPercentage >= MIN_VOTES_FOR_APPROVAL_PERCENT, "Initiative did not reach approval threshold");

        require(address(this).balance >= initiative.requestedAmount, "Insufficient funds in EcoFund");

        initiative.isApproved = true;
        initiative.isExecuted = true;
        // Funds are sent to the designated ecoFundRecipient, not directly to the proposer, for security/accountability.
        // The proposer is effectively managing the project, but the funds go to a vetted multisig/DAO address.
        payable(ecoFundRecipient).transfer(initiative.requestedAmount); 

        emit EcoInitiativeExecuted(initiativeId, initiative.requestedAmount);
    }

    // --- V. Internal Resource & Staking ---

    /**
     * @notice Users stake a specified ERC20 token to passively earn "Vitality Points".
     * @param amount The amount of ERC20 tokens to stake.
     */
    function stakeForVitalityPoints(uint256 amount) public nonReentrant {
        require(amount > 0, "Stake amount must be greater than zero");
        
        // Before new stake, calculate and add any pending Vitality Points
        _calculateAndAddVitalityPoints(msg.sender);

        // Transfer tokens from user to contract
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        StakerInfo storage staker = stakers[msg.sender];
        staker.stakedAmount += amount;
        staker.lastClaimTime = block.timestamp; // Reset last claim time after adding stake
        
        emit TokensStaked(msg.sender, amount);
    }

    /**
     * @notice Allows users to claim their accumulated Vitality Points earned from staking.
     */
    function claimVitalityPoints() public nonReentrant {
        _calculateAndAddVitalityPoints(msg.sender); // Calculate all pending points

        uint256 claimedAmount = stakers[msg.sender].unclaimedPoints;
        require(claimedAmount > 0, "No Vitality Points to claim");
        
        userVitalityPoints[msg.sender] += claimedAmount;
        stakers[msg.sender].unclaimedPoints = 0;
        stakers[msg.sender].lastClaimTime = block.timestamp; // Update last claim time after successful claim

        emit VitalityPointsClaimed(msg.sender, claimedAmount);
    }

    /**
     * @notice Internal helper function to calculate and add Vitality Points for a staker.
     * @param stakerAddress The address of the staker.
     */
    function _calculateAndAddVitalityPoints(address stakerAddress) internal {
        StakerInfo storage staker = stakers[stakerAddress];
        if (staker.stakedAmount == 0) return;

        uint256 timeElapsed = block.timestamp - staker.lastClaimTime;
        if (timeElapsed == 0) return;

        // Calculate new points. Use 10**VP_DECIMALS for scaling if vitalityPointsPerTokenPerSecond is a base unit.
        // Assuming vitalityPointsPerTokenPerSecond is already scaled correctly (e.g., 100 means 0.01 with 18 decimals)
        uint256 newPoints = (staker.stakedAmount * vitalityPointsPerTokenPerSecond * timeElapsed) / (10**VP_DECIMALS);
        staker.unclaimedPoints += newPoints;
        staker.lastClaimTime = block.timestamp;
    }

    /**
     * @notice Allows spending Vitality Points for various in-contract actions.
     * @dev This function is called internally by other functions like `nurtureGaiaBeing`, etc.
     * @param amount The amount of Vitality Points to spend.
     * @param purpose A string describing the purpose of the spend (e.g., "Nurture", "Mutation").
     */
    function _spendVitalityPoints(address _spender, uint256 amount, string memory purpose) internal {
        require(userVitalityPoints[_spender] >= amount, "Insufficient Vitality Points");
        userVitalityPoints[_spender] -= amount;
        emit VitalityPointsSpent(_spender, amount, purpose);
    }

    /**
     * @notice Public wrapper for spending Vitality Points (e.g., for future features).
     */
    function spendVitalityPoints(uint256 amount, string memory purpose) public {
        _spendVitalityPoints(msg.sender, amount, purpose);
    }

    /**
     * @notice Allows users to unstake their previously staked ERC20 tokens.
     * @param amount The amount of ERC20 tokens to unstake.
     */
    function unstakeERC20Tokens(uint256 amount) public nonReentrant {
        StakerInfo storage staker = stakers[msg.sender];
        require(staker.stakedAmount >= amount, "Insufficient staked amount");

        _calculateAndAddVitalityPoints(msg.sender); // Claim any pending VP before unstaking

        staker.stakedAmount -= amount;
        stakeToken.safeTransfer(msg.sender, amount);

        emit TokensUnstaked(msg.sender, amount);
    }

    // --- VI. Governance & Administration ---

    /**
     * @notice A general function for the DAO to update various configurable numerical parameters.
     * @dev Only callable by the DAO (or owner as placeholder). Uses bytes32 for parameter names.
     * @param paramName The keccak256 hash of the parameter name (e.g., keccak256("mintCost")).
     * @param newValue The new value for the parameter.
     */
    function updateDAOParameter(bytes32 paramName, uint256 newValue) public onlyDAO {
        daoParameters[paramName] = newValue;
        emit DAOParameterUpdated(paramName, newValue);
    }

    /**
     * @notice Sets the authorized wallet address that can receive funds for approved initiatives from the EcoFund.
     * @dev Only callable by the DAO (or owner as placeholder). This could be a multisig or a dedicated DAO treasury.
     * @param newRecipient The new address for the EcoFund recipient.
     */
    function setEcoFundRecipient(address newRecipient) public onlyDAO {
        require(newRecipient != address(0), "Recipient cannot be zero address");
        ecoFundRecipient = newRecipient;
        emit EcoFundRecipientSet(newRecipient);
    }

    /**
     * @notice Admin/DAO function to enable or disable the requirement for external attestation of eco-action pledges.
     * @dev If disabled, pledges are automatically considered attested upon submission.
     * @param required True to require attestation, false to disable.
     */
    function togglePledgeVerificationStatus(bool required) public onlyDAO {
        ecoPledgeVerificationRequired = required;
        emit DAOParameterUpdated(keccak256("ecoPledgeVerificationRequired"), required ? 1 : 0);
    }

    /**
     * @notice Adds an address to the list of authorized eco-initiative proposers.
     * @dev Only callable by the DAO (or owner as placeholder).
     * @param proposerAddress The address to authorize.
     */
    function addEcoInitiativeProposer(address proposerAddress) public onlyDAO {
        require(proposerAddress != address(0), "Address cannot be zero");
        isEcoInitiativeProposer[proposerAddress] = true;
    }

    /**
     * @notice Removes an address from the list of authorized eco-initiative proposers.
     * @dev Only callable by the DAO (or owner as placeholder).
     * @param proposerAddress The address to de-authorize.
     */
    function removeEcoInitiativeProposer(address proposerAddress) public onlyDAO {
        isEcoInitiativeProposer[proposerAddress] = false;
    }

    // --- Utility and Fallback ---

    receive() external payable {
        emit DonationToEcoFund(msg.sender, msg.value);
    }

    // Minimal Math utility for min/max within contract to avoid importing a full library
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }
    }

    // Minimal Base64 utility for tokenURI
    library Base64 {
        string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        function encode(bytes memory data) internal pure returns (string memory) {
            if (data.length == 0) return "";

            uint256 encodedLen = 4 * ((data.length + 2) / 3);
            bytes memory result = new bytes(encodedLen);

            uint256 j = 0;
            for (uint256 i = 0; i < data.length; i += 3) {
                uint256 val = uint256(data[i]);
                val = i + 1 < data.length ? val * 256 + uint256(data[i + 1]) : val;
                val = i + 2 < data.length ? val * 256 + uint256(data[i + 2]) : val;

                bytes1 b1 = bytes1(TABLE[val / 262144]);
                bytes1 b2 = bytes1(TABLE[(val / 4096) % 64]);
                bytes1 b3 = bytes1(TABLE[(val / 64) % 64]);
                bytes1 b4 = bytes1(TABLE[val % 64]);

                result[j++] = b1;
                result[j++] = b2;
                result[j++] = i + 1 < data.length ? b3 : bytes1('=');
                result[j++] = i + 2 < data.length ? b4 : bytes1('=');
            }
            return string(result);
        }

        // Helper to convert health and evolution stage to a simple hex color for SVG.
        // This is a very basic example; real art would use a more complex mapping.
        function toHexColor(uint256 health, uint256 evolutionStage) internal pure returns (string memory) {
            // Health 0-100, EvolutionStage 1-N
            // Map health to green component, evolution to blue/red.
            // Example: More green for higher health. More blue for higher evolution.
            uint256 r = 255 - (health * 2); // Inverted red: less red as health increases
            uint256 g = (health * 2);      // Green increases with health
            uint256 b = (evolutionStage * 50) % 255; // Blue cycles or increases with evolution

            // Clamp values to 0-255
            r = Math.min(r, 255); g = Math.min(g, 255); b = Math.min(b, 255);
            r = Math.max(r, 0); g = Math.max(g, 0); b = Math.max(b, 0);

            // Convert to hex string
            bytes memory buffer = new bytes(6);
            buffer[0] = toHexDigit(r / 16);
            buffer[1] = toHexDigit(r % 16);
            buffer[2] = toHexDigit(g / 16);
            buffer[3] = toHexDigit(g % 16);
            buffer[4] = toHexDigit(b / 16);
            buffer[5] = toHexDigit(b % 16);
            return string(buffer);
        }

        function toHexDigit(uint256 value) internal pure returns (bytes1) {
            require(value < 16, "Invalid hex digit value");
            if (value < 10) {
                return bytes1(uint8(48 + value)); // 0-9
            } else {
                return bytes1(uint8(87 + value)); // a-f (for 10-15)
            }
        }
    }
}
```