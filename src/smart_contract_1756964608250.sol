Here's a Solidity smart contract named `AethelEngine` that implements a system for **Adaptive Digital Constructs (ADCs)**, which are dynamic NFTs that evolve based on decentralized curator consensus, coupled with a soulbound reputation system and dynamic pricing. This contract aims to be creative, advanced, and avoids direct duplication of common open-source patterns by integrating these concepts into a single, cohesive system.

---

## AethelEngine Smart Contract

The `AethelEngine` is a decentralized protocol designed for the creation, evolution, and curation of "Adaptive Digital Constructs" (ADCs). These ADCs are dynamic NFTs whose traits and value change over time, driven by a decentralized network of "Curators." The system incorporates a reputation-weighted governance model to simulate collective intelligence ("AI-driven" aspect) and a dynamic pricing mechanism.

### Outline:

**I. Core Infrastructure & System Setup**
*   `constructor`: Initializes the contract with basic parameters.
*   `updateSystemParameter`: Owner-only, updates core system constants.
*   `setExternalAddresses`: Owner-only, sets addresses for dependencies like `AethelToken`.
*   `pauseContract`: Emergency pause for critical operations.
*   `unpauseContract`: Unpause contract.

**II. Aethel Reputation (Non-transferable Score)**
*   `getReputationScore`: View, retrieves the reputation score for an address.
*   `_updateReputation`: Internal function to adjust reputation.

**III. Aethel Curatorship & Decentralized Governance (AI-simulated consensus)**
*   `stakeForCuratorship`: Users stake `AethelToken` to become a Curator.
*   `unstakeFromCuratorship`: Curators can unstake their tokens after a cooldown.
*   `proposeADC_EvolutionAction`: ADC owner proposes a trait evolution.
*   `proposeADC_PruningAction`: Curator proposes to prune (deactivate) an ADC.
*   `voteOnCuratorProposal`: Curators cast their reputation-weighted vote on active proposals.
*   `executeCuratorProposal`: Executes settled proposals, updating ADCs and adjusting reputation/rewards.
*   `getCuratorStakeAmount`: View, returns a curator's staked amount.
*   `getProposalDetails`: View, returns comprehensive details about a specific proposal.

**IV. Adaptive Digital Constructs (ADCs) - Dynamic NFTs**
*   `mintNewADC`: Mints a new Adaptive Digital Construct (ADC) with initial traits.
*   `getCurrentADCPrice`: View, calculates the dynamic price of an ADC.
*   `buyADC`: Allows users to purchase an ADC.
*   `getADC_Traits`: View, returns all traits of an ADC.
*   `getADC_EvolutionPoints`: View, returns evolution points of an ADC.
*   `getADC_PrestigeScore`: View, calculates and returns an ADC's prestige score.
*   `tokenURI`: Overrides ERC721 `tokenURI` for dynamic metadata generation.

**V. Epoch Management & Reward Distribution**
*   `advanceEpoch`: Triggers epoch end, processes proposals, and distributes rewards.
*   `claimCuratorRewards`: Curators claim their earned `AethelToken` rewards.
*   `getCurrentEpochDetails`: View, returns current epoch number and end time.
*   `getPendingCuratorRewards`: View, returns unclaimed rewards for a curator.

### Function Summary:

