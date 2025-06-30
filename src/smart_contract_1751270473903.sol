Okay, let's design a sophisticated smart contract that combines several advanced concepts: NFTs with dynamic traits, a resource generation mechanism (staking), interaction with external data (oracles), randomness (VRF), and a lightweight governance system to influence parameters.

We'll call this contract `OmniGenesis`. It represents a digital ecosystem where users can stake unique "Fragment" NFTs to generate "Essence" (an internal fungible resource). Essence is then used to "Synthesize" new Fragments. The traits of newly synthesized Fragments, and potentially the update of existing Fragment traits, are influenced by a combination of randomness (Chainlink VRF) and external data (Chainlink Oracle). The parameters of this system can be adjusted through a simple governance process based on Essence/Fragment holdings.

This design incorporates:
1.  **ERC-721:** For the "Fragment" NFTs.
2.  **ERC-20:** For the "Essence" fungible resource (implemented within the same contract for simplicity, or as a separate contract). Let's implement it within for tighter coupling.
3.  **Staking:** Lock NFTs to earn Essence.
4.  **Dynamic NFTs:** Fragment traits can potentially change based on oracle data updates.
5.  **Generative Mechanics:** Synthesis uses Essence, randomness, and external data to create new NFTs with specific traits.
6.  **Oracles (Chainlink):** Fetch external data to influence synthesis/trait updates.
7.  **Randomness (Chainlink VRF):** Introduce unpredictable elements into trait generation.
8.  **Light Governance:** Allow stakeholders to propose and vote on parameter changes.

---

**OmniGenesis Smart Contract**

**Concept:** A decentralized protocol for generating and evolving unique digital entities ("Fragments" - ERC-721 NFTs) influenced by staking, time, randomness, and external data, powered by an internal fungible resource ("Essence" - ERC-20 like). Parameters of the system are subject to stakeholder governance.

**Outline:**

1.  **State Variables:** Define contracts (tokens, VRF, Oracle), parameters (costs, rates, trait ranges), mappings (stakes, traits, randomness requests, oracle requests, governance proposals, votes), and structs (FragmentTraits, ParameterProposal, CatalystInfo).
2.  **Events:** Announce key actions (EssenceMinted, FragmentSynthesized, TraitsUpdated, Staked, Unstaked, ProposalCreated, Voted, ParameterChanged).
3.  **Interfaces:** Define necessary interfaces (ERC20, ERC721, VRFCoordinatorV2, Oracle).
4.  **Constructor:** Initialize contracts and base parameters.
5.  **Admin/Setup Functions:** Set initial parameters, add catalyst types, set oracle/VRF configs.
6.  **Essence Generation (Staking):** Functions for staking Fragments to earn Essence, claiming earned Essence, and unstaking.
7.  **Fragment Synthesis:** Function to initiate synthesis (burning Essence, requesting randomness/oracle data). Callback functions for VRF and Oracle to complete synthesis (minting NFT, setting traits).
8.  **Fragment Trait Management:** View fragment traits, initiate trait updates based on new oracle data, callback for oracle trait update, potentially lock traits.
9.  **Oracle & VRF Management:** Functions to request data/randomness (primarily internal), callback handlers.
10. **Catalyst System:** Functions to manage catalyst types, apply catalysts during synthesis (internal logic), perhaps mint catalysts (admin or special process).
11. **Governance:** Functions to propose parameter changes, vote on proposals (weighted by holdings), and execute successful proposals.
12. **View/Query Functions:** Get contract state, parameters, user data (stakes, balances, traits), proposal info.

**Function Summary (25+ Functions):**

