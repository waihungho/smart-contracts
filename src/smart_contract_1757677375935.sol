Here's a Solidity smart contract for **"Ethereal Echoes: Autonomous Narrative & Dynamic NFT Evolution"**. This contract creates a self-evolving, on-chain narrative system where digital assets (NFTs) called "Narrative Fragments" react and change based on a probabilistic, deterministic "prediction engine." Users influence this engine by submitting "predictions" using a fungible token called "Echo Essence." Fragments can mutate, combine, or split, leading to dynamic metadata and an emergent narrative. A decentralized governance mechanism ("Lore Keepers") allows stakeholders to guide the system's evolution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string conversion in URI
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For calculations

/**
 * @title Ethereal Echoes: Autonomous Narrative & Dynamic NFT Evolution
 * @dev This contract creates a self-evolving, on-chain narrative system where digital assets (NFTs) called
 *      "Narrative Fragments" react and change based on a probabilistic, deterministic "prediction engine."
 *      Users influence this engine by submitting "predictions" using a fungible token called "Echo Essence."
 *      Fragments can mutate, combine, or split, leading to dynamic metadata and an emergent narrative.
 *      A decentralized governance mechanism ("Lore Keepers") allows stakeholders to guide the system's evolution.
 *
 * @outline
 * I. Core System & Setup
 * II. Narrative Fragments (NFT - ERC721 based)
 * III. Echo Essence (Fungible Token - ERC20 based)
 * IV. Predictive & Influence Mechanics
 * V. Fragment Evolution & Lore Progression
 * VI. Governance & System Parameters (Lore Keepers DAO)
 * VII. Emergency & Maintenance
 *
 * @function_summary
 * 1.  `constructor`: Initializes owner, ERC721/ERC20 tokens, and initial system parameters.
 * 2.  `setEpochDuration(uint64 _duration)`: Sets the duration of each narrative epoch. Owner/Governance only.
 * 3.  `getCurrentEpoch()`: Returns the current narrative epoch number.
 * 4.  `triggerEpochAdvance()`: Public function to advance the system to the next epoch, finalizing predictions, calculating outcomes, and opening the evolution window. Can be called by anyone after the current epoch duration.
 * 5.  `mintNarrativeFragment(string calldata initialTraitsJson)`: Mints a new Narrative Fragment NFT with initial on-chain stringified JSON traits.
 * 6.  `getFragmentTraits(uint256 tokenId)`: Retrieves the current stringified JSON traits of a specific fragment.
 * 7.  `tokenURI(uint256 tokenId)`: Overrides ERC721URIStorage to return the current dynamically generated metadata URI for a fragment.
 * 8.  `claimEssenceForParticipation()`: Allows stakers/active participants to claim accrued Echo Essence rewards from previous epochs.
 * 9.  `stakeEssence(uint256 amount)`: Stakes Echo Essence to gain influence in prediction outcomes and accumulate governance power/rewards.
 * 10. `unstakeEssence(uint256 amount)`: Unstakes Echo Essence.
 * 11. `submitPrediction(uint256 fragmentId, bytes32 targetTraitHash, uint256 essenceAmount)`: Users submit a prediction for a fragment's future evolution, backing it with Essence.
 * 12. `reallocatePrediction(uint256 fragmentId, bytes32 oldTargetHash, bytes32 newTargetHash, uint256 essenceAmount)`: Allows users to change the target of an existing prediction, moving staked Essence.
 * 13. `getFragmentPredictionOdds(uint256 fragmentId)`: Calculates and returns the current probabilistic odds for various trait evolutions for a fragment based on submitted predictions in the current epoch.
 * 14. `getPredictionWindowEndTime()`: Returns the timestamp when prediction submissions close for the current epoch.
 * 15. `initiateFragmentEvolution(uint256 fragmentId, bytes32 chosenEvolutionHash)`: Triggers the evolution of a fragment by its owner during the evolution window, based on epoch-finalized predictions and consuming Essence.
 * 16. `getPotentialEvolutionPaths(uint256 fragmentId)`: Returns a list of possible evolution outcome hashes for a fragment based on its current traits. (Simulated/predefined options).
 * 17. `getEvolutionCost(bytes32 evolutionPathHash)`: Returns the Echo Essence cost required to pursue a specific evolution path.
 * 18. `absorbEcho(uint256 targetFragmentId, uint256 sourceFragmentId)`: A creative evolution where one fragment absorbs traits/essence from another, burning the source fragment and altering the target.
 * 19. `splitFragment(uint256 parentFragmentId, string calldata childInitialTraitsJson)`: A fragment can "split," creating a new child fragment and potentially altering the parent's traits, with an Essence cost.
 * 20. `proposeSystemParameterChange(string calldata parameterKey, string calldata newValue)`: Allows staked Essence holders to propose changes to core system parameters (e.g., epoch duration, prediction weights).
 * 21. `voteOnProposal(uint256 proposalId, bool support)`: Allows staked Essence holders to vote on active governance proposals.
 * 22. `executeProposal(uint256 proposalId)`: Executes a proposal that has passed the voting period and met quorum.
 * 23. `setOracleAddress(address _newOracle)`: Sets an address for a potential external data oracle (e.g., Chainlink VRF for more unpredictable outcomes). Owner/Governance only.
 * 24. `pauseContract()`: Pauses certain critical functionalities of the contract in case of an emergency. Owner/Governance only.
 * 25. `unpauseContract()`: Unpauses the contract after an emergency. Owner/Governance only.
 */