1.  **`constructor()`**: Initializes the contract, setting the owner, ERC-721 token details (`AADC`), and default values for various system parameters like minimum curator stake, fees, quorum percentages, and epoch duration.
2.  **`updateSystemParameter(bytes32 _paramName, uint256 _newValue)`**: An `owner`-only function to modify critical system parameters. This allows for dynamic tuning of the protocol's economics and governance rules post-deployment.
3.  **`setExternalAddresses(address _aethelTokenAddress)`**: An `owner`-only function to link the contract to the `AethelToken` (an ERC-20 token) which is essential for staking, fees, and rewards within the system.
4.  **`pauseContract()`**: An `owner`-only emergency function to temporarily halt sensitive operations within the contract, providing a safety mechanism in case of vulnerabilities or unexpected behavior.
5.  **`unpauseContract()`**: An `owner`-only function to reactivate the contract after it has been paused.
6.  **`getReputationScore(address _user)`**: A public view function that returns the non-transferable reputation score of a specified user, accumulated through successful curation.
7.  **`_updateReputation(address _user, int256 _amount)`**: An internal helper function to adjust a user's reputation score, used when curators perform actions (e.g., successful votes increase, failed votes decrease).
8.  **`stakeForCuratorship()`**: Allows any user to become a Curator by staking a minimum amount of `AethelToken`. Curators gain voting rights and become eligible for rewards.
9.  **`unstakeFromCuratorship()`**: Enables an active Curator to retrieve their staked `AethelToken` after a predefined cooldown period (e.g., one epoch), relinquishing their curatorship role.
10. **`proposeADC_EvolutionAction(uint256 _adcId, string memory _newTraitName, uint8 _newTraitLevel, string memory _actionRationale)`**: An ADC owner can propose an evolution for their NFT, suggesting a new trait or an upgrade to an existing one. Requires an `AethelToken` fee.
11. **`proposeADC_PruningAction(uint256 _adcId, string memory _actionRationale)`**: A Curator can propose to "prune" (deactivate) an ADC if they deem it no longer relevant or valuable to the ecosystem. Requires an `AethelToken` fee.
12. **`voteOnCuratorProposal(uint256 _proposalId, bool _support)`**: Allows active Curators to cast a vote (for or against) on an open proposal. Their vote's weight is determined by their current reputation score.
13. **`executeCuratorProposal(uint256 _proposalId)`**: Any user can call this function after a proposal's voting period has ended. If the proposal meets the required quorum and majority, its intended action (ADC evolution or pruning) is executed, and participating curators are registered for reputation adjustments.
14. **`getCuratorStakeAmount(address _curator)`**: A public view function to query the `AethelToken` amount currently staked by a specific curator.
15. **`getProposalDetails(uint256 _proposalId)`**: A public view function that provides comprehensive information about a specific proposal, including its type, target ADC, proposer, status, vote counts, and the proposed changes.
16. **`mintNewADC(string memory _initialTraitDescription)`**: Enables any user to mint a new ADC. This creates a new NFT with initial, base traits, requiring an `AethelToken` fee.
17. **`getCurrentADCPrice(uint256 _adcId)`**: A public view function that calculates the real-time dynamic price of an ADC. The price adjusts based on its evolution points, prestige score, and simulated market factors.
18. **`buyADC(uint256 _adcId)`**: Allows a user to purchase an existing ADC. The transaction occurs at the ADC's current dynamic price, and a portion of the payment is distributed to the previous owner, with the rest contributing to the protocol's reward pool.
19. **`getADC_Traits(uint256 _adcId)`**: A public view function that returns all currently active traits and their respective levels for a given ADC.
20. **`getADC_EvolutionPoints(uint256 _adcId)`**: A public view function that returns the total accumulated evolution points of an ADC, reflecting its developmental history.
21. **`getADC_PrestigeScore(uint256 _adcId)`**: A public view function that calculates and returns the "prestige" score of an ADC, influenced by its evolution, curator endorsements, and ownership history.
22. **`tokenURI(uint256 _tokenId)`**: Overrides the standard ERC-721 `tokenURI` function to generate dynamic, Base64-encoded JSON metadata. This metadata reflects the ADC's current traits, evolution points, and prestige, allowing the NFT to visually and semantically adapt.
23. **`advanceEpoch()`**: Can be called by anyone after the current epoch duration has passed. This function acts as the system's "heartbeat," processing all pending proposals, updating curator reputations based on their voting outcomes, distributing rewards, and initializing the next epoch.
24. **`claimCuratorRewards()`**: Allows Curators to claim their accumulated `AethelToken` rewards earned from successfully participating in the curation process.
25. **`getCurrentEpochDetails()`**: A public view function that returns the current epoch number and the timestamp when the current epoch is scheduled to conclude.
26. **`getPendingCuratorRewards(address _curator)`**: A public view function that returns the amount of `AethelToken` rewards that a specific curator has accrued but not yet claimed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AethelEngine
 * @dev A self-evolving, decentralized protocol for dynamic asset generation and reputation management.
 *      It features Adaptive Digital Constructs (ADCs) as dynamic NFTs that evolve based on decentralized
 *      curator consensus, driven by a reputation-weighted voting system. Curators earn reputation (soulbound)
 *      and rewards for effective curation, and ADCs have a dynamically adjusting price based on their
 *      evolution and prestige.
 *
 * Outline:
 * I. Core Infrastructure & System Setup
 * II. Aethel Reputation (Non-transferable Score)
 * III. Aethel Curatorship & Decentralized Governance (AI-simulated consensus)
 * IV. Adaptive Digital Constructs (ADCs) - Dynamic NFTs
 * V. Epoch Management & Reward Distribution
 *
 * Function Summary:
 *
 * I. Core Infrastructure & System Setup
 * 1.  constructor(): Initializes the contract with the first owner, ERC-721 details, and core system parameters.
 * 2.  updateSystemParameter(bytes32 _paramName, uint256 _newValue): Owner-only. Allows updating key system
 *     constants like minimum curator stake, evolution quorum, epoch duration, etc.
 * 3.  setExternalAddresses(address _aethelTokenAddress): Owner-only. Sets the address for the
 *     ERC-20 AethelToken, which is used for staking, fees, and rewards.
 * 4.  pauseContract(): Owner-only. Triggers an emergency pause, halting critical state-changing functions.
 * 5.  unpauseContract(): Owner-only. Unpauses the contract, re-enabling paused functions.
 *
 * II. Aethel Reputation (Non-transferable Score)
 * 6.  getReputationScore(address _user): View. Returns the current reputation score of a given address.
 * 7.  _updateReputation(address _user, int256 _amount): Internal. Adjusts a user's reputation score.
 *
 * III. Aethel Curatorship & Decentralized Governance (AI-simulated consensus)
 * 8.  stakeForCuratorship(): Allows users to stake AethelTokens to become a Curator, granting voting rights
 *     and eligibility for rewards. Requires a minimum stake and reputation.
 * 9.  unstakeFromCuratorship(): Allows Curators to unstake their tokens after a predefined cooldown period
 *     or epoch, revoking their curatorship status.
 * 10. proposeADC_EvolutionAction(uint256 _adcId, string memory _newTraitName, uint8 _newTraitLevel, string memory _actionRationale):
 *     ADC owner proposes an evolution for their ADC (e.g., adding a new trait, upgrading an existing one).
 *     Requires a fee in AethelToken.
 * 11. proposeADC_PruningAction(uint256 _adcId, string memory _actionRationale):
 *     A Curator proposes to "prune" (deactivate/deprecate) an ADC deemed undesirable or irrelevant.
 *     Requires a fee in AethelToken.
 * 12. voteOnCuratorProposal(uint256 _proposalId, bool _support): Curators cast their reputation-weighted vote
 *     (for or against) on an active proposal.
 * 13. executeCuratorProposal(uint256 _proposalId): Allows anyone to trigger the execution of a proposal
 *     once its voting period has ended and if it has met the required quorum and majority. This updates ADCs,
 *     and adjusts curator reputation/rewards.
 * 14. getCuratorStakeAmount(address _curator): View. Returns the amount of AethelToken staked by a curator.
 * 15. getProposalDetails(uint256 _proposalId): View. Returns comprehensive details about a specific proposal,
 *     including its status, votes, and target.
 *
 * IV. Adaptive Digital Constructs (ADCs) - Dynamic NFTs
 * 16. mintNewADC(string memory _initialTraitDescription): Allows any user to mint a brand new ADC with an
 *     initial set of characteristics. Requires a fee in AethelToken.
 * 17. getCurrentADCPrice(uint256 _adcId): View. Calculates the dynamic price of an ADC based on its
 *     evolution level, prestige score, and market factors.
 * 18. buyADC(uint256 _adcId): Allows a user to purchase an ADC at its current dynamic price.
 * 19. getADC_Traits(uint256 _adcId): View. Returns the current traits and their levels for a given ADC.
 * 20. getADC_EvolutionPoints(uint256 _adcId): View. Returns evolution points of an ADC.
 * 21. getADC_PrestigeScore(uint256 _adcId): View. Calculates and returns the prestige score of an ADC,
 *     influenced by its evolution, curator endorsements, and historical ownership.
 * 22. tokenURI(uint256 _tokenId): Overrides the ERC721 standard `tokenURI` to generate dynamic JSON metadata
 *     reflecting the ADC's current traits and evolution state.
 *
 * V. Epoch Management & Reward Distribution
 * 23. advanceEpoch(): Can be called by anyone after the current epoch has ended. This function processes all
 *     settled proposals, updates reputation scores, distributes rewards to Curators, and initiates the next epoch.
 * 24. claimCuratorRewards(): Allows Curators to claim their accrued AethelToken rewards from successful curation.
 * 25. getCurrentEpochDetails(): View. Returns the current epoch number and its end timestamp.
 * 26. getPendingCuratorRewards(address _curator): View. Returns unclaimed rewards for a curator.
 */