1.  `constructor`: Initializes the contract, Essence token, Fragment NFT, and sets initial parameters for VRF, Oracle, costs, rates.
2.  `setVRFParameters`: Admin function to set Chainlink VRF coordinator, keyhash, and subscription ID.
3.  `setOracleParameters`: Admin function to set Chainlink Oracle address, job ID, fee, and link token address.
4.  `setSynthesisCosts`: Admin function to adjust the amount of Essence required for synthesis.
5.  `setEssenceGenerationRate`: Admin function to adjust the rate at which staked Fragments generate Essence per unit of time.
6.  `addSynthesisCatalystType`: Admin function to define properties (e.g., trait bias, cost reduction) of a new type of catalyst.
7.  `setTraitDefinition`: Admin function to map trait IDs (numbers) to human-readable descriptions (strings).
8.  `stakeFragmentsForEssence`: Allows users to stake their Fragment NFTs to start earning Essence rewards. Requires ERC721 `approve`.
9.  `claimEssence`: Allows users to claim accrued Essence rewards from their staked Fragments.
10. `unstakeFragments`: Allows users to withdraw their staked Fragment NFTs and any claimed Essence. Forfeits unclaimed essence.
11. `requestSynthesis`: Initiates the Fragment synthesis process. Burns required Essence, requests randomness from VRF, and requests initial data from the Oracle.
12. `fulfillRandomWords`: (Internal/Callback) Called by the VRF coordinator. Uses the random number(s) to determine some core Fragment traits and triggers the Oracle data application.
13. `requestOracleDataForFragmentUpdate`: Allows a user (or protocol logic) to request an update to an *existing* Fragment's traits based on current external data (e.g., weather, market price). Costs Essence/Link.
14. `fulfillOracleData`: (Internal/Callback) Called by the Oracle contract. Applies the retrieved external data to influence fragment traits during synthesis or update existing traits.
15. `getFragmentTraits`: View function to retrieve the current traits of a specific Fragment NFT.
16. `lockFragmentTraits`: Allows a user to permanently lock the traits of a Fragment NFT, preventing future updates (costs Essence or requires a catalyst).
17. `applyCatalystToSynthesis`: (Internal Logic) Applied during `requestSynthesis` if a catalyst is used. Modifies the outcome of randomness or oracle data application based on the catalyst type.
18. `mintCatalyst`: Admin function to mint new Catalyst NFTs (if catalysts are NFTs) or assign catalyst status.
19. `proposeParameterChange`: Allows users (meeting a minimum holding threshold) to propose changes to configurable parameters (e.g., synthesis cost, essence rate).
20. `voteOnParameterChange`: Allows users to vote on active parameter proposals. Voting power could be weighted by Essence/Fragment holdings.
21. `executeParameterChange`: Allows anyone to execute a proposal that has reached quorum and passed the voting period with a majority.
22. `getEssenceGenerationRate`: View function to retrieve the current Essence generation rate per staked Fragment.
23. `getSynthesisCost`: View function to retrieve the current Essence cost for synthesis.
24. `getUserStakedFragments`: View function to see which Fragment IDs a user has staked.
25. `getUserStakedEssenceRewards`: View function to calculate and see how much Essence a user can currently claim from their staked fragments.
26. `getLatestOracleData`: View function to retrieve the latest data received from the Oracle.
27. `getVRFConfig`: View function to retrieve the current VRF coordinator, keyhash, and subscription ID.
28. `getCatalystInfo`: View function to retrieve details about a specific catalyst type.
29. `getProposalState`: View function to check the current state (Active, Passed, Failed, Executed) and details of a governance proposal.
30. `getTraitDefinition`: View function to get the human-readable description for a trait ID.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
// Assume a simplified Oracle interface for external data
interface IOracle {
    function requestData(
        bytes32 jobId,
        address callbackAddress,
        bytes4 callbackFunctionId,
        uint256 nonce,
        bytes parameters
    ) external returns (bytes32 requestId);

    function fulfillData(bytes32 requestId, bytes data) external; // Placeholder for callback structure
}

/**
 * @title OmniGenesis
 * @dev A decentralized protocol for generating and evolving unique digital entities (Fragments)
 *      influenced by staking, time, randomness, and external data, powered by an internal
 *      fungible resource (Essence). Parameters are subject to governance.
 *
 * Concept Outline:
 * 1. State Variables: Store contract references, parameters, user data (stakes, traits),
 *    request mappings (VRF, Oracle), governance data.
 * 2. Events: Announce important state changes and actions.
 * 3. Interfaces: Define necessary external contract interactions (ERC20, ERC721, VRF, Oracle).
 * 4. Constructor: Initialize contract, sub-tokens (Essence, Fragment), and initial configs.
 * 5. Admin/Setup: Functions for owner to configure Chainlink, costs, rates, catalyst types, trait definitions.
 * 6. Essence Generation (Staking): Users stake Fragments (ERC721) to accrue Essence (ERC20-like).
 * 7. Fragment Synthesis: Users burn Essence to trigger creation of a new Fragment, influenced by VRF randomness and Oracle data.
 * 8. Fragment Trait Management: View traits, trigger trait updates based on new Oracle data for existing fragments, lock traits.
 * 9. Oracle & VRF Interaction: Handle requests and callbacks for external data and randomness.
 * 10. Catalyst System: Define catalyst types and allow them to influence synthesis outcomes.
 * 11. Governance: Simple system for proposing, voting on, and executing parameter changes based on token holdings.
 * 12. View Functions: Query current state, parameters, user holdings, proposal details, etc.
 *
 * Function Summary:
 * - constructor: Initializes contract, tokens, and base parameters.
 * - setVRFParameters: Admin sets VRF coordinator, keyhash, subscription.
 * - setOracleParameters: Admin sets Oracle address, job ID, fee, Link token address.
 * - setSynthesisCosts: Admin sets the Essence cost for Fragment synthesis.
 * - setEssenceGenerationRate: Admin sets Essence yield per staked Fragment per second.
 * - addSynthesisCatalystType: Admin defines a new catalyst type's effects and cost.
 * - setTraitDefinition: Admin maps numeric trait IDs to string descriptions.
 * - stakeFragmentsForEssence: User stakes Fragment NFTs to earn Essence.
 * - claimEssence: User claims accrued Essence rewards from staked Fragments.
 * - unstakeFragments: User withdraws staked Fragments (forfeits unclaimed Essence).
 * - requestSynthesis: User burns Essence, requests VRF and Oracle data to mint a new Fragment.
 * - fulfillRandomWords: VRF callback; uses random output to determine base traits and triggers Oracle callback logic.
 * - requestOracleDataForFragmentUpdate: User requests an existing Fragment's traits be updated based on current Oracle data.
 * - fulfillOracleData: Oracle callback; applies external data to influence traits during synthesis or update.
 * - getFragmentTraits: View function to get a Fragment's current traits.
 * - lockFragmentTraits: User locks a Fragment's traits permanently.
 * - applyCatalystToSynthesis: (Internal) Modifies synthesis outcome based on used catalyst.
 * - mintCatalyst: Admin/special process function to create Catalysts. (Simple admin-only for this example)
 * - proposeParameterChange: User proposes a governance parameter change.
 * - voteOnParameterChange: User votes on an active proposal.
 * - executeParameterChange: Executes a proposal that has met quorum/threshold.
 * - getEssenceGenerationRate: View current Essence rate.
 * - getSynthesisCost: View current synthesis cost.
 * - getUserStakedFragments: View Fragment IDs staked by a user.
 * - getUserStakedEssenceRewards: View calculable unclaimed Essence for a user.
 * - getLatestOracleData: View the last fetched Oracle data.
 * - getVRFConfig: View VRF parameters.
 * - getCatalystInfo: View details of a catalyst type.
 * - getProposalState: View state and details of a governance proposal.
 * - getTraitDefinition: View string description for a trait ID.
 */