contract EtherealEchoes is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpoch, uint64 predictionWindowEnd, uint64 evolutionWindowEnd);
    event FragmentMinted(uint256 indexed tokenId, address indexed owner, string initialTraits);
    event FragmentEvolved(uint256 indexed tokenId, bytes32 indexed evolutionHash, string newTraits);
    event FragmentAbsorbed(uint256 indexed targetTokenId, uint256 indexed sourceTokenId);
    event FragmentSplit(uint256 indexed parentTokenId, uint256 indexed childTokenId, string childTraits);
    event PredictionSubmitted(uint256 indexed fragmentId, address indexed predictor, bytes32 targetTraitHash, uint256 essenceAmount);
    event PredictionReallocated(uint256 indexed fragmentId, address indexed predictor, bytes32 oldTargetHash, bytes32 newTargetHash, uint256 essenceAmount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string parameterKey, string newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);

    // --- State Variables ---
    EchoEssence public essenceToken; // The ERC20 token for predictions and governance
    Counters.Counter private _fragmentTokenIds; // Counter for Narrative Fragment NFTs

    // Current epoch details
    uint256 public currentEpoch;
    uint64 public epochDuration; // Duration of each epoch in seconds
    uint64 public predictionWindowEnd; // Timestamp when prediction submission closes
    uint64 public evolutionWindowEnd; // Timestamp when fragment evolution closes (typically ends when new epoch starts)

    // Fragment traits storage: tokenId => JSON string of traits
    mapping(uint256 => string) public fragmentTraits;

    // --- Prediction System ---
    // fragmentId => epoch => targetTraitHash => totalEssenceStaked
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))) public epochPredictions;
    // fragmentId => epoch => predictorAddress => targetTraitHash => essenceStakedByPredictor
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(bytes32 => uint256)))) public userPredictions;
    // fragmentId => epoch => totalEssenceForFragment
    mapping(uint256 => mapping(uint256 => uint256)) public totalEssencePerFragmentPerEpoch;

    // --- Governance System ---
    // Staked Essence for governance and rewards: address => amount
    mapping(address => uint256) public stakedEssence;
    mapping(address => uint256) public lastClaimEpoch; // To track reward distribution

    struct Proposal {
        uint256 id;
        string parameterKey;
        string newValue;
        uint256 creationEpoch;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted; // Voter address => true if voted
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalVotingPeriod; // In seconds
    uint256 public proposalQuorumPercentage; // e.g., 5 for 5% of total staked essence
    uint256 public minEssenceToPropose;

    // --- Oracle Integration ---
    address public oracleAddress; // For potential VRF or external data feeds

    // --- Pausability (for emergencies) ---
    bool public paused;

    // --- Configuration Parameters (Governance-controlled) ---
    mapping(bytes32 => uint256) public systemParameters; // e.g., keccak256("PREDICTION_REWARD_PERCENTAGE")

    // --- Internal/Utility Mappings ---
    // Mappings for predefined evolution paths and their costs (can be complex JSON or struct definitions)
    // For simplicity, let's use a hash -> cost, and assume the off-chain system knows what the hash means.
    mapping(bytes32 => uint256) public evolutionPathCosts; // evolutionPathHash => essenceCost

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyLoreKeepers() {
        require(stakedEssence[msg.sender] >= minEssenceToPropose, "Not enough Essence staked to act as Lore Keeper");
        _;
    }

    /**
     * @dev Constructor
     * @param _essenceTokenAddress Address of the Echo Essence ERC20 token.
     * @param _initialEpochDuration Initial duration of each epoch in seconds.
     * @param _initialProposalVotingPeriod Initial voting period for proposals in seconds.
     * @param _initialProposalQuorumPercentage Initial quorum percentage for proposals (e.g., 5 for 5%).
     * @param _minEssenceToPropose_ Minimum Essence required to create a proposal.
     */
    constructor(
        address _essenceTokenAddress,
        uint64 _initialEpochDuration,
        uint256 _initialProposalVotingPeriod,
        uint256 _initialProposalQuorumPercentage,
        uint256 _minEssenceToPropose_
    ) ERC721("Narrative Fragment", "ECHOFRAG") Ownable(msg.sender) {
        require(_essenceTokenAddress != address(0), "Invalid essence token address");
        essenceToken = EchoEssence(_essenceTokenAddress); // Assume EchoEssence is deployed separately
        epochDuration = _initialEpochDuration;
        currentEpoch = 1; // Start with Epoch 1
        predictionWindowEnd = uint64(block.timestamp) + epochDuration;
        evolutionWindowEnd = predictionWindowEnd; // Evolution closes with the next epoch advance
        paused = false;

        proposalVotingPeriod = _initialProposalVotingPeriod;
        proposalQuorumPercentage = _initialProposalQuorumPercentage;
        minEssenceToPropose = _minEssenceToPropose_;

        // Set initial system parameters (can be modified by governance)
        systemParameters[keccak256(abi.encodePacked("PREDICTION_REWARD_PERCENTAGE"))] = 10; // 0.1% for every 1% of Essence staked
        systemParameters[keccak256(abi.encodePacked("STAKING_REWARD_PERCENTAGE"))] = 100; // 1% of staked Essence per epoch (100 = 1%)
        systemParameters[keccak256(abi.encodePacked("BASE_EVOLUTION_COST"))] = 1 ether; // Example: 1 Essence
        systemParameters[keccak256(abi.encodePacked("MINT_FRAGMENT_COST"))] = 0.1 ether; // Example: 0.1 Essence to mint
        systemParameters[keccak256(abi.encodePacked("ABSORPTION_COST"))] = 2 ether; // Example: 2 Essence for absorption
        systemParameters[keccak256(abi.encodePacked("SPLIT_FRAGMENT_COST"))] = 1.5 ether; // Example: 1.5 Essence for splitting

        // Define initial evolution path costs
        evolutionPathCosts[keccak256(abi.encodePacked("STANDARD_EVOLUTION"))] = systemParameters[keccak256(abi.encodePacked("BASE_EVOLUTION_COST"))];
        evolutionPathCosts[keccak256(abi.encodePacked("ADAPTIVE_CHANGE"))] = systemParameters[keccak256(abi.encodePacked("BASE_EVOLUTION_COST"))].mul(150).div(100); // 1.5x base cost
        evolutionPathCosts[keccak256(abi.encodePacked("RADICAL_SHIFT"))] = systemParameters[keccak256(abi.encodePacked("BASE_EVOLUTION_COST"))].mul(200).div(100); // 2x base cost
    }

    // --- I. Core System & Setup ---

    /**
     * @dev Sets the duration of each narrative epoch.
     * @param _duration The new duration in seconds.
     */
    function setEpochDuration(uint64 _duration) public onlyOwner whenNotPaused {
        require(_duration > 0, "Epoch duration must be positive");
        epochDuration = _duration;
    }

    /**
     * @dev Returns the current narrative epoch number.
     * @return The current epoch.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @dev Advances the system to the next epoch. This finalizes predictions, calculates
     *      outcomes, and opens the evolution window for the new epoch.
     *      Can be called by anyone after the current epoch's duration has passed.
     *      Note: Complex reward distribution for accurate predictions should ideally be done here,
     *      but is omitted for contract size and gas cost in this example. Rewards are instead tied to staking.
     */
    function triggerEpochAdvance() public whenNotPaused {
        require(block.timestamp >= predictionWindowEnd, "Prediction window not yet closed");

        currentEpoch++;
        uint64 now = uint64(block.timestamp);
        predictionWindowEnd = now + epochDuration;
        evolutionWindowEnd = predictionWindowEnd; // Evolution window typically runs until the next epoch advance.

        emit EpochAdvanced(currentEpoch, predictionWindowEnd, evolutionWindowEnd);
    }

    // --- II. Narrative Fragments (NFT - ERC721 based) ---

    /**
     * @dev Mints a new Narrative Fragment NFT to the caller with initial on-chain traits.
     *      The initial traits are provided as a stringified JSON object.
     *      Requires an Essence fee to mint, defined by `MINT_FRAGMENT_COST`.
     * @param initialTraitsJson A stringified JSON object representing the fragment's initial traits.
     *                          Example: `{"color": "red", "type": "seed", "energy": 10}`
     */
    function mintNarrativeFragment(string calldata initialTraitsJson) public whenNotPaused {
        _fragmentTokenIds.increment();
        uint256 newItemId = _fragmentTokenIds.current();

        uint256 mintCost = systemParameters[keccak256(abi.encodePacked("MINT_FRAGMENT_COST"))];
        if (mintCost > 0) {
            require(essenceToken.transferFrom(msg.sender, address(this), mintCost), "Essence transfer failed for minting");
        }
        
        _safeMint(msg.sender, newItemId);
        fragmentTraits[newItemId] = initialTraitsJson;
        _setTokenURI(newItemId, _calculateFragmentURI(newItemId, initialTraitsJson)); // Set initial URI

        emit FragmentMinted(newItemId, msg.sender, initialTraitsJson);
    }

    /**
     * @dev Retrieves the current stringified JSON traits of a specific fragment.
     * @param tokenId The ID of the Narrative Fragment.
     * @return A stringified JSON object of the fragment's current traits.
     */
    function getFragmentTraits(uint256 tokenId) public view returns (string memory) {
        // No owner check, as metadata/traits are generally public.
        require(_exists(tokenId), "ERC721: invalid token ID");
        return fragmentTraits[tokenId];
    }

    /**
     * @dev Overrides ERC721URIStorage to return the current dynamically generated metadata URI for a fragment.
     *      The URI will point to an off-chain renderer/API that generates the image and JSON based on the on-chain traits.
     *      The URI includes the current epoch and a hash of the traits to ensure freshness and cache busting.
     * @param tokenId The ID of the Narrative Fragment.
     * @return The dynamic metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        string memory currentTraits = fragmentTraits[tokenId];
        return _calculateFragmentURI(tokenId, currentTraits);
    }

    /**
     * @dev Internal helper to construct the dynamic metadata URI.
     *      This URI points to an off-chain API, but its parameters are derived from on-chain state.
     * @param tokenId The ID of the Narrative Fragment.
     * @param traitsJson The current JSON string of traits.
     * @return The constructed metadata URI.
     */
    function _calculateFragmentURI(uint256 tokenId, string memory traitsJson) internal view returns (string memory) {
        bytes32 traitsHash = keccak256(abi.encodePacked(traitsJson));
        // Example: https://api.etherealechoes.com/fragment/{tokenId}/{epoch}/{traitsHash}.json
        // The off-chain API would use tokenId, epoch, and traitsHash to render dynamic content.
        return string(abi.encodePacked(
            "https://api.etherealechoes.com/fragment/",
            tokenId.toString(),
            "/",
            currentEpoch.toString(),
            "/",
            Strings.toHexString(uint256(traitsHash)),
            ".json"
        ));
    }

    // --- III. Echo Essence (Fungible Token - ERC20 based) ---
    // Note: EchoEssence is a separate ERC20 contract that this contract interacts with.

    /**
     * @dev Allows stakers/active participants to claim accrued Echo Essence rewards from previous epochs.
     *      Rewards are based on the amount of Essence staked.
     */
    function claimEssenceForParticipation() public whenNotPaused {
        uint256 userStaked = stakedEssence[msg.sender];
        require(userStaked > 0, "No Essence staked to claim rewards");

        uint256 lastClaimed = lastClaimEpoch[msg.sender];
        uint256 epochsPassed = currentEpoch.sub(lastClaimed);
        require(epochsPassed > 0, "No new epochs passed since last claim or no staking recorded");

        // Simple reward calculation: configurable percentage of staked Essence per epoch
        uint256 rewardPercentage = systemParameters[keccak256(abi.encodePacked("STAKING_REWARD_PERCENTAGE"))]; // e.g., 100 for 1%
        uint256 rewardPerEpoch = userStaked.mul(rewardPercentage).div(10_000); // 10_000 for percentage with 2 decimal places (100 = 1.00%)
        uint256 totalReward = rewardPerEpoch.mul(epochsPassed);

        lastClaimEpoch[msg.sender] = currentEpoch;
        require(essenceToken.mint(msg.sender, totalReward), "Essence reward minting failed");
    }

    /**
     * @dev Stakes Echo Essence to gain influence in prediction outcomes and accumulate governance power/rewards.
     * @param amount The amount of Essence to stake.
     */
    function stakeEssence(uint256 amount) public whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "Essence transfer failed");

        stakedEssence[msg.sender] = stakedEssence[msg.sender].add(amount);
        if (lastClaimEpoch[msg.sender] == 0) { // First time staking
            lastClaimEpoch[msg.sender] = currentEpoch;
        }
    }

    /**
     * @dev Unstakes Echo Essence.
     * @param amount The amount of Essence to unstake.
     */
    function unstakeEssence(uint256 amount) public whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(stakedEssence[msg.sender] >= amount, "Insufficient staked Essence");

        stakedEssence[msg.sender] = stakedEssence[msg.sender].sub(amount);
        require(essenceToken.transfer(msg.sender, amount), "Essence transfer failed");
    }

    // --- IV. Predictive & Influence Mechanics ---

    /**
     * @dev Users submit a prediction for a fragment's future evolution, backing it with Essence.
     *      This Essence contributes to the "odds" of a particular trait path.
     * @param fragmentId The ID of the Narrative Fragment.
     * @param targetTraitHash A keccak256 hash representing the predicted evolution path/target traits.
     * @param essenceAmount The amount of Echo Essence to stake on this prediction.
     */
    function submitPrediction(uint256 fragmentId, bytes32 targetTraitHash, uint256 essenceAmount) public whenNotPaused {
        require(block.timestamp < predictionWindowEnd, "Prediction window is closed");
        require(essenceAmount > 0, "Essence amount must be greater than zero");
        require(_exists(fragmentId), "Fragment does not exist");

        // Transfer Essence from the user to the contract
        require(essenceToken.transferFrom(msg.sender, address(this), essenceAmount), "Essence transfer failed for prediction");

        epochPredictions[fragmentId][currentEpoch][targetTraitHash] = epochPredictions[fragmentId][currentEpoch][targetTraitHash].add(essenceAmount);
        userPredictions[fragmentId][currentEpoch][msg.sender][targetTraitHash] = userPredictions[fragmentId][currentEpoch][msg.sender][targetTraitHash].add(essenceAmount);
        totalEssencePerFragmentPerEpoch[fragmentId][currentEpoch] = totalEssencePerFragmentPerEpoch[fragmentId][currentEpoch].add(essenceAmount);

        emit PredictionSubmitted(fragmentId, msg.sender, targetTraitHash, essenceAmount);
    }

    /**
     * @dev Allows users to change the target of an existing prediction, moving staked Essence.
     * @param fragmentId The ID of the Narrative Fragment.
     * @param oldTargetHash The keccak256 hash of the previously predicted evolution path.
     * @param newTargetHash The keccak256 hash of the new predicted evolution path.
     * @param essenceAmount The amount of Essence to reallocate. Must be <= previously staked amount.
     */
    function reallocatePrediction(uint256 fragmentId, bytes32 oldTargetHash, bytes32 newTargetHash, uint256 essenceAmount) public whenNotPaused {
        require(block.timestamp < predictionWindowEnd, "Prediction window is closed");
        require(essenceAmount > 0, "Essence amount must be greater than zero");
        require(oldTargetHash != newTargetHash, "Old and new target hashes cannot be the same");
        require(userPredictions[fragmentId][currentEpoch][msg.sender][oldTargetHash] >= essenceAmount, "Insufficient Essence staked for old target");

        epochPredictions[fragmentId][currentEpoch][oldTargetHash] = epochPredictions[fragmentId][currentEpoch][oldTargetHash].sub(essenceAmount);
        userPredictions[fragmentId][currentEpoch][msg.sender][oldTargetHash] = userPredictions[fragmentId][currentEpoch][msg.sender][oldTargetHash].sub(essenceAmount);

        epochPredictions[fragmentId][currentEpoch][newTargetHash] = epochPredictions[fragmentId][currentEpoch][newTargetHash].add(essenceAmount);
        userPredictions[fragmentId][currentEpoch][msg.sender][newTargetHash] = userPredictions[fragmentId][currentEpoch][msg.sender][newTargetHash].add(essenceAmount);

        // totalEssencePerFragmentPerEpoch remains unchanged as Essence is just reallocated
        emit PredictionReallocated(fragmentId, msg.sender, oldTargetHash, newTargetHash, essenceAmount);
    }

    /**
     * @dev Calculates and returns the current probabilistic odds for various trait evolutions
     *      for a fragment based on submitted predictions in the current epoch.
     *      Returns (targetTraitHash, percentage_of_total_essence) pairs.
     *      Note: This will return all predicted hashes. Off-chain UI will interpret these into trait names.
     *      For this example, it demonstrates a few static paths. A full implementation would dynamically
     *      collect all submitted target hashes for the given fragment and epoch.
     * @param fragmentId The ID of the Narrative Fragment.
     * @return An array of (bytes32 targetTraitHash, uint256 percentage) tuples.
     */
    function getFragmentPredictionOdds(uint256 fragmentId) public view returns (bytes32[] memory, uint256[] memory) {
        uint256 totalEssence = totalEssencePerFragmentPerEpoch[fragmentId][currentEpoch];
        if (totalEssence == 0) {
            return (new bytes32[](0), new uint256[](0));
        }

        // Example: Assume 3 potential paths for demonstration.
        // In a real system, you'd iterate through a list of known valid hashes or dynamically
        // track all unique hashes that received predictions in the current epoch.
        bytes32 path1 = keccak256(abi.encodePacked("STANDARD_EVOLUTION"));
        bytes32 path2 = keccak256(abi.encodePacked("ADAPTIVE_CHANGE"));
        bytes32 path3 = keccak256(abi.encodePacked("RADICAL_SHIFT"));

        bytes32[] memory paths = new bytes32[](3);
        uint256[] memory percentages = new uint256[](3);

        paths[0] = path1;
        percentages[0] = epochPredictions[fragmentId][currentEpoch][path1].mul(100).div(totalEssence);

        paths[1] = path2;
        percentages[1] = epochPredictions[fragmentId][currentEpoch][path2].mul(100).div(totalEssence);

        paths[2] = path3;
        percentages[2] = epochPredictions[fragmentId][currentEpoch][path3].mul(100).div(totalEssence);

        return (paths, percentages);
    }

    /**
     * @dev Returns the timestamp when prediction submissions close for the current epoch.
     * @return Timestamp in seconds.
     */
    function getPredictionWindowEndTime() public view returns (uint64) {
        return predictionWindowEnd;
    }

    // --- V. Fragment Evolution & Lore Progression ---

    /**
     * @dev Triggers the evolution of a fragment by its owner during the evolution window,
     *      based on epoch-finalized predictions and consuming Essence.
     *      The `chosenEvolutionHash` must be a valid and eligible path given the fragment's current state
     *      and the outcome of the previous prediction epoch.
     * @param fragmentId The ID of the Narrative Fragment to evolve.
     * @param chosenEvolutionHash The keccak256 hash representing the chosen evolution path.
     */
    function initiateFragmentEvolution(uint256 fragmentId, bytes32 chosenEvolutionHash) public whenNotPaused {
        require(msg.sender == ownerOf(fragmentId), "Only fragment owner can initiate evolution");
        require(block.timestamp >= predictionWindowEnd, "Evolution window not yet open");
        require(block.timestamp < evolutionWindowEnd, "Evolution window is closed");

        uint256 cost = getEvolutionCost(chosenEvolutionHash);
        require(cost > 0, "Invalid evolution path or no cost defined");
        require(essenceToken.transferFrom(msg.sender, address(this), cost), "Essence transfer failed for evolution");

        // --- Core Evolution Logic ---
        // This is where the magic happens. A mapping from `chosenEvolutionHash` to new traits
        // or a complex on-chain function that calculates new traits based on current traits + hash.
        // For simplicity, `_applyEvolution` is a placeholder. In a real system, this would:
        // 1. Parse `fragmentTraits[fragmentId]`.
        // 2. Use `chosenEvolutionHash` to look up rules for trait modification.
        // 3. Potentially use `oracleAddress` for an element of randomness (e.g., Chainlink VRF)
        //    if multiple outcomes have similar prediction odds.
        // 4. Construct the new JSON string for traits.
        string memory oldTraits = fragmentTraits[fragmentId];
        string memory newTraits = _applyEvolution(oldTraits, chosenEvolutionHash); 

        fragmentTraits[fragmentId] = newTraits;
        _setTokenURI(fragmentId, _calculateFragmentURI(fragmentId, newTraits)); // Update URI after traits change

        emit FragmentEvolved(fragmentId, chosenEvolutionHash, newTraits);
    }

    /**
     * @dev Internal function to apply an evolution based on current traits and the chosen evolution hash.
     *      This would involve complex parsing of JSON traits and applying rules.
     *      For demonstration, a simplified approach that concatenates the evolution.
     * @param currentTraitsJson Current traits of the fragment.
     * @param evolutionHash The hash of the chosen evolution path.
     * @return The new stringified JSON traits.
     */
    function _applyEvolution(string memory currentTraitsJson, bytes32 evolutionHash) internal pure returns (string memory) {
        // In a real application, this would parse `currentTraitsJson`,
        // apply rules based on `evolutionHash` (e.g., incrementing an attribute, changing a type),
        // and then re-serialize to JSON.
        // Example: `{"color": "red", "type": "seed"}` -> `{"color": "orange", "type": "sprout"}`
        return string(abi.encodePacked(currentTraitsJson, " -> EVOLVED_BY:", Strings.toHexString(uint256(evolutionHash))));
    }


    /**
     * @dev Returns a list of possible evolution outcome hashes for a fragment based on its current traits.
     *      This would typically consult a predefined "evolution tree" or rules engine.
     *      For simplicity, returns a static set of example paths.
     * @param fragmentId The ID of the Narrative Fragment.
     * @return An array of bytes32 hashes representing potential evolution paths.
     */
    function getPotentialEvolutionPaths(uint256 fragmentId) public view returns (bytes32[] memory) {
        // Here you would retrieve `fragmentTraits[fragmentId]` and based on those traits,
        // determine what evolutions are possible.
        // Example: If trait "type" is "seed", then "STANDARD_EVOLUTION" is possible.
        // If "energy" > 50, then "RADICAL_SHIFT" is possible.
        string memory currentTraits = fragmentTraits[fragmentId]; // Could influence possible paths

        bytes32[] memory paths = new bytes32[](3);
        paths[0] = keccak256(abi.encodePacked("STANDARD_EVOLUTION"));
        paths[1] = keccak256(abi.encodePacked("ADAPTIVE_CHANGE"));
        paths[2] = keccak256(abi.encodePacked("RADICAL_SHIFT"));
        return paths;
    }

    /**
     * @dev Returns the Echo Essence cost required to pursue a specific evolution path.
     * @param evolutionPathHash The keccak256 hash of the evolution path.
     * @return The Essence cost.
     */
    function getEvolutionCost(bytes32 evolutionPathHash) public view returns (uint256) {
        return evolutionPathCosts[evolutionPathHash];
    }

    /**
     * @dev A creative evolution where one fragment (`sourceFragmentId`) is "absorbed" by another (`targetFragmentId`).
     *      The source fragment is burned, and some of its traits (or an 'essence' representation) are merged
     *      into the target fragment, altering its traits. Requires Essence cost.
     * @param targetFragmentId The ID of the fragment that will absorb.
     * @param sourceFragmentId The ID of the fragment that will be absorbed (and burned).
     */
    function absorbEcho(uint256 targetFragmentId, uint256 sourceFragmentId) public whenNotPaused {
        require(msg.sender == ownerOf(targetFragmentId), "Only owner of target can absorb");
        require(msg.sender == ownerOf(sourceFragmentId), "Only owner of source can allow absorption");
        require(targetFragmentId != sourceFragmentId, "Cannot absorb itself");
        require(block.timestamp >= predictionWindowEnd && block.timestamp < evolutionWindowEnd, "Absorption only allowed during evolution window");

        // Cost for absorption (configurable system parameter)
        uint256 absorptionCost = systemParameters[keccak256(abi.encodePacked("ABSORPTION_COST"))];
        require(essenceToken.transferFrom(msg.sender, address(this), absorptionCost), "Essence transfer failed for absorption");

        // --- Core Absorption Logic ---
        // This is where traits from sourceFragmentId are processed and merged into targetFragmentId.
        // Example: target might gain 'strength' from source, or absorb a 'color' trait.
        string memory targetTraits = fragmentTraits[targetFragmentId];
        string memory sourceTraits = fragmentTraits[sourceFragmentId];

        string memory newTargetTraits = _applyAbsorption(targetTraits, sourceTraits); // Internal function for trait merging

        fragmentTraits[targetFragmentId] = newTargetTraits;
        _setTokenURI(targetFragmentId, _calculateFragmentURI(targetFragmentId, newTargetTraits));

        _burn(sourceFragmentId); // Burn the source fragment

        emit FragmentAbsorbed(targetFragmentId, sourceFragmentId);
    }

    /**
     * @dev Internal function to apply absorption logic.
     * @param targetTraitsJson Current traits of the target fragment.
     * @param sourceTraitsJson Traits of the source fragment being absorbed.
     * @return The new stringified JSON traits for the target fragment.
     */
    function _applyAbsorption(string memory targetTraitsJson, string memory sourceTraitsJson) internal pure returns (string memory) {
        // Example: simple concatenation, but this would be complex JSON merging and rule application.
        // E.g., `target.energy += source.energy / 2` or `target.color = source.color` if conditions met.
        return string(abi.encodePacked(targetTraitsJson, " -> ABSORBED(", sourceTraitsJson, ")"));
    }

    /**
     * @dev A fragment can "split," creating a new child fragment and potentially altering the parent's traits.
     *      Requires the parent fragment to have specific "splittable" traits and an Essence cost.
     * @param parentFragmentId The ID of the fragment that will split.
     * @param childInitialTraitsJson The initial stringified JSON traits for the newly minted child fragment.
     */
    function splitFragment(uint256 parentFragmentId, string calldata childInitialTraitsJson) public whenNotPaused {
        require(msg.sender == ownerOf(parentFragmentId), "Only owner of parent can split");
        require(block.timestamp >= predictionWindowEnd && block.timestamp < evolutionWindowEnd, "Splitting only allowed during evolution window");

        // Cost for splitting (configurable system parameter)
        uint256 splitCost = systemParameters[keccak256(abi.encodePacked("SPLIT_FRAGMENT_COST"))];
        require(essenceToken.transferFrom(msg.sender, address(this), splitCost), "Essence transfer failed for splitting");

        // --- Core Splitting Logic ---
        // Alter parent traits (e.g., reduce "energy_level", remove a trait that was "given" to the child)
        string memory oldParentTraits = fragmentTraits[parentFragmentId];
        string memory newParentTraits = _applySplitToParent(oldParentTraits, childInitialTraitsJson); // Logic for parent changes

        _fragmentTokenIds.increment();
        uint256 newChildId = _fragmentTokenIds.current();

        _safeMint(msg.sender, newChildId); // Mint new child to the owner of the parent
        fragmentTraits[newChildId] = childInitialTraitsJson; // Set child's traits
        _setTokenURI(newChildId, _calculateFragmentURI(newChildId, childInitialTraitsJson));

        fragmentTraits[parentFragmentId] = newParentTraits; // Update parent's traits
        _setTokenURI(parentFragmentId, _calculateFragmentURI(parentFragmentId, newParentTraits));

        emit FragmentSplit(parentFragmentId, newChildId, childInitialTraitsJson);
    }

    /**
     * @dev Internal function to apply splitting logic to the parent fragment.
     * @param parentTraitsJson Current traits of the parent fragment.
     * @param childTraitsJson Traits of the child fragment being created (to infer what was "given away").
     * @return The new stringified JSON traits for the parent fragment.
     */
    function _applySplitToParent(string memory parentTraitsJson, string memory childTraitsJson) internal pure returns (string memory) {
        // Example: parent loses some "mass" or "energy" that is now in the child.
        // `parent.energy -= child.energy`
        return string(abi.encodePacked(parentTraitsJson, " -> SPLIT_OFF(", childTraitsJson, ")"));
    }

    // --- VI. Governance & System Parameters (Lore Keepers DAO) ---

    /**
     * @dev Allows staked Essence holders to propose changes to core system parameters.
     *      Requires `minEssenceToPropose` staked Essence.
     * @param parameterKey A string identifier for the parameter (e.g., "EPOCH_DURATION", "PREDICTION_REWARD_PERCENTAGE").
     * @param newValue The new value for the parameter, as a string. (Note: parsing handled in `executeProposal`).
     */
    function proposeSystemParameterChange(string calldata parameterKey, string calldata newValue) public onlyLoreKeepers whenNotPaused {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        // Initialize hasVoted for the new proposal
        // Note: 'mapping in struct' is an anti-pattern for public storage if you want to iterate or delete
        // but for checking a single address it is fine and gas-efficient.
        proposals[proposalId] = Proposal({
            id: proposalId,
            parameterKey: parameterKey,
            newValue: newValue,
            creationEpoch: currentEpoch,
            voteEndTime: uint256(block.timestamp) + proposalVotingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false
            // hasVoted is not initialized here, but accessed as `proposals[id].hasVoted[voter]`
        });

        emit ProposalCreated(proposalId, msg.sender, parameterKey, newValue);
    }

    /**
     * @dev Allows staked Essence holders to vote on active governance proposals.
     *      Requires `minEssenceToPropose` staked Essence to participate.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a "yes" vote, false for a "no" vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public onlyLoreKeepers whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp < proposal.voteEndTime, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterPower = stakedEssence[msg.sender];
        require(voterPower > 0, "Must have staked Essence to vote");

        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(voterPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, voterPower);
    }

    /**
     * @dev Executes a proposal that has passed the voting period and met quorum.
     *      Anyone can call this function once conditions are met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "Voting period not yet ended");
        require(!proposal.executed, "Proposal already executed");

        // Quorum calculation: Total Essence staked in THIS contract is `essenceToken.balanceOf(address(this))`
        uint256 totalEssenceStakedInContract = essenceToken.balanceOf(address(this));
        require(totalEssenceStakedInContract > 0, "No Essence staked for quorum calculation");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        // Quorum: total votes must be at least `proposalQuorumPercentage` of total staked Essence in the contract
        require(totalVotes.mul(100) >= totalEssenceStakedInContract.mul(proposalQuorumPercentage), "Quorum not met"); 
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass (more 'no' votes or tie)");

        // Apply the parameter change
        // Note: This simplified implementation parses strings to uint256. A robust system
        // would have different proposal types for different data types (e.g., `proposeUintParameterChange`).
        bytes32 paramKeyHash = keccak256(abi.encodePacked(proposal.parameterKey));
        uint256 parsedValue = uint256(abi.decode(abi.encodePacked(proposal.newValue), (uint256)));

        if (paramKeyHash == keccak256(abi.encodePacked("EPOCH_DURATION"))) {
            epochDuration = uint64(parsedValue);
        } else if (paramKeyHash == keccak256(abi.encodePacked("PROPOSAL_VOTING_PERIOD"))) {
            proposalVotingPeriod = parsedValue;
        } else if (paramKeyHash == keccak256(abi.encodePacked("PROPOSAL_QUORUM_PERCENTAGE"))) {
            require(parsedValue <= 100, "Quorum percentage cannot exceed 100");
            proposalQuorumPercentage = parsedValue;
        } else if (paramKeyHash == keccak256(abi.encodePacked("MIN_ESSENCE_TO_PROPOSE"))) {
            minEssenceToPropose = parsedValue;
        } else if (paramKeyHash == keccak256(abi.encodePacked("MINT_FRAGMENT_COST"))) {
            systemParameters[keccak256(abi.encodePacked("MINT_FRAGMENT_COST"))] = parsedValue;
        } else if (paramKeyHash == keccak256(abi.encodePacked("ABSORPTION_COST"))) {
            systemParameters[keccak256(abi.encodePacked("ABSORPTION_COST"))] = parsedValue;
        } else if (paramKeyHash == keccak256(abi.encodePacked("SPLIT_FRAGMENT_COST"))) {
            systemParameters[keccak256(abi.encodePacked("SPLIT_FRAGMENT_COST"))] = parsedValue;
        } else if (paramKeyHash == keccak256(abi.encodePacked("BASE_EVOLUTION_COST"))) {
            systemParameters[keccak256(abi.encodePacked("BASE_EVOLUTION_COST"))] = parsedValue;
            // Update dependent evolution costs if desired, or make them separate proposals
            evolutionPathCosts[keccak256(abi.encodePacked("STANDARD_EVOLUTION"))] = parsedValue;
        } else {
            // Generic parameter update for uint256 type for any other registered parameter
            systemParameters[paramKeyHash] = parsedValue;
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Sets an address for a potential external data oracle (e.g., Chainlink VRF for more unpredictable outcomes).
     *      Only callable by the contract owner. A more decentralized approach would be via governance proposal.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) public onlyOwner whenNotPaused {
        require(_newOracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _newOracle;
    }

    // --- VII. Emergency & Maintenance ---

    /**
     * @dev Pauses certain critical functionalities of the contract in case of an emergency.
     *      Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract after an emergency.
     *      Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }
}

// Separate EchoEssence token contract. This would be deployed independently.
// For a real system, its `mint` function needs careful access control,
// typically allowing only specific contracts (like EtherealEchoes) to call it.
contract EchoEssence is ERC20, Ownable {
    constructor() ERC20("Echo Essence", "ESSENCE") Ownable(msg.sender) {
        // Initial mint for the deployer for testing/initial liquidity.
        // In a real scenario, this might be a small initial mint or a timelocked distribution.
        _mint(msg.sender, 1_000_000_000 * 10**decimals()); // 1 Billion ESSENCE
    }

    // Allow only trusted minters to mint more Essence (e.g., the EtherealEchoes contract itself)
    // The `_minter` address needs to be set after EtherealEchoes deployment.
    address public minter;

    function setMinter(address _minter) public onlyOwner {
        require(_minter != address(0), "Minter cannot be zero address");
        minter = _minter;
    }

    function mint(address to, uint256 amount) public returns (bool) {
        require(msg.sender == minter, "Only the designated minter can mint");
        _mint(to, amount);
        return true;
    }
}
```