contract AethelEngine is ERC721, ERC721Burnable, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    // --- I. Core Infrastructure & System Setup ---

    IERC20 public aethelToken; // The ERC20 token used for staking, fees, and rewards

    // System parameters, configurable by owner
    mapping(bytes32 => uint256) public systemParameters;

    // Parameter names for easy reference
    bytes32 constant MIN_CURATOR_STAKE = "MIN_CURATOR_STAKE";
    bytes32 constant EVOLUTION_FEE = "EVOLUTION_FEE";
    bytes32 constant PRUNING_FEE = "PRUNING_FEE";
    bytes32 constant MINT_ADC_FEE = "MINT_ADC_FEE";
    bytes32 constant EVOLUTION_VOTE_QUORUM_PERCENT = "EVOLUTION_VOTE_QUORUM_PERCENT"; // e.g., 5000 for 50%
    bytes32 constant PRUNING_VOTE_QUORUM_PERCENT = "PRUNING_VOTE_QUORUM_PERCENT"; // e.g., 6000 for 60%
    bytes32 constant EPOCH_DURATION = "EPOCH_DURATION"; // in seconds
    bytes32 constant REPUTATION_GAIN_PER_SUCCESSFUL_VOTE = "REPUTATION_GAIN_PER_SUCCESSFUL_VOTE";
    bytes32 constant REPUTATION_LOSS_PER_FAILED_VOTE = "REPUTATION_LOSS_PER_FAILED_VOTE";
    bytes32 constant BASE_ADC_PRICE = "BASE_ADC_PRICE";
    bytes32 constant EVOLUTION_POINT_COST = "EVOLUTION_POINT_COST"; // AethelToken cost for 1 evolution point in price calculation
    bytes32 constant REWARD_POOL_SHARE_PERCENT = "REWARD_POOL_SHARE_PERCENT"; // % of fees to reward pool

    // Events
    event SystemParameterUpdated(bytes32 indexed paramName, uint256 oldValue, uint256 newValue);
    event ExternalAddressSet(string indexed name, address indexed newAddress);
    event ReputationUpdated(address indexed user, int256 change, uint256 newScore);
    event CuratorStaked(address indexed curator, uint256 amount);
    event CuratorUnstaked(address indexed curator, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed adcId, uint8 proposalType, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ADC_Minted(uint256 indexed adcId, address indexed owner, string initialTraits);
    event ADC_Evolved(uint252 indexed adcId, string traitName, uint8 newLevel);
    event ADC_Pruned(uint256 indexed adcId);
    event ADC_Purchased(uint256 indexed adcId, address indexed buyer, uint256 price);
    event EpochAdvanced(uint256 indexed epochNumber, uint256 endTime);
    event RewardsClaimed(address indexed curator, uint256 amount);


    constructor(address _owner) ERC721("AethelEngine ADC", "AADC") Ownable(_owner) {
        // Initialize default system parameters
        systemParameters[MIN_CURATOR_STAKE] = 1000 * 10 ** 18; // 1000 AethelTokens (assuming 18 decimals)
        systemParameters[EVOLUTION_FEE] = 50 * 10 ** 18; // 50 AethelTokens
        systemParameters[PRUNING_FEE] = 10 * 10 ** 18; // 10 AethelTokens
        systemParameters[MINT_ADC_FEE] = 200 * 10 ** 18; // 200 AethelTokens
        systemParameters[EVOLUTION_VOTE_QUORUM_PERCENT] = 5000; // 50.00% (value / 10000)
        systemParameters[PRUNING_VOTE_QUORUM_PERCENT] = 6000; // 60.00%
        systemParameters[EPOCH_DURATION] = 7 days; // 7 days in seconds
        systemParameters[REPUTATION_GAIN_PER_SUCCESSFUL_VOTE] = 100; // 1.00 reputation (assuming 2 decimals, or 100 base units)
        systemParameters[REPUTATION_LOSS_PER_FAILED_VOTE] = 50; // 0.50 reputation
        systemParameters[BASE_ADC_PRICE] = 1000 * 10 ** 18; // 1000 AethelTokens
        systemParameters[EVOLUTION_POINT_COST] = 5 * 10 ** 18; // 5 AethelTokens
        systemParameters[REWARD_POOL_SHARE_PERCENT] = 2000; // 20.00% of fees go to reward pool

        // Set initial epoch
        currentEpoch.number = 1;
        currentEpoch.endTime = block.timestamp + systemParameters[EPOCH_DURATION];
    }

    modifier onlyCurator() {
        require(curatorStakes[msg.sender] >= systemParameters[MIN_CURATOR_STAKE], "AethelEngine: Not a curator or insufficient stake");
        _;
    }

    /**
     * @dev Allows the owner to update key system parameters.
     * @param _paramName The name of the parameter to update (e.g., "MIN_CURATOR_STAKE").
     * @param _newValue The new value for the parameter.
     */
    function updateSystemParameter(bytes32 _paramName, uint256 _newValue) external onlyOwner {
        uint256 oldValue = systemParameters[_paramName];
        systemParameters[_paramName] = _newValue;
        emit SystemParameterUpdated(_paramName, oldValue, _newValue);
    }

    /**
     * @dev Allows the owner to set the address of external contracts like AethelToken.
     * @param _aethelTokenAddress The address of the AethelToken contract.
     */
    function setExternalAddresses(address _aethelTokenAddress) external onlyOwner {
        require(_aethelTokenAddress != address(0), "AethelEngine: Zero address for AethelToken");
        aethelToken = IERC20(_aethelTokenAddress);
        emit ExternalAddressSet("AethelToken", _aethelTokenAddress);
    }

    /**
     * @dev See {Ownable-pause}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev See {Ownable-unpause}.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }


    // --- II. Aethel Reputation (Non-transferable Score) ---

    // Reputation score for each address (effectively a Soulbound score)
    mapping(address => uint256) public reputationScores;

    /**
     * @dev Returns the current reputation score of a given user.
     * @param _user The address whose reputation score is to be retrieved.
     * @return The reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address whose reputation to update.
     * @param _amount The amount to add or subtract (can be negative).
     */
    function _updateReputation(address _user, int256 _amount) internal {
        uint256 currentScore = reputationScores[_user];
        if (_amount > 0) {
            reputationScores[_user] = currentScore + uint256(_amount);
        } else {
            reputationScores[_user] = (currentScore < uint256(-_amount)) ? 0 : currentScore - uint256(-_amount);
        }
        emit ReputationUpdated(_user, _amount, reputationScores[_user]);
    }


    // --- III. Aethel Curatorship & Decentralized Governance ---

    // Curator stakes
    mapping(address => uint256) public curatorStakes;
    mapping(address => uint256) public curatorCooldownEndEpoch; // Epoch number when curator can unstake

    // Proposals
    uint256 public nextProposalId = 1;

    enum ProposalType { Evolution, Pruning }
    enum ProposalStatus { Pending, Active, Executed, Rejected }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        uint256 adcId;
        address proposer;
        uint256 epochCreated;
        uint256 votingEndTime; // End of current epoch
        ProposalStatus status;
        string rationale;

        // For Evolution proposals
        string newTraitName;
        uint8 newTraitLevel;

        // Voting data (reputation-weighted)
        uint256 totalReputationFor;
        uint256 totalReputationAgainst;
        mapping(address => bool) hasVoted; // Tracks if a curator has voted
        mapping(address => bool) voteSupport; // True for 'for', false for 'against'
        address[] voters; // List of addresses who voted on this proposal to iterate for reward distribution
    }
    mapping(uint256 => Proposal) public proposals;
    uint256[] public activeProposalsInEpoch; // Tracks proposals active in the current epoch

    // To prevent immediate unstaking after staking
    uint256 public constant UNSTAKE_COOLDOWN_EPOCHS = 1; // Unstake after 1 epoch

    /**
     * @dev Allows users to stake AethelTokens to become a Curator.
     *      Requires a minimum stake. Reputation (positive score) is a soft requirement for influence.
     */
    function stakeForCuratorship() external nonReentrant whenNotPaused {
        require(aethelToken != IERC20(address(0)), "AethelEngine: AethelToken not set");
        uint256 minStake = systemParameters[MIN_CURATOR_STAKE];
        require(aethelToken.transferFrom(msg.sender, address(this), minStake), "AethelEngine: Token transfer failed for stake");
        
        curatorStakes[msg.sender] += minStake;
        curatorCooldownEndEpoch[msg.sender] = currentEpoch.number + UNSTAKE_COOLDOWN_EPOCHS; // Can unstake after this epoch ends

        emit CuratorStaked(msg.sender, minStake);
    }

    /**
     * @dev Allows Curators to unstake their tokens.
     *      Requires a cooldown period after staking or last unstake.
     */
    function unstakeFromCuratorship() external nonReentrant whenNotPaused onlyCurator {
        require(curatorCooldownEndEpoch[msg.sender] <= currentEpoch.number, "AethelEngine: Cooldown period active.");
        uint256 stake = curatorStakes[msg.sender];
        require(stake > 0, "AethelEngine: No active stake found.");

        curatorStakes[msg.sender] = 0; // Reset stake
        curatorCooldownEndEpoch[msg.sender] = 0; // Reset cooldown

        require(aethelToken.transfer(msg.sender, stake), "AethelEngine: Token transfer failed for unstake");
        emit CuratorUnstaked(msg.sender, stake);
    }

    /**
     * @dev An ADC owner proposes an evolution (add/upgrade a trait) for their ADC.
     * @param _adcId The ID of the ADC to evolve.
     * @param _newTraitName The name of the trait to add/upgrade.
     * @param _newTraitLevel The target level for the trait.
     * @param _actionRationale A description of why this evolution is proposed.
     */
    function proposeADC_EvolutionAction(
        uint256 _adcId,
        string memory _newTraitName,
        uint8 _newTraitLevel,
        string memory _actionRationale
    ) external nonReentrant whenNotPaused {
        require(_exists(_adcId), "AethelEngine: ADC does not exist.");
        require(ownerOf(_adcId) == msg.sender, "AethelEngine: Only ADC owner can propose evolution.");
        require(_newTraitLevel > 0, "AethelEngine: Trait level must be positive.");
        
        uint256 evolutionFee = systemParameters[EVOLUTION_FEE];
        require(aethelToken.transferFrom(msg.sender, address(this), evolutionFee), "AethelEngine: Evolution fee transfer failed.");
        _addToRewardPool(evolutionFee); // Add fee to reward pool

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.Evolution;
        newProposal.adcId = _adcId;
        newProposal.proposer = msg.sender;
        newProposal.epochCreated = currentEpoch.number;
        newProposal.votingEndTime = currentEpoch.endTime;
        newProposal.status = ProposalStatus.Active;
        newProposal.rationale = _actionRationale;
        newProposal.newTraitName = _newTraitName;
        newProposal.newTraitLevel = _newTraitLevel;

        activeProposalsInEpoch.push(proposalId);
        emit ProposalCreated(proposalId, _adcId, uint8(ProposalType.Evolution), msg.sender);
    }

    /**
     * @dev A Curator proposes to "prune" (deactivate/deprecate) an ADC.
     * @param _adcId The ID of the ADC to prune.
     * @param _actionRationale A description of why this pruning is proposed.
     */
    function proposeADC_PruningAction(
        uint256 _adcId,
        string memory _actionRationale
    ) external nonReentrant whenNotPaused onlyCurator {
        require(_exists(_adcId), "AethelEngine: ADC does not exist.");
        
        uint256 pruningFee = systemParameters[PRUNING_FEE];
        require(aethelToken.transferFrom(msg.sender, address(this), pruningFee), "AethelEngine: Pruning fee transfer failed.");
        _addToRewardPool(pruningFee); // Add fee to reward pool

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.Pruning;
        newProposal.adcId = _adcId;
        newProposal.proposer = msg.sender;
        newProposal.epochCreated = currentEpoch.number;
        newProposal.votingEndTime = currentEpoch.endTime;
        newProposal.status = ProposalStatus.Active;
        newProposal.rationale = _actionRationale;

        activeProposalsInEpoch.push(proposalId);
        emit ProposalCreated(proposalId, _adcId, uint8(ProposalType.Pruning), msg.sender);
    }

    /**
     * @dev Curators cast their reputation-weighted vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True if voting 'for', false if voting 'against'.
     */
    function voteOnCuratorProposal(uint256 _proposalId, bool _support) external nonReentrant whenNotPaused onlyCurator {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "AethelEngine: Proposal not active.");
        require(block.timestamp <= proposal.votingEndTime, "AethelEngine: Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "AethelEngine: Already voted on this proposal.");

        uint256 voterReputation = reputationScores[msg.sender];
        require(voterReputation > 0, "AethelEngine: Voter must have reputation.");

        if (_support) {
            proposal.totalReputationFor += voterReputation;
        } else {
            proposal.totalReputationAgainst += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;
        proposal.voteSupport[msg.sender] = _support;
        proposal.voters.push(msg.sender); // Store voter for later reward/reputation adjustment

        emit VoteCast(_proposalId, msg.sender, _support, voterReputation);
    }

    /**
     * @dev Allows anyone to trigger the execution of a proposal once its voting period has ended
     *      and if it has met the required quorum and majority. This updates ADCs, and adjusts
     *      curator reputation/rewards. This function can be called before `advanceEpoch`
     *      to settle proposals individually.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeCuratorProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "AethelEngine: Proposal not active or already executed.");
        require(block.timestamp > proposal.votingEndTime, "AethelEngine: Voting period not ended yet.");

        uint256 totalReputationInVote = proposal.totalReputationFor + proposal.totalReputationAgainst;
        require(totalReputationInVote > 0, "AethelEngine: No votes cast on this proposal.");

        uint256 quorumPercentage = (proposal.proposalType == ProposalType.Evolution) ?
            systemParameters[EVOLUTION_VOTE_QUORUM_PERCENT] : systemParameters[PRUNING_VOTE_QUORUM_PERCENT];
        
        uint256 minQuorumReputation = (totalReputationInVote * quorumPercentage) / 10000;
        require(totalReputationInVote >= minQuorumReputation, "AethelEngine: Quorum not met.");

        bool proposalPassed = proposal.totalReputationFor > proposal.totalReputationAgainst;

        if (proposalPassed) {
            if (proposal.proposalType == ProposalType.Evolution) {
                _applyADC_Evolution(proposal.adcId, proposal.newTraitName, proposal.newTraitLevel);
            } else if (proposal.proposalType == ProposalType.Pruning) {
                _pruneADC(proposal.adcId);
            }
            proposal.status = ProposalStatus.Executed;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }

        // Adjust curator reputations for this proposal
        _adjustReputationsAndQueueRewards(proposalId, proposalPassed);

        emit ProposalExecuted(_proposalId, proposalPassed);
    }

    /**
     * @dev Internal function to adjust reputation and queue rewards after a proposal is settled.
     * @param _proposalId The ID of the settled proposal.
     * @param _proposalPassed Whether the proposal passed or failed.
     */
    function _adjustReputationsAndQueueRewards(uint256 _proposalId, bool _proposalPassed) internal {
        Proposal storage proposal = proposals[_proposalId];
        uint256 rewardAmountPerReputationPoint = (currentEpoch.totalRewardPool > 0 && currentEpoch.totalReputationForSuccessfulCurators > 0) ? 
            (currentEpoch.totalRewardPool / currentEpoch.totalReputationForSuccessfulCurators) : 0;

        for (uint256 i = 0; i < proposal.voters.length; i++) {
            address voter = proposal.voters[i];
            bool votedWithMajority = (proposal.voteSupport[voter] == _proposalPassed);

            if (votedWithMajority) {
                _updateReputation(voter, int256(systemParameters[REPUTATION_GAIN_PER_SUCCESSFUL_VOTE]));
                // Queue rewards for successful voters in the current epoch's reward pool
                // Simplified: rewards based on reputation at time of voting for this epoch
                pendingCuratorRewards[voter] += (reputationScores[voter] * rewardAmountPerReputationPoint);
            } else {
                _updateReputation(voter, -int256(systemParameters[REPUTATION_LOSS_PER_FAILED_VOTE]));
            }
        }
    }

    /**
     * @dev Returns the amount of AethelToken staked by a curator.
     * @param _curator The address of the curator.
     * @return The staked amount.
     */
    function getCuratorStakeAmount(address _curator) public view returns (uint256) {
        return curatorStakes[_curator];
    }

    /**
     * @dev Returns comprehensive details about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        public view
        returns (
            uint256 id,
            ProposalType proposalType,
            uint256 adcId,
            address proposer,
            uint256 epochCreated,
            uint256 votingEndTime,
            ProposalStatus status,
            string memory rationale,
            string memory newTraitName,
            uint8 newTraitLevel,
            uint256 totalReputationFor,
            uint256 totalReputationAgainst
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposalType,
            proposal.adcId,
            proposal.proposer,
            proposal.epochCreated,
            proposal.votingEndTime,
            proposal.status,
            proposal.rationale,
            proposal.newTraitName,
            proposal.newTraitLevel,
            proposal.totalReputationFor,
            proposal.totalReputationAgainst
        );
    }


    // --- IV. Adaptive Digital Constructs (ADCs) - Dynamic NFTs ---

    struct ADC_Data {
        bool isActive; // Can be set to false if pruned
        uint256 evolutionPoints;
        uint256 prestigeScore;
        uint256 lastPurchasePrice; // For dynamic pricing history
        mapping(string => uint8) traits; // traitName => traitLevel
        string[] traitNames; // To iterate over traits
    }
    mapping(uint256 => ADC_Data) public adcData;
    uint256 private _nextTokenId = 0; // Start from 1, so the first minted ID is 1.

    /**
     * @dev Mints a new Adaptive Digital Construct (ADC).
     * @param _initialTraitDescription A base description for the ADC, inspiring its initial traits.
     *      This is a placeholder for more complex initial trait generation.
     */
    function mintNewADC(string memory _initialTraitDescription) external nonReentrant whenNotPaused returns (uint256) {
        require(aethelToken != IERC20(address(0)), "AethelEngine: AethelToken not set");
        uint256 mintFee = systemParameters[MINT_ADC_FEE];
        require(aethelToken.transferFrom(msg.sender, address(this), mintFee), "AethelEngine: Mint fee transfer failed.");
        _addToRewardPool(mintFee); // Add fee to reward pool

        uint256 newTokenId = ++_nextTokenId;
        _mint(msg.sender, newTokenId);

        ADC_Data storage newADC = adcData[newTokenId];
        newADC.isActive = true;
        newADC.evolutionPoints = 0;
        newADC.prestigeScore = 100; // Base prestige
        newADC.lastPurchasePrice = mintFee; // Initial price based on mint fee

        // Example: Parse _initialTraitDescription to set initial traits
        // For simplicity, let's just add a generic "Origin" trait and "Potential"
        newADC.traits["Origin"] = 1;
        newADC.traitNames.push("Origin");
        newADC.traits["Potential"] = 1;
        newADC.traitNames.push("Potential");
        // In a real system, this would involve more sophisticated logic or a curated list.

        emit ADC_Minted(newTokenId, msg.sender, _initialTraitDescription);
        return newTokenId;
    }

    /**
     * @dev Internal function to apply an evolution to an ADC.
     * @param _adcId The ID of the ADC to evolve.
     * @param _traitName The name of the trait to update/add.
     * @param _newLevel The new level for the trait.
     */
    function _applyADC_Evolution(uint256 _adcId, string memory _traitName, uint8 _newLevel) internal {
        ADC_Data storage adc = adcData[_adcId];
        require(adc.isActive, "AethelEngine: ADC is not active.");

        // Check if trait already exists, if not, add it to traitNames array
        if (adc.traits[_traitName] == 0) { // Trait does not exist, or level is 0
            bool found = false;
            for (uint256 i = 0; i < adc.traitNames.length; i++) {
                if (keccak256(abi.encodePacked(adc.traitNames[i])) == keccak256(abi.encodePacked(_traitName))) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                adc.traitNames.push(_traitName);
            }
        }
        adc.traits[_traitName] = _newLevel;
        adc.evolutionPoints += _newLevel; // Evolution points accumulate based on new trait level
        adc.prestigeScore += _newLevel * 10; // Increase prestige for evolution

        emit ADC_Evolved(_adcId, _traitName, _newLevel);
    }

    /**
     * @dev Internal function to prune an ADC (set isActive to false).
     * @param _adcId The ID of the ADC to prune.
     */
    function _pruneADC(uint256 _adcId) internal {
        ADC_Data storage adc = adcData[_adcId];
        require(adc.isActive, "AethelEngine: ADC is already pruned.");
        adc.isActive = false;
        // Optionally, burn the NFT or prevent future transfers. For now, just mark inactive.
        emit ADC_Pruned(_adcId);
    }

    /**
     * @dev Calculates the dynamic price of an ADC based on its evolution level, prestige, and market factors.
     * @param _adcId The ID of the ADC.
     * @return The calculated price in AethelTokens.
     */
    function getCurrentADCPrice(uint256 _adcId) public view returns (uint256) {
        require(_exists(_adcId), "AethelEngine: ADC does not exist.");
        ADC_Data storage adc = adcData[_adcId];
        require(adc.isActive, "AethelEngine: ADC is inactive.");

        uint256 basePrice = systemParameters[BASE_ADC_PRICE];
        
        // Price increases with evolution points and prestige
        uint256 dynamicPrice = basePrice + (adc.evolutionPoints * systemParameters[EVOLUTION_POINT_COST]);
        // Prestige contributes directly to the price, assuming 10^18 for full token, so 1 prestige point = 0.01 AethelToken
        dynamicPrice += (adc.prestigeScore * (10 ** 18)) / 100;

        // Add a demand factor: If last purchase was recent and price increased, slight further boost.
        // This is a very simplified demand model.
        // In a real system, this would be more complex, potentially involving a bonding curve or oracle data.
        if (adc.lastPurchasePrice > 0 && dynamicPrice > adc.lastPurchasePrice) {
            dynamicPrice = (dynamicPrice * 105) / 100; // 5% boost for positive momentum
        }
        
        return dynamicPrice;
    }

    /**
     * @dev Allows users to purchase an ADC at its current dynamic price.
     * @param _adcId The ID of the ADC to purchase.
     */
    function buyADC(uint256 _adcId) external nonReentrant whenNotPaused {
        require(_exists(_adcId), "AethelEngine: ADC does not exist.");
        require(ownerOf(_adcId) != msg.sender, "AethelEngine: Cannot buy your own ADC.");
        ADC_Data storage adc = adcData[_adcId];
        require(adc.isActive, "AethelEngine: ADC is inactive.");

        uint256 price = getCurrentADCPrice(_adcId);
        require(aethelToken.transferFrom(msg.sender, address(this), price), "AethelEngine: Token transfer failed for purchase.");

        address previousOwner = ownerOf(_adcId);
        _transfer(previousOwner, msg.sender, _adcId); // Transfer NFT

        adc.lastPurchasePrice = price; // Update last purchase price for dynamic pricing

        // Distribute purchase price: previous owner gets a portion, rest goes to protocol (reward pool, treasury)
        uint256 ownerShare = (price * 80) / 100; // 80% to previous owner
        uint256 protocolShare = price - ownerShare;
        
        require(aethelToken.transfer(previousOwner, ownerShare), "AethelEngine: Failed to transfer owner share.");
        // Protocol share is already in this contract from transferFrom, stays in reward pool or treasury.
        
        _addToRewardPool(protocolShare); // Add to reward pool

        emit ADC_Purchased(_adcId, msg.sender, price);
    }
    
    /**
     * @dev Returns the current traits and their levels for a given ADC.
     * @param _adcId The ID of the ADC.
     * @return An array of trait names and an array of their corresponding levels.
     */
    function getADC_Traits(uint256 _adcId) public view returns (string[] memory traitNames, uint8[] memory traitLevels) {
        require(_exists(_adcId), "AethelEngine: ADC does not exist.");
        ADC_Data storage adc = adcData[_adcId];

        traitNames = new string[](adc.traitNames.length);
        traitLevels = new uint8[](adc.traitNames.length);

        for (uint256 i = 0; i < adc.traitNames.length; i++) {
            traitNames[i] = adc.traitNames[i];
            traitLevels[i] = adc.traits[adc.traitNames[i]];
        }
        return (traitNames, traitLevels);
    }

    /**
     * @dev Returns the accumulated evolution points for an ADC.
     * @param _adcId The ID of the ADC.
     * @return The number of evolution points.
     */
    function getADC_EvolutionPoints(uint256 _adcId) public view returns (uint256) {
        require(_exists(_adcId), "AethelEngine: ADC does not exist.");
        return adcData[_adcId].evolutionPoints;
    }

    /**
     * @dev Calculates and returns the prestige score of an ADC.
     * @param _adcId The ID of the ADC.
     * @return The prestige score.
     */
    function getADC_PrestigeScore(uint256 _adcId) public view returns (uint256) {
        require(_exists(_adcId), "AethelEngine: ADC does not exist.");
        return adcData[_adcId].prestigeScore;
    }

    /**
     * @dev See {ERC721-tokenURI}. Generates dynamic JSON metadata for ADCs.
     * @param _tokenId The ID of the ADC.
     * @return The URI pointing to the JSON metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        ADC_Data storage adc = adcData[_tokenId];

        string memory name = string(abi.encodePacked("Aethel ADC #", _tokenId.toString()));
        string memory description = string(abi.encodePacked("An Adaptive Digital Construct (ADC) that evolves through decentralized curation. Current evolution points: ", adc.evolutionPoints.toString(), ". Prestige: ", adc.prestigeScore.toString(), ". Active: ", adc.isActive ? "Yes" : "No", "."));
        
        string memory traitsJson = "[";
        for (uint256 i = 0; i < adc.traitNames.length; i++) {
            traitsJson = string(abi.encodePacked(
                traitsJson,
                '{"trait_type": "', adc.traitNames[i], '", "value": "', adc.traits[adc.traitNames[i]].toString(), '"}'
            ));
            if (i < adc.traitNames.length - 1) {
                traitsJson = string(abi.encodePacked(traitsJson, ","));
            }
        }
        traitsJson = string(abi.encodePacked(traitsJson, "]"));

        // Placeholder image. In a real dApp, this would be dynamically generated or pointed to evolving IPFS content.
        string memory imageURI = "ipfs://QmbnQ4W4X5T6K7G8H9J0L1M2N3O4P5Q6R7S8T9U0V"; 

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', name, '", "description": "', description, '", "image": "', imageURI, '", "attributes": ', traitsJson, '}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }


    // --- V. Epoch Management & Reward Distribution ---

    struct Epoch {
        uint256 number;
        uint256 endTime;
        uint256 totalRewardPool; // AethelTokens accumulated for rewards
        // We will directly track pending rewards per curator, instead of recalculating totalSuccessfulReputation per epoch
    }
    Epoch public currentEpoch;

    mapping(address => uint256) public pendingCuratorRewards; // Rewards accumulated per curator

    /**
     * @dev Can be called by anyone after the current epoch has ended.
     *      Processes all settled proposals, updates reputation scores, and initiates the next epoch.
     *      Individual proposal execution and reward queuing is handled when `executeCuratorProposal` is called.
     */
    function advanceEpoch() external nonReentrant whenNotPaused {
        require(block.timestamp >= currentEpoch.endTime, "AethelEngine: Epoch not yet ended.");

        // Process any active proposals that have expired and haven't been executed yet
        for (uint256 i = 0; i < activeProposalsInEpoch.length; i++) {
            uint256 proposalId = activeProposalsInEpoch[i];
            Proposal storage proposal = proposals[proposalId];

            if (proposal.votingEndTime <= block.timestamp && proposal.status == ProposalStatus.Active) {
                // Execute overdue proposals automatically
                _executeExpiredProposal(proposalId);
            }
        }

        // Clear proposals that belonged to the previous epoch.
        // This is a simplification; in a production system, proposals might be archived.
        // For efficiency, we just reset the array.
        delete activeProposalsInEpoch; 

        // Prepare for the next epoch
        currentEpoch.number++;
        currentEpoch.endTime = block.timestamp + systemParameters[EPOCH_DURATION];
        currentEpoch.totalRewardPool = 0; // Reset for the new epoch

        emit EpochAdvanced(currentEpoch.number, currentEpoch.endTime);
    }
    
    /**
     * @dev Internal function to execute an expired proposal during `advanceEpoch`.
     * @param _proposalId The ID of the expired proposal.
     */
    function _executeExpiredProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        
        uint252 totalReputationInVote = proposal.totalReputationFor + proposal.totalReputationAgainst;
        if (totalReputationInVote == 0) {
            proposal.status = ProposalStatus.Rejected; // No votes, reject
            emit ProposalExecuted(_proposalId, false);
            return;
        }

        uint256 quorumPercentage = (proposal.proposalType == ProposalType.Evolution) ?
            systemParameters[EVOLUTION_VOTE_QUORUM_PERCENT] : systemParameters[PRUNING_VOTE_QUORUM_PERCENT];
        
        uint256 minQuorumReputation = (totalReputationInVote * quorumPercentage) / 10000;

        bool proposalPassed = (totalReputationInVote >= minQuorumReputation) && (proposal.totalReputationFor > proposal.totalReputationAgainst);

        if (proposalPassed) {
            if (proposal.proposalType == ProposalType.Evolution) {
                _applyADC_Evolution(proposal.adcId, proposal.newTraitName, proposal.newTraitLevel);
            } else if (proposal.proposalType == ProposalType.Pruning) {
                _pruneADC(proposal.adcId);
            }
            proposal.status = ProposalStatus.Executed;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        _adjustReputationsAndQueueRewards(_proposalId, proposalPassed);
        emit ProposalExecuted(_proposalId, proposalPassed);
    }


    /**
     * @dev Allows Curators to claim their accrued AethelToken rewards.
     */
    function claimCuratorRewards() external nonReentrant whenNotPaused onlyCurator {
        uint256 rewards = pendingCuratorRewards[msg.sender];
        require(rewards > 0, "AethelEngine: No rewards to claim.");

        pendingCuratorRewards[msg.sender] = 0;
        require(aethelToken.transfer(msg.sender, rewards), "AethelEngine: Reward transfer failed.");

        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Internal function to add tokens to the epoch's reward pool.
     * @param _amount The amount of AethelTokens to add.
     */
    function _addToRewardPool(uint256 _amount) internal {
        uint256 rewardShare = (_amount * systemParameters[REWARD_POOL_SHARE_PERCENT]) / 10000;
        currentEpoch.totalRewardPool += rewardShare;
        // Remaining _amount - rewardShare could go to treasury or be burned etc.
    }

    /**
     * @dev Returns the current epoch number and its scheduled end timestamp.
     * @return _epochNumber The current epoch number.
     * @return _endTime The timestamp when the current epoch is scheduled to end.
     */
    function getCurrentEpochDetails() public view returns (uint256 _epochNumber, uint256 _endTime) {
        return (currentEpoch.number, currentEpoch.endTime);
    }

    /**
     * @dev Returns the amount of unclaimed AethelToken rewards for a specific curator.
     * @param _curator The address of the curator.
     * @return The amount of pending rewards.
     */
    function getPendingCuratorRewards(address _curator) public view returns (uint256) {
        return pendingCuratorRewards[_curator];
    }
}

// Minimalist Base64 library for on-chain metadata
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load not just the table, but also everything around it
        // and check that it is what we expect
        assembly {
            let table := mload(add(_TABLE, 32))
        }

        string memory result = new string(data.length * 4 / 3 + 3);
        
        assembly {
            let src := add(data, 32)
            let srcLen := mload(data)
            let dest := add(result, 32)

            let table := mload(add(_TABLE, 32))

            for { let i := 0 } lt(i, srcLen) { i := add(i, 3) } {
                let temp := mload(add(src, i))

                // The following block does the equivalent of (temp >> 18) & 0x3F, (temp >> 12) & 0x3F, etc.
                // but in a more optimized way.
                mstore(dest, byte(and(shr(18, temp), 0x3F), table))
                mstore(add(dest, 1), byte(and(shr(12, temp), 0x3F), table))
                mstore(add(dest, 2), byte(and(shr(6, temp), 0x3F), table))
                mstore(add(dest, 3), byte(and(temp, 0x3F), table))
                dest := add(dest, 4)
            }

            switch mod(srcLen, 3)
            case 1 {
                mstore(sub(dest, 1), 0x3d)
                mstore(sub(dest, 2), 0x3d)
            }
            case 2 {
                mstore(sub(dest, 1), 0x3d)
            }

            mstore(result, sub(dest, add(result, 32)))
        }

        return result;
    }
}

```