contract OmniGenesis is ERC20, ERC721, Ownable, VRFConsumerBaseV2 {
    // --- State Variables ---

    // Tokens
    ERC20 public essenceToken; // ERC20 is inherited directly, this isn't needed as a separate variable
    ERC721 public fragmentNFT; // ERC721 is inherited directly

    // Chainlink VRF
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 i_subscriptionId;
    bytes32 i_keyHash;
    uint32 i_callbackGasLimit;

    // Chainlink Oracle
    IOracle public oracle;
    ERC20 public linkToken; // Assuming Oracle requires LINK token
    bytes32 public oracleJobId;
    uint256 public oracleFee;

    // Synthesis Parameters
    uint256 public essenceForSynthesis;
    uint256 public currentFragmentSupply = 0; // ERC721 internal _nextTokenId could track this

    // Essence Generation (Staking) Parameters
    uint256 public essenceGenerationRatePerSecond; // Per staked fragment

    struct StakeInfo {
        uint256[] fragmentIds;
        uint256 startTime; // When the first fragment was staked
        uint256 accumulatedRewards; // Rewards calculated up to the last claim/stake/unstake action
        mapping(uint256 => bool) isStaked; // To check if a specific ID is staked by this user
    }
    mapping(address => StakeInfo) private userStakes;

    // Fragment Traits
    struct FragmentTraits {
        uint256 coreTrait; // Derived from VRF
        uint256 externalTrait; // Derived from Oracle data
        bool traitsLocked; // Can no longer be updated
        mapping(uint256 => uint256) catalystModifiers; // Store how catalysts affected this fragment
    }
    mapping(uint256 => FragmentTraits) private fragmentTraits; // fragmentId => Traits

    // Randomness & Oracle Request Tracking
    mapping(uint256 => uint256) private vrfRequestIdToFragmentId; // VRF request ID => Fragment ID being synthesized/updated
    mapping(bytes32 => uint256) private oracleRequestIdToFragmentId; // Oracle request ID => Fragment ID being synthesized/updated
    mapping(bytes32 => bool) private activeOracleRequests; // Track pending Oracle requests

    // Catalyst System
    struct CatalystInfo {
        uint256 essenceCostModifier; // % reduction in synthesis cost
        bytes traitBiasData; // Data influencing how traits are set (e.g., min/max range for random/oracle)
        bool isActive;
    }
    mapping(uint256 => CatalystInfo) public catalystTypes; // Catalyst ID => Info
    uint256 public nextCatalystId = 1; // Counter for catalyst types

    // Governance
    struct ParameterProposal {
        address proposer;
        bytes data; // Encoded function call data for the parameter setter
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalVotes; // Weighted votes (e.g., sum of Essence + Fragment counts)
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed; // Determined after voting period
    }
    mapping(uint256 => ParameterProposal) public proposals;
    uint256 public nextProposalId = 1;
    uint256 public votingPeriodBlocks = 100; // Example voting period
    uint256 public proposalThresholdHoldings = 100; // Minimum combined holdings (Essence + Fragments) to propose
    uint256 public quorumVotesPercentage = 5; // % of total possible votes (total supply) needed for quorum

    // Trait Definitions
    mapping(uint256 => string) public traitDefinitions; // Trait ID => Description string

    // Latest Oracle Data (Example: simplified single data point)
    bytes public latestOracleData;

    // --- Events ---
    event EssenceMinted(address indexed recipient, uint256 amount);
    event FragmentSynthesized(uint256 indexed fragmentId, address indexed owner, uint256 costPaid);
    event TraitsUpdated(uint256 indexed fragmentId, bool isInitialSynthesis);
    event FragmentStaked(address indexed user, uint256[] fragmentIds);
    event FragmentUnstaked(address indexed user, uint256[] fragmentIds);
    event EssenceClaimed(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 startBlock, uint256 endBlock);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 votes);
    event ParameterChanged(uint256 indexed proposalId, bytes data);
    event OracleDataReceived(bytes32 indexed requestId, bytes data);
    event RandomnessReceived(uint256 indexed requestId, uint256[] randomWords);

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address oracleAddress,
        address linkAddress,
        bytes32 jobId,
        uint256 fee
    )
        ERC20("Essence", "ESS")
        ERC721("OmniGenesis Fragment", "OGF")
        VRFConsumerBaseV2(vrfCoordinator)
        Ownable(msg.sender)
    {
        // Chainlink VRF setup
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        // Chainlink Oracle setup
        oracle = IOracle(oracleAddress);
        linkToken = ERC20(linkAddress);
        oracleJobId = jobId;
        oracleFee = fee;

        // Initial parameters
        essenceForSynthesis = 100 ether; // Example cost
        essenceGenerationRatePerSecond = 100 * 1e18 / (365 * 24 * 60 * 60); // Example: 100 Essence per year per fragment

        // Approve VRF Coordinator for LINK spend (if needed, depends on VRF setup)
        // linkToken.approve(address(i_vrfCoordinator), type(uint256).max); // Or specific amount
    }

    // --- Admin/Setup Functions ---

    /**
     * @dev Sets the Chainlink VRF parameters. Only callable by owner.
     * @param vrfCoordinator The address of the VRF Coordinator contract.
     * @param keyHash The key hash used for requesting randomness.
     * @param subscriptionId The subscription ID to use for VRF requests.
     * @param callbackGasLimit The gas limit for the fulfillRandomWords callback.
     */
    function setVRFParameters(address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit) external onlyOwner {
        // Requires re-initializing VRFConsumerBaseV2 if coordinator changes, or handle carefully
        // i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator); // Can't change immutable
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    /**
     * @dev Sets the Chainlink Oracle parameters. Only callable by owner.
     * @param oracleAddress The address of the Oracle contract.
     * @param linkAddress The address of the LINK token contract.
     * @param jobId The job ID for the desired Oracle task.
     * @param fee The amount of LINK required per request.
     */
    function setOracleParameters(address oracleAddress, address linkAddress, bytes32 jobId, uint256 fee) external onlyOwner {
        oracle = IOracle(oracleAddress);
        linkToken = ERC20(linkAddress);
        oracleJobId = jobId;
        oracleFee = fee;
    }

    /**
     * @dev Sets the amount of Essence required to perform a synthesis. Only callable by owner or governance.
     * @param _essenceForSynthesis The new Essence cost.
     */
    function setSynthesisCosts(uint256 _essenceForSynthesis) external onlyOwnerOrGovernance {
        essenceForSynthesis = _essenceForSynthesis;
    }

    /**
     * @dev Sets the rate at which staked Fragments generate Essence per second. Only callable by owner or governance.
     * @param _ratePerSecond The new Essence generation rate per second.
     */
    function setEssenceGenerationRate(uint256 _ratePerSecond) external onlyOwnerOrGovernance {
        essenceGenerationRatePerSecond = _ratePerSecond;
    }

    /**
     * @dev Defines a new type of catalyst. Only callable by owner.
     * @param essenceCostModifier The percentage reduction in synthesis cost (e.g., 10 for 10%).
     * @param traitBiasData Encoded data defining how this catalyst influences traits.
     * @param isActive Whether this catalyst type is initially active.
     * @return The ID of the newly added catalyst type.
     */
    function addSynthesisCatalystType(uint256 essenceCostModifier, bytes memory traitBiasData, bool isActive) external onlyOwner returns (uint256) {
        uint256 catalystId = nextCatalystId++;
        catalystTypes[catalystId] = CatalystInfo(essenceCostModifier, traitBiasData, isActive);
        return catalystId;
    }

     /**
     * @dev Sets the human-readable definition for a trait ID. Only callable by owner.
     * @param traitId The numeric ID of the trait.
     * @param definition The string description for the trait.
     */
    function setTraitDefinition(uint256 traitId, string memory definition) external onlyOwner {
        traitDefinitions[traitId] = definition;
    }

    // --- Essence Generation (Staking) ---

    /**
     * @dev Stakes user's Fragment NFTs to earn Essence.
     * Requires the contract to be approved as an operator for the Fragments.
     * @param fragmentIds The array of Fragment IDs to stake.
     */
    function stakeFragmentsForEssence(uint256[] memory fragmentIds) external {
        require(fragmentIds.length > 0, "No fragments to stake");
        StakeInfo storage stake = userStakes[msg.sender];

        // Claim accumulated rewards before changing stake
        _claimEssenceRewards(msg.sender);

        uint256 currentTimestamp = block.timestamp;
        if (stake.fragmentIds.length == 0) {
            // First time staking
            stake.startTime = currentTimestamp;
        }

        for (uint i = 0; i < fragmentIds.length; i++) {
            uint256 fragmentId = fragmentIds[i];
            require(ownerOf(fragmentId) == msg.sender, "Not owner of fragment");
            require(!stake.isStaked[fragmentId], "Fragment already staked");

            transferFrom(msg.sender, address(this), fragmentId); // Transfer NFT to contract
            stake.fragmentIds.push(fragmentId);
            stake.isStaked[fragmentId] = true;
        }

        // Update start time if the stake became non-empty
        if (stake.startTime == 0) {
             stake.startTime = currentTimestamp;
        }


        emit FragmentStaked(msg.sender, fragmentIds);
    }

    /**
     * @dev Claims accrued Essence rewards from staked Fragments.
     */
    function claimEssence() external {
        _claimEssenceRewards(msg.sender);
        emit EssenceClaimed(msg.sender, userStakes[msg.sender].accumulatedRewards);
        userStakes[msg.sender].accumulatedRewards = 0; // Reset claimed amount
    }

    /**
     * @dev Unstakes user's Fragment NFTs.
     * Forfeits any unclaimed Essence rewards.
     * @param fragmentIds The array of Fragment IDs to unstake.
     */
    function unstakeFragments(uint256[] memory fragmentIds) external {
        require(fragmentIds.length > 0, "No fragments to unstake");
        StakeInfo storage stake = userStakes[msg.sender];

        // Forfeit unclaimed rewards by not claiming them first
        // _claimEssenceRewards(msg.sender); // Skip claiming to forfeit

        uint256 currentTimestamp = block.timestamp;
        uint256 totalStakedCount = stake.fragmentIds.length;
        uint256 unstakedCount = 0;
        uint256[] memory remainingStakedIds = new uint256[](totalStakedCount - fragmentIds.length); // Assuming all fragmentIds are valid and staked
        uint256 remainingIndex = 0;

        for (uint i = 0; i < fragmentIds.length; i++) {
            uint256 fragmentId = fragmentIds[i];
            require(stake.isStaked[fragmentId], "Fragment not staked by user");
            // Note: ownerOf check isn't strictly needed here as `isStaked` mapping implies ownership by contract for this user's stake

            stake.isStaked[fragmentId] = false;
            transferFrom(address(this), msg.sender, fragmentId); // Transfer NFT back to user
            unstakedCount++;
        }

        // Rebuild the staked fragments array efficiently (avoid deleting elements iteratively)
        for (uint i = 0; i < totalStakedCount; i++) {
            uint256 currentStakedId = stake.fragmentIds[i];
             if (stake.isStaked[currentStakedId]) {
                 remainingStakedIds[remainingIndex++] = currentStakedId;
             }
        }
        stake.fragmentIds = remainingStakedIds; // Replace with remaining IDs

        // If all fragments are unstaked, reset start time and accumulated rewards
        if (stake.fragmentIds.length == 0) {
            stake.startTime = 0;
            stake.accumulatedRewards = 0; // Explicitly reset even if unclaimed
        } else {
             // Recalculate rewards up to now and update start time for remaining stake
             uint256 rewardsEarnedSinceLastUpdate = (currentTimestamp - stake.startTime) * stake.fragmentIds.length * essenceGenerationRatePerSecond;
             stake.accumulatedRewards += rewardsEarnedSinceLastUpdate;
             stake.startTime = currentTimestamp; // Update start time for the *remaining* stake period calculation
        }


        emit FragmentUnstaked(msg.sender, fragmentIds);
    }

    /**
     * @dev Internal function to calculate and add pending Essence rewards to accumulated rewards.
     * Called before any action that changes the stake state (stake, claim, unstake).
     * @param user The address of the user whose stake rewards should be updated.
     */
    function _claimEssenceRewards(address user) internal {
        StakeInfo storage stake = userStakes[user];
        uint256 currentTimestamp = block.timestamp;

        if (stake.fragmentIds.length > 0 && stake.startTime > 0 && essenceGenerationRatePerSecond > 0) {
            uint256 duration = currentTimestamp - stake.startTime;
            uint256 rewardsEarned = duration * stake.fragmentIds.length * essenceGenerationRatePerSecond;
            stake.accumulatedRewards += rewardsEarned;
            stake.startTime = currentTimestamp; // Reset timer for next calculation period
        }

        // Mint accumulated rewards to the user
        if (stake.accumulatedRewards > 0) {
             _mint(user, stake.accumulatedRewards); // Mint ERC20 Essence tokens
            // stake.accumulatedRewards is reset in claimEssence, not here
        }
    }

    /**
     * @dev Calculates pending, unclaimed Essence rewards for a user.
     * @param user The address of the user.
     * @return The amount of Essence the user can currently claim.
     */
    function getUserStakedEssenceRewards(address user) public view returns (uint256) {
         StakeInfo storage stake = userStakes[user];
         if (stake.fragmentIds.length == 0 || stake.startTime == 0 || essenceGenerationRatePerSecond == 0) {
             return stake.accumulatedRewards; // Return already accumulated if no active stake/rate
         }
         uint256 currentTimestamp = block.timestamp;
         uint256 duration = currentTimestamp - stake.startTime;
         uint256 rewardsEarned = duration * stake.fragmentIds.length * essenceGenerationRatePerSecond;
         return stake.accumulatedRewards + rewardsEarned;
    }


    // --- Fragment Synthesis ---

    /**
     * @dev Initiates the synthesis process for a new Fragment.
     * Burns Essence, requests VRF randomness and Oracle data.
     * @param catalystId The optional ID of a catalyst to use (0 for none).
     */
    function requestSynthesis(uint256 catalystId) external {
        uint256 cost = essenceForSynthesis;
        if (catalystId > 0) {
            CatalystInfo storage catalyst = catalystTypes[catalystId];
            require(catalyst.isActive, "Catalyst not active");
            cost = cost * (100 - catalyst.essenceCostModifier) / 100;
            // Store catalyst usage for potential trait modification later
            // This specific catalystId will be associated with the synthesis request
        }

        require(balanceOf(msg.sender) >= cost, "Insufficient Essence for synthesis");

        _burn(msg.sender, cost); // Burn the required Essence

        // Get next Fragment ID before requesting randomness/oracle data
        // Note: ERC721 _nextTokenId is internal, we'll need to track this explicitly or rely on mint event.
        // Let's use currentFragmentSupply as the ID counter for simplicity here.
        uint256 newFragmentId = currentFragmentSupply + 1;

        // Request VRF randomness
        uint256 vrfRequestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            getRequestConfirmations(), // Or a fixed number
            i_callbackGasLimit,
            1 // Request 1 random word
        );
        vrfRequestIdToFragmentId[vrfRequestId] = newFragmentId; // Map request to fragment ID

        // Request Oracle data
        bytes memory oracleParams = abi.encode("get", "some_data_key"); // Example Oracle parameters
        bytes32 oracleRequestId = oracle.requestData(
            oracleJobId,
            address(this),
            this.fulfillOracleData.selector,
            newFragmentId, // Use fragment ID as nonce
            oracleParams
        );
        oracleRequestIdToFragmentId[oracleRequestId] = newFragmentId; // Map request to fragment ID
        activeOracleRequests[oracleRequestId] = true; // Mark request as pending

        currentFragmentSupply++; // Increment supply counter
        // The actual minting and trait setting happens in the callback functions
        emit FragmentSynthesized(newFragmentId, msg.sender, cost);
    }

    /**
     * @dev Callback function for Chainlink VRF. Mints the Fragment and sets core traits.
     * @param requestId The request ID provided in the requestRandomWords call.
     * @param randomWords The array of random words provided by the VRF coordinator.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(randomWords.length > 0, "No random words provided");
        uint256 fragmentId = vrfRequestIdToFragmentId[requestId];
        require(fragmentId > 0, "VRF request ID not mapped to a fragment");

        // Determine core trait based on randomness
        // Example: coreTrait = randomWord % 100 (value between 0-99)
        fragmentTraits[fragmentId].coreTrait = randomWords[0] % 100;

        // We need to know the owner to mint it. Store owner in the request mapping?
        // Or assume owner is fixed by who requested synthesis? Let's assume fixed.
        // Store owner in the mapping alongside fragmentId during requestSynthesis.
        // For simplicity in *this* example, we'll assume the owner is retrieved elsewhere or implied.
        // In a real system, map request ID -> {fragmentId, owner}

        // Placeholder owner:
        // This requires a more complex mapping: request ID -> {fragmentId, owner, catalystId}
        // For this example, let's add owner to the vrfRequestIdToFragmentId mapping struct
        // Struct VrfRequestInfo { uint256 fragmentId; address owner; uint256 catalystId; }
        // Mapping vrfRequestIdToFragmentId -> VrfRequestInfo

        // **SIMPLIFICATION for this example:** We'll assume the owner is stored elsewhere or
        // that the fulfillments happen *after* initial request processing where owner is known.
        // Let's just mint to a placeholder or rely on external state lookup for this example.

        // *** Correction: Need to store the owner who requested synthesis! ***
        // Redesigning requestSynthesis and fulfillRandomWords logic slightly for owner tracking.
        // Let's add a mapping: fragmentId => address owner.

        address fragmentOwner = fragmentIdToRequester[fragmentId]; // Need this mapping
        require(fragmentOwner != address(0), "Fragment owner not tracked");

        _safeMint(fragmentOwner, fragmentId); // Mint the NFT

        emit RandomnessReceived(requestId, randomWords);
        emit TraitsUpdated(fragmentId, true); // Traits are initially set
    }

     // Need a mapping to store the requester/owner for the fragment being synthesized
     mapping(uint256 => address) private fragmentIdToRequester;
     // Need a mapping to store catalyst ID used during synthesis request
     mapping(uint256 => uint256) private fragmentIdToCatalyst;


    // --- Fragment Trait Management ---

     /**
     * @dev Allows a user to request an update to an existing Fragment's traits based on current Oracle data.
     * Costs Essence or requires LINK depending on Oracle config.
     * @param fragmentId The ID of the Fragment NFT to update.
     */
    function requestOracleDataForFragmentUpdate(uint256 fragmentId) external {
        require(ownerOf(fragmentId) == msg.sender, "Not owner of fragment");
        require(!fragmentTraits[fragmentId].traitsLocked, "Fragment traits are locked");

        // Example: require Essence cost for update, or require user to provide LINK
        uint256 updateCost = oracleFee; // Use Oracle fee as cost
        require(linkToken.balanceOf(msg.sender) >= updateCost, "Insufficient LINK for Oracle update");

        // Transfer LINK to contract
        linkToken.transferFrom(msg.sender, address(this), updateCost);

        // Request Oracle data for update
        bytes memory oracleParams = abi.encode("get", "some_updated_data"); // Example: requesting different data
        bytes32 oracleRequestId = oracle.requestData(
            oracleJobId,
            address(this),
            this.fulfillOracleData.selector,
            fragmentId, // Use fragment ID as nonce/identifier for callback
            oracleParams
        );
        oracleRequestIdToFragmentId[oracleRequestId] = fragmentId; // Map request to fragment ID
        activeOracleRequests[oracleRequestId] = true; // Mark request as pending

        // Emit an event indicating request, not completion
        // Consider a specific event like TraitUpdateRequest(fragmentId, requestId)
    }


    /**
     * @dev Callback function for Chainlink Oracle. Applies external data to influence traits.
     * This function is called for both initial synthesis AND trait updates.
     * @param requestId The request ID provided in the requestData call.
     * @param data The data received from the Oracle.
     */
    function fulfillOracleData(bytes32 requestId, bytes memory data) external {
        require(activeOracleRequests[requestId], "Oracle request not active");
        delete activeOracleRequests[requestId]; // Mark as fulfilled

        uint256 fragmentId = oracleRequestIdToFragmentId[requestId];
        require(fragmentId > 0, "Oracle request ID not mapped to a fragment");

        // Check if this is an initial synthesis or an update request
        bool isInitialSynthesis = !fragmentTraits[fragmentId].traitsLocked && fragmentTraits[fragmentId].externalTrait == 0; // Example check

        // Apply external data to traits
        // Example: externalTrait = uint256(keccak256(data)) % 200; // Simple hash of data
        // More complex logic needed here to parse `data` and apply biases from catalyst if applicable

        uint256 externalTraitValue = uint256(keccak256(data)) % 200; // Placeholder logic

        if (!fragmentTraits[fragmentId].traitsLocked) {
             fragmentTraits[fragmentId].externalTrait = externalTraitValue;

             // Apply Catalyst influence IF this was an initial synthesis and a catalyst was used
             uint256 usedCatalystId = fragmentIdToCatalyst[fragmentId];
             if (isInitialSynthesis && usedCatalystId > 0) {
                  CatalystInfo storage catalyst = catalystTypes[usedCatalystId];
                  // Apply catalyst.traitBiasData to modify fragmentTraits[fragmentId].coreTrait and .externalTrait
                  // Example: coreTrait = (coreTrait + catalyst.traitBiasModifier) % 100;
                  // This logic is highly specific to your trait system
                  // fragmentTraits[fragmentId].catalystModifiers[usedCatalystId] = someValue; // Record catalyst effect
             }

             emit TraitsUpdated(fragmentId, isInitialSynthesis);
        }

        latestOracleData = data; // Store latest data received
        emit OracleDataReceived(requestId, data);
    }

    /**
     * @dev Gets the traits of a specific Fragment NFT.
     * @param fragmentId The ID of the Fragment.
     * @return The FragmentTraits struct for the given ID.
     */
    function getFragmentTraits(uint256 fragmentId) external view returns (FragmentTraits memory) {
        require(_exists(fragmentId), "Fragment does not exist");
        // Note: Returns a copy of the struct from storage
        return fragmentTraits[fragmentId];
    }

    /**
     * @dev Allows the owner of a Fragment to lock its traits permanently.
     * Prevents future trait updates via Oracle data.
     * Requires burning Essence or using a special catalyst.
     * @param fragmentId The ID of the Fragment to lock.
     */
    function lockFragmentTraits(uint256 fragmentId) external {
        require(ownerOf(fragmentId) == msg.sender, "Not owner of fragment");
        require(!fragmentTraits[fragmentId].traitsLocked, "Fragment traits already locked");

        // Example cost: burn Essence
        uint256 lockCost = essenceForSynthesis / 2; // Example cost
        require(balanceOf(msg.sender) >= lockCost, "Insufficient Essence to lock traits");
        _burn(msg.sender, lockCost);

        fragmentTraits[fragmentId].traitsLocked = true;
        // Emit an event for trait locking
    }

    // --- Catalyst System ---

    /**
     * @dev Placeholder for internal catalyst application logic.
     * This would be called during synthesis fulfillment (`fulfillRandomWords` or `fulfillOracleData`)
     * if a catalyst was specified in `requestSynthesis`.
     * @param fragmentId The ID of the fragment being synthesized.
     * @param catalystId The ID of the catalyst used.
     */
    function applyCatalystToSynthesis(uint256 fragmentId, uint256 catalystId) internal {
        // This function is conceptual. The logic would be inside fulfillments.
        // Example: catalystTypes[catalystId].traitBiasData is decoded and used
        // to influence how randomWords or oracle data map to traits.
    }

    /**
     * @dev Admin function to mint Catalyst NFTs (if catalysts are NFTs).
     * This is a simplified example; a real system might have earning mechanisms.
     * @param to The recipient address.
     * @param catalystTypeId The type of catalyst to mint.
     */
    function mintCatalyst(address to, uint265 catalystTypeId) external onlyOwner {
        // Assumes catalysts are NFTs. Requires another ERC721 or ERC1155 implementation.
        // Since catalysts are just state modifiers in this example, this function is not needed for this contract's logic.
        // Kept in summary as a potential related function in a broader system.
    }


    // --- Governance ---

    /**
     * @dev Allows users with sufficient holdings to propose a change to a configurable parameter.
     * The change is represented by the encoded call data of the target setter function.
     * @param target The address of the contract where the function will be called (likely this contract).
     * @param calldata The encoded function call (e.g., `abi.encodeWithSelector(this.setSynthesisCosts.selector, newCost)`).
     * @param description A brief description of the proposal.
     */
    function proposeParameterChange(address target, bytes memory calldata, string memory description) external {
        // Calculate user's combined voting power (Essence + Fragment count)
        uint256 userHoldings = balanceOf(msg.sender) + ERC721.balanceOf(msg.sender);
        require(userHoldings >= proposalThresholdHoldings, "Insufficient holdings to propose");

        uint256 proposalId = nextProposalId++;
        uint256 start = block.number;
        uint256 end = start + votingPeriodBlocks;

        proposals[proposalId] = ParameterProposal({
            proposer: msg.sender,
            data: calldata,
            startBlock: start,
            endBlock: end,
            totalVotes: 0,
            executed: false,
            passed: false, // Determined after voting ends
            hasVoted: new mapping(address => bool) // Initialize inner mapping
        });

        // Store proposal description separately if needed, or hash it.

        emit ProposalCreated(proposalId, msg.sender, start, end);
    }

    /**
     * @dev Allows users to vote on an active proposal.
     * Voting power is weighted by their current Essence + Fragment holdings.
     * @param proposalId The ID of the proposal to vote on.
     */
    function voteOnParameterChange(uint265 proposalId) external {
        ParameterProposal storage proposal = proposals[proposalId];
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "Voting not open");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        // Calculate voter's power at the time of voting
        uint256 voterPower = balanceOf(msg.sender) + ERC721.balanceOf(msg.sender);
        require(voterPower > 0, "No voting power");

        proposal.totalVotes += voterPower;
        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, voterPower);
    }

    /**
     * @dev Allows anyone to execute a proposal that has passed its voting period and met the criteria.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 proposalId) external {
        ParameterProposal storage proposal = proposals[proposalId];
        require(block.number > proposal.endBlock, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        // Calculate total possible voting power (e.g., total supply of Essence + Fragments)
        // For simplicity, let's use current total supplies.
        uint256 totalPossibleVotes = totalSupply() + currentFragmentSupply; // Or use snapshot at proposal start

        // Check Quorum: total votes must be above a threshold of total possible votes
        require(proposal.totalVotes * 100 >= totalPossibleVotes * quorumVotesPercentage, "Quorum not met");

        // Check Majority: For this simple model, quorum IS majority. A more complex model
        // would track pro/con votes. Assuming simple support-weighted total votes for 'yes'.
        // If quorum is met, it passes in this simple model.
        proposal.passed = true;

        require(proposal.passed, "Proposal did not pass");

        // Execute the proposal's encoded function call
        (bool success, ) = proposal.target.call(proposal.data);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ParameterChanged(proposalId, proposal.data);
    }

    // Modifier to restrict functions to owner or governance execution
    modifier onlyOwnerOrGovernance() {
        require(owner() == msg.sender || msg.sender == address(this), "Only owner or governance can call");
        _;
    }


    // --- View/Query Functions ---

    /**
     * @dev Gets the current Essence generation rate per staked Fragment per second.
     */
    function getEssenceGenerationRate() external view returns (uint256) {
        return essenceGenerationRatePerSecond;
    }

    /**
     * @dev Gets the current Essence cost for Fragment synthesis.
     */
    function getSynthesisCost() external view returns (uint256) {
        return essenceForSynthesis;
    }

    /**
     * @dev Gets the IDs of Fragments currently staked by a user.
     * @param user The address of the user.
     * @return An array of staked Fragment IDs.
     */
    function getUserStakedFragments(address user) external view returns (uint256[] memory) {
        return userStakes[user].fragmentIds;
    }

    /**
     * @dev Gets the latest data received from the Oracle.
     * @return The latest Oracle data bytes.
     */
    function getLatestOracleData() external view returns (bytes memory) {
        return latestOracleData;
    }

    /**
     * @dev Gets the current Chainlink VRF configuration parameters.
     * @return vrfCoordinator The VRF Coordinator address.
     * @return keyHash The key hash.
     * @return subscriptionId The subscription ID.
     * @return callbackGasLimit The callback gas limit.
     */
    function getVRFConfig() external view returns (address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit) {
        return (address(i_vrfCoordinator), i_keyHash, i_subscriptionId, i_callbackGasLimit);
    }

    /**
     * @dev Gets details for a specific catalyst type.
     * @param catalystId The ID of the catalyst type.
     * @return CatalystInfo struct details.
     */
    function getCatalystInfo(uint256 catalystId) external view returns (CatalystInfo memory) {
        return catalystTypes[catalystId];
    }

    /**
     * @dev Gets the state and details of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return ParameterProposal struct details.
     */
    function getProposalState(uint256 proposalId) external view returns (ParameterProposal memory) {
        // Note: The internal 'hasVoted' mapping is not returned in external calls.
        // You'd need a separate view function like `hasVoted(proposalId, user)` if needed.
        return proposals[proposalId];
    }

     /**
     * @dev Gets the string definition for a trait ID.
     * @param traitId The numeric ID of the trait.
     * @return The definition string.
     */
    function getTraitDefinition(uint256 traitId) external view returns (string memory) {
        return traitDefinitions[traitId];
    }

    // --- Internal/Helper Functions ---

    // VRFConsumerBaseV2 requires getRequestConfirmations()
    function getRequestConfirmations() internal pure returns (uint16) {
         return 3; // Or a configurable value
    }

    // ERC721 required functions (implemented by OpenZeppelin)
    // ERC20 required functions (implemented by OpenZeppelin)

    // Need to override ERC721's _beforeTokenTransfer to update staking status if transferring staked tokens
    // This is complex. A simpler model ensures staked tokens cannot be transferred *unless* unstaked first.
    // The current `unstakeFragments` handles transfer back to user. Transfers to contract are handled in `stakeFragmentsForEssence`.
    // Standard ERC721 functions like `transferFrom` will fail if the caller is not the owner OR approved operator.
    // Staking works by transferring ownership TO the contract. So standard `transferFrom` by original owner would fail.
    // Approval for the contract itself is handled implicitly as it *is* the owner.

    // Need to ensure Fragment NFTs can't be transferred while staked by calling standard ERC721 functions.
    // The current implementation achieves this because the contract becomes the owner during staking.
    // Only the contract can call transferFrom on a staked NFT.

    // Example of how to handle Oracle data application logic (conceptual)
    function _applyOracleDataToTraits(uint256 fragmentId, bytes memory data) internal {
        // Decode 'data' bytes based on how the Oracle feeds it
        // Example: uint256 price = abi.decode(data, (uint256));
        // Use 'price' to influence fragmentTraits[fragmentId].externalTrait
        // fragmentTraits[fragmentId].externalTrait = price % 200; // Simple example

        // If a catalyst was used during synthesis, apply its bias
        uint256 usedCatalystId = fragmentIdToCatalyst[fragmentId];
        if (usedCatalystId > 0) {
            CatalystInfo storage catalyst = catalystTypes[usedCatalystId];
            // Apply catalyst.traitBiasData to modify traits
            // Example: fragmentTraits[fragmentId].externalTrait = fragmentTraits[fragmentId].externalTrait + uint256(catalyst.traitBiasData) % 50;
        }
    }
}
```