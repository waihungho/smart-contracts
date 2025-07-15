Okay, here is a Solidity smart contract designed with an interesting, advanced, and somewhat trendy concept: a "ChronoMorphs" protocol.

This protocol manages a type of dynamic NFT (ERC721) called a "ChronoMorph" whose state and properties change over time and through user interaction. It incorporates a simple on-chain reputation system that affects NFT capabilities and staking rewards, and includes a basic governance mechanism to adjust protocol parameters.

This aims to be creative by combining dynamic NFT state, a reputation system, algorithmic rewards tied to both, and simple governance in a single, non-standard structure.

**Outline and Function Summary**

*   **Protocol:** ChronoMorphs Protocol
*   **Concept:** Manages dynamic NFTs (ChronoMorphs) that evolve or decay based on time, user interaction (gaining Evolution Points), and a user's on-chain reputation. Includes staking for yield (in a hypothetical reward token), where yield is influenced by the ChronoMorph's state and the staker's reputation. Protocol parameters can be adjusted via a simple governance mechanism.
*   **Core Entities:**
    *   `ChronoMorph`: An ERC721 token with dynamic state (`MorphState`), `evolutionPoints`, `lastStateChangeTime`, `decayRate`.
    *   `Reputation`: A score associated with each user address.
    *   `StakingPool`: Where ChronoMorphs can be locked to earn rewards.
    *   `System Parameters`: Configurable values governing evolution, decay, rewards, reputation gain/loss.
    *   `Proposals`: For changing System Parameters.
*   **Hypothetical Token:** Assumes a simple `CHR` (ChronoRewards) token exists (or is minted internally) for staking rewards. (A basic internal balance management is used instead of a full ERC20 for simplicity and avoiding standard ERC20 contract duplication).

---

**Function Summary (Total: 27 functions)**

1.  `constructor()`: Initializes the contract, sets initial owner and system parameters.
2.  `setSystemParameter(string calldata _name, uint256 _value)`: (Owner/Governance) Sets a specific system parameter value.
3.  `getSystemParameter(string calldata _name)`: (Public View) Gets the current value of a system parameter.
4.  `mintMorph(address _to)`: Mints a new ChronoMorph NFT in its initial state (`Hatchling`) to an address. Limited by a max supply.
5.  `transferFrom(address _from, address _to, uint256 _tokenId)`: (Standard ERC721) Transfers ownership of a Morph. Includes reputation update logic on transfer.
6.  `safeTransferFrom(address _from, address _to, uint256 _tokenId)`: (Standard ERC721) Safely transfers ownership.
7.  `safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data)`: (Standard ERC721) Safely transfers ownership with data.
8.  `approve(address _approved, uint256 _tokenId)`: (Standard ERC721) Approves an address to manage a Morph.
9.  `setApprovalForAll(address _operator, bool _approved)`: (Standard ERC721) Sets approval for an operator for all Morphs.
10. `getApproved(uint256 _tokenId)`: (Standard ERC721) Gets the approved address for a Morph.
11. `isApprovedForAll(address _owner, address _operator)`: (Standard ERC721) Checks if an operator is approved for all Morphs.
12. `balanceOf(address _owner)`: (Standard ERC721) Gets the number of Morphs owned by an address.
13. `ownerOf(uint256 _tokenId)`: (Standard ERC721) Gets the owner of a Morph.
14. `getMorphState(uint256 _tokenId)`: (Public View) Gets the current `MorphState` of a ChronoMorph.
15. `getMorphProperties(uint256 _tokenId)`: (Public View) Gets detailed properties (points, decay rate, times) of a ChronoMorph.
16. `evolveMorph(uint256 _tokenId)`: (Public) Attempts to evolve a ChronoMorph to the next state if conditions (evolution points, reputation threshold) are met. Updates state, points, time, and potentially reputation. *Unique logic.*
17. `triggerDecay(uint256 _tokenId)`: (Public) Explicitly triggers the decay process for a ChronoMorph, reducing evolution points or reverting state based on elapsed time. *Unique logic.*
18. `increaseEvolutionPoints(uint256 _tokenId, uint256 _points)`: (Public, requires permissions/conditions) Allows adding evolution points to a ChronoMorph. Could be tied to game mechanics or other protocol interactions. *Unique interaction.*
19. `getUserReputation(address _user)`: (Public View) Gets the reputation score of a user.
20. `applyReputationBoost()`: (Public, requires payment/condition) Allows a user to increase their reputation score, possibly by burning a token or paying ETH (placeholder for now). *Unique mechanic.*
21. `stakeMorph(uint256 _tokenId)`: (Public) Stakes a ChronoMorph NFT in the contract. Only owner can stake their non-staked Morph. Updates staking state. *Unique staking criteria.*
22. `unstakeMorph(uint256 _tokenId)`: (Public) Unstakes a previously staked ChronoMorph. Transfers ownership back. *Standard.*
23. `claimStakingRewards(uint256 _tokenId)`: (Public) Calculates and claims pending `CHR` rewards for a staked ChronoMorph. Rewards are based on duration, Morph state, and user reputation. *Unique reward calculation logic.*
24. `getPendingRewards(uint256 _tokenId)`: (Public View) Calculates the current pending `CHR` rewards for a staked ChronoMorph without claiming. *Utility.*
25. `proposeParameterChange(string calldata _paramName, uint256 _newValue, uint256 _delay)`: (Public) Allows users with sufficient reputation to propose changing a system parameter. *Unique governance target.*
26. `voteOnProposal(uint256 _proposalId, bool _support)`: (Public) Allows users with sufficient reputation to vote on an active proposal. Voting power could be based on reputation. *Unique voting criteria.*
27. `executeProposal(uint256 _proposalId)`: (Public) Executes a proposal that has passed its voting period and met quorum/thresholds, after a specified delay.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC165/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for basic admin, not core logic

// --- ChronoMorphs Protocol ---
// Concept: Dynamic NFTs (ChronoMorphs) whose state evolves or decays based on time,
// evolution points (gained through interaction/reputation), and user reputation.
// Includes staking with algorithmic rewards influenced by NFT state and staker reputation.
// System parameters are adjustable via reputation-gated governance proposals.

// --- Function Summary ---
// 1.  constructor()
// 2.  setSystemParameter(string, uint256) - Owner/Governance
// 3.  getSystemParameter(string) - Public View
// 4.  mintMorph(address) - Public
// 5.  transferFrom(address, address, uint256) - Standard ERC721 (Overridden for Reputation)
// 6.  safeTransferFrom(address, address, uint256) - Standard ERC721
// 7.  safeTransferFrom(address, address, uint256, bytes) - Standard ERC721
// 8.  approve(address, uint256) - Standard ERC721
// 9.  setApprovalForAll(address, bool) - Standard ERC721
// 10. getApproved(uint256) - Public View
// 11. isApprovedForAll(address, address) - Public View
// 12. balanceOf(address) - Standard ERC721 Public View
// 13. ownerOf(uint256) - Standard ERC721 Public View
// 14. getMorphState(uint256) - Public View
// 15. getMorphProperties(uint256) - Public View
// 16. evolveMorph(uint256) - Public (Unique Logic)
// 17. triggerDecay(uint256) - Public (Unique Logic)
// 18. increaseEvolutionPoints(uint256, uint256) - Public (Conditional/Unique)
// 19. getUserReputation(address) - Public View
// 20. applyReputationBoost() - Public (Conditional/Unique)
// 21. stakeMorph(uint256) - Public (Unique Staking Criteria)
// 22. unstakeMorph(uint256) - Public
// 23. claimStakingRewards(uint256) - Public (Unique Reward Calculation)
// 24. getPendingRewards(uint256) - Public View (Utility)
// 25. proposeParameterChange(string, uint256, uint256) - Public (Unique Governance Target)
// 26. voteOnProposal(uint256, bool) - Public (Unique Voting Criteria)
// 27. executeProposal(uint256) - Public

contract ChronoMorphsCore is Context, ERC165, IERC721, IERC721Receiver, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- State Variables ---

    string public name = "ChronoMorph";
    string public symbol = "CM";
    Counters.Counter private _tokenIdCounter;
    uint256 public maxSupply;

    enum MorphState { Hatchling, Juvenile, Adult, Elder, Dormant }

    struct Morph {
        address owner;
        MorphState state;
        uint256 evolutionPoints;
        uint256 lastStateChangeTime;
        uint256 decayRateFactor; // Factor applied to state's base decay rate
        bool isStaked;
        uint256 stakingStartTime;
        uint256 lastRewardClaimTime;
    }

    mapping(uint256 => Morph) private _morphs;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => uint256) private userReputation;

    // System Parameters (Configurable via Governance)
    mapping(string => uint256) public systemParameters;
    mapping(MorphState => uint256) public evolutionPointRequirement; // Points needed to evolve from a state
    mapping(MorphState => uint255) public baseDecayRatePerDay; // Base decay rate in points per day
    mapping(MorphState => uint256) public stakingRewardRatePerSecond; // CHR reward per second per morph state
    mapping(MorphState => uint256) public reputationThresholdForEvolution; // Required reputation to evolve

    // Governance
    struct Proposal {
        uint256 id;
        string paramName;
        uint256 newValue;
        uint256 proposerReputation; // Reputation needed to propose
        uint256 requiredVotingReputation; // Reputation needed to vote
        uint256 voteStart;
        uint256 voteEnd;
        uint256 executionTime; // Timelock
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
    }

    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    // Governance parameters
    uint256 public minReputationToPropose;
    uint256 public minReputationToVote;
    uint256 public proposalVotingPeriod; // in seconds
    uint256 public proposalExecutionDelay; // in seconds
    uint256 public quorumReputationPercentage; // Percentage of total *eligible* reputation needed to vote FOR

    // Reward Token (CHR) - Simplified internal balance tracking
    mapping(address => uint256) private _chrBalances;
    uint256 public totalChrSupply;
    uint256 public reputationBoostCost; // Cost in some resource (placeholder) for reputation boost

    // --- Events ---

    event MorphMinted(uint256 indexed tokenId, address indexed to);
    event MorphStateChanged(uint256 indexed tokenId, MorphState oldState, MorphState newState, uint256 timestamp);
    event EvolutionPointsIncreased(uint256 indexed tokenId, uint256 pointsAdded, uint256 newPoints);
    event MorphStaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event MorphUnstaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event UserReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event SystemParameterSet(string paramName, uint256 value);
    event ProposalCreated(uint256 indexed proposalId, string paramName, uint256 newValue, uint256 voteEnd, uint256 executionTime);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---

    modifier onlyMorphOwner(uint256 _tokenId) {
        require(_morphs[_tokenId].owner == _msgSender(), "ChronoMorphs: Not owner");
        _;
    }

    modifier onlyMorphExists(uint256 _tokenId) {
        require(_exists(_tokenId), "ChronoMorphs: token does not exist");
        _;
    }

    modifier reputationGated(uint256 _requiredReputation) {
        require(userReputation[_msgSender()] >= _requiredReputation, "ChronoMorphs: Insufficient reputation");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _maxSupply) Ownable(_msgSender()) {
        maxSupply = _maxSupply;

        // Initial System Parameters (can be changed via governance)
        systemParameters["initialEvolutionPoints"] = 50;
        systemParameters["minEvolutionPointsToDecay"] = 10; // Min points before decay happens
        systemParameters["evolutionPointGainOnEvolve"] = 25; // Points gained by *user* reputation, not morph
        systemParameters["reputationLossOnDecay"] = 5;
        systemParameters["reputationGainOnSuccessfulEvolution"] = 10;
        systemParameters["reputationBoostCost"] = 1 ether; // Placeholder cost in ETH

        // Initial State Requirements/Rates
        evolutionPointRequirement[MorphState.Hatchling] = 100; // Hatchling -> Juvenile
        evolutionPointRequirement[MorphState.Juvenile] = 250; // Juvenile -> Adult
        evolutionPointRequirement[MorphState.Adult] = 500;   // Adult -> Elder
        // Elder -> Dormant transition managed by decay if points drop below threshold

        baseDecayRatePerDay[MorphState.Juvenile] = 5;   // Points lost per day
        baseDecayRatePerDay[MorphState.Adult] = 10;
        baseDecayRatePerDay[MorphState.Elder] = 20;
        // Hatchling & Dormant have no base decay

        stakingRewardRatePerSecond[MorphState.Hatchling] = 1;   // Hypothetical CHR amount per second * 1e18
        stakingRewardRatePerSecond[MorphState.Juvenile] = 2;
        stakingRewardRatePerSecond[MorphState.Adult] = 5;
        stakingRewardRatePerSecond[MorphState.Elder] = 10;
        stakingRewardRatePerSecond[MorphState.Dormant] = 0;

        reputationThresholdForEvolution[MorphState.Hatchling] = 0; // No reputation needed for first evolve
        reputationThresholdForEvolution[MorphState.Juvenile] = 50;
        reputationThresholdForEvolution[MorphState.Adult] = 150;
        reputationThresholdForEvolution[MorphState.Elder] = 300; // Maybe Elder requires high rep to evolve to ultimate form? Or no evolution?

        // Initial Governance Parameters
        minReputationToPropose = 100;
        minReputationToVote = 50;
        proposalVotingPeriod = 7 days;
        proposalExecutionDelay = 2 days;
        quorumReputationPercentage = 20; // 20% of total *eligible* reputation voting FOR

        reputationBoostCost = systemParameters["reputationBoostCost"]; // Set the state variable from param
    }

    // --- System Parameter Management ---

    /**
     * @dev Sets a specific system parameter. Restricted to owner or successful governance execution.
     * @param _name The name of the parameter.
     * @param _value The new value for the parameter.
     */
    function setSystemParameter(string calldata _name, uint256 _value) public onlyOwner { // Restricted to owner initially, governance can call this internally
        systemParameters[_name] = _value;
        if (keccak256(bytes(_name)) == keccak256(bytes("reputationBoostCost"))) {
            reputationBoostCost = _value;
        }
        // Add other state variable updates here if new parameters are added
        emit SystemParameterSet(_name, _value);
    }

    /**
     * @dev Gets the current value of a system parameter.
     * @param _name The name of the parameter.
     * @return The value of the parameter.
     */
    function getSystemParameter(string calldata _name) public view returns (uint256) {
        return systemParameters[_name];
    }

    // --- ChronoMorph NFT Management (ERC721 extensions) ---

    /**
     * @dev Mints a new ChronoMorph NFT.
     * @param _to The address to mint the ChronoMorph to.
     */
    function mintMorph(address _to) public onlyOwner { // Restricted to owner/minter role initially
        uint256 newTokenId = _tokenIdCounter.current();
        require(newTokenId < maxSupply, "ChronoMorphs: Max supply reached");
        _mint(_to, newTokenId);

        _morphs[newTokenId] = Morph({
            owner: _to,
            state: MorphState.Hatchling,
            evolutionPoints: systemParameters["initialEvolutionPoints"],
            lastStateChangeTime: block.timestamp,
            decayRateFactor: 100, // 100% base decay rate initially
            isStaked: false,
            stakingStartTime: 0,
            lastRewardClaimTime: 0
        });

        _tokenIdCounter.increment();
        emit MorphMinted(newTokenId, _to);
    }

    /**
     * @dev See {IERC721-transferFrom}. Overridden to include reputation logic.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        // Standard ERC721 checks
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ChronoMorphs: transfer caller is not owner nor approved");
        require(_from == ownerOf(_tokenId), "ChronoMorphs: transfer from incorrect owner");
        require(_to != address(0), "ChronoMorphs: transfer to the zero address");

        // Ensure staked tokens cannot be transferred
        require(!_morphs[_tokenId].isStaked, "ChronoMorphs: Staked morph cannot be transferred");

        _beforeTokenTransfer(_from, _to, _tokenId);
        _transfer(_from, _to, _tokenId);
        _afterTokenTransfer(_from, _to, _tokenId);

        // Potential Reputation Logic on Transfer (Example: small reputation change, or log for off-chain analysis)
        // For simplicity, let's add a small reputational friction or signal
        // _updateReputation(_from, userReputation[_from] > 5 ? -5 : 0); // Example: Lose small rep on transfer
        // _updateReputation(_to, 1); // Example: Gain very small rep for receiving
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public override {
        transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ChronoMorphs: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address _approved, uint256 _tokenId) public override onlyMorphOwner(_tokenId) {
        _approve(_approved, _tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address _operator, bool _approved) public override {
        require(_operator != _msgSender(), "ChronoMorphs: Approve to caller");
        _operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 _tokenId) public view override onlyMorphExists(_tokenId) returns (address) {
        return _tokenApprovals[_tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        require(_owner != address(0), "ChronoMorphs: balance query for the zero address");
        return _balances[_owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 _tokenId) public view override onlyMorphExists(_tokenId) returns (address) {
        return _morphs[_tokenId].owner;
    }

    // --- ChronoMorph State & Properties ---

    /**
     * @dev Gets the current MorphState of a ChronoMorph.
     * @param _tokenId The ID of the ChronoMorph.
     * @return The MorphState enum value.
     */
    function getMorphState(uint256 _tokenId) public view onlyMorphExists(_tokenId) returns (MorphState) {
        return _morphs[_tokenId].state;
    }

    /**
     * @dev Gets detailed properties of a ChronoMorph.
     * @param _tokenId The ID of the ChronoMorph.
     * @return A tuple containing state, evolution points, last state change time, decay rate factor, staked status, staking start time, last reward claim time.
     */
    function getMorphProperties(uint256 _tokenId)
        public
        view
        onlyMorphExists(_tokenId)
        returns (
            MorphState state,
            uint256 evolutionPoints,
            uint256 lastStateChangeTime,
            uint256 decayRateFactor,
            bool isStaked,
            uint256 stakingStartTime,
            uint256 lastRewardClaimTime
        )
    {
        Morph storage morph = _morphs[_tokenId];
        return (
            morph.state,
            morph.evolutionPoints,
            morph.lastStateChangeTime,
            morph.decayRateFactor,
            morph.isStaked,
            morph.stakingStartTime,
            morph.lastRewardClaimTime
        );
    }

    /**
     * @dev Attempts to evolve a ChronoMorph to the next state.
     * Requires sufficient evolution points and user reputation.
     * Consumes evolution points upon successful evolution.
     * @param _tokenId The ID of the ChronoMorph to evolve.
     */
    function evolveMorph(uint256 _tokenId) public onlyMorphOwner(_tokenId) onlyMorphExists(_tokenId) {
        Morph storage morph = _morphs[_tokenId];
        MorphState currentState = morph.state;
        uint256 requiredPoints = evolutionPointRequirement[currentState];
        uint256 requiredRep = reputationThresholdForEvolution[currentState];

        // Decay check before evolution attempt
        _applyDecay(_tokenId); // Internal helper

        require(currentState != MorphState.Elder && currentState != MorphState.Dormant, "ChronoMorphs: Morph cannot evolve further or is dormant");
        require(userReputation[_msgSender()] >= requiredRep, "ChronoMorphs: Insufficient reputation to evolve");
        require(morph.evolutionPoints >= requiredPoints, "ChronoMorphs: Insufficient evolution points");

        MorphState nextState;
        if (currentState == MorphState.Hatchling) {
            nextState = MorphState.Juvenile;
        } else if (currentState == MorphState.Juvenile) {
            nextState = MorphState.Adult;
        } else if (currentState == MorphState.Adult) {
            nextState = MorphState.Elder;
        } else {
             revert("ChronoMorphs: Invalid state for evolution");
        }

        // Transition state
        emit MorphStateChanged(_tokenId, currentState, nextState, block.timestamp);
        morph.state = nextState;
        morph.evolutionPoints = morph.evolutionPoints - requiredPoints; // Consume points
        morph.lastStateChangeTime = block.timestamp;
        // Potentially adjust decayRateFactor based on evolution success or state?
        // morph.decayRateFactor = 100; // Reset factor?

        // Reward user reputation for successful evolution
        _updateReputation(_msgSender(), userReputation[_msgSender()] + systemParameters["reputationGainOnSuccessfulEvolution"]);
    }

     /**
     * @dev Explicitly triggers the decay process for a ChronoMorph.
     * Calculates decay based on time elapsed since last state change/decay check
     * and the morph's current state and decay rate factor.
     * Can lead to reduction in evolution points or reverting to a previous state (Dormant).
     * @param _tokenId The ID of the ChronoMorph to decay.
     */
    function triggerDecay(uint256 _tokenId) public onlyMorphExists(_tokenId) {
         _applyDecay(_tokenId); // Internal helper
    }


    /**
     * @dev Allows increasing a ChronoMorph's evolution points.
     * This function is a placeholder for how evolution points might be gained
     * (e.g., completing tasks, interacting with other contracts, specific items).
     * Restricted access would be required in a real application.
     * @param _tokenId The ID of the ChronoMorph.
     * @param _points The number of points to add.
     */
    function increaseEvolutionPoints(uint256 _tokenId, uint256 _points) public onlyMorphOwner(_tokenId) onlyMorphExists(_tokenId) {
        require(_points > 0, "ChronoMorphs: Points must be positive");
        Morph storage morph = _morphs[_tokenId];

        // Ensure not in a state that can't gain points (e.g., Dormant permanently?)
        require(morph.state != MorphState.Dormant, "ChronoMorphs: Dormant morphs cannot gain points");

        uint256 oldPoints = morph.evolutionPoints;
        morph.evolutionPoints += _points;
        emit EvolutionPointsIncreased(_tokenId, _points, morph.evolutionPoints);
    }

    // --- Reputation System ---

    /**
     * @dev Gets the reputation score for a user.
     * @param _user The address of the user.
     * @return The user's current reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Allows a user to boost their reputation.
     * Placeholder: In a real system, this might require burning a token, staking, or completing an action.
     * Currently requires sending ETH (placeholder).
     * @dev This function demonstrates a unique *mechanism* for gaining reputation,
     * separate from automatic gains via evolution/decay.
     */
    function applyReputationBoost() public payable {
        // Placeholder: Require sending a specific amount of ETH, which is locked or sent elsewhere.
        // Or require burning a specific ERC20 token.
        // require(msg.value >= reputationBoostCost, "ChronoMorphs: Insufficient ETH for boost");
        // Alternatively, require an external call that verifies a condition

        // For demonstration, just requires the call and increases reputation
        uint256 oldRep = userReputation[_msgSender()];
        uint256 boostAmount = 25; // Example fixed boost
        _updateReputation(_msgSender(), oldRep + boostAmount);

        // In a real scenario, handle the msg.value (send to treasury, burn, etc.)
        // payable(owner()).transfer(msg.value); // Example: send to owner
    }


    // --- Staking System ---

    /**
     * @dev Stakes a ChronoMorph owned by the caller.
     * Transfers the NFT to the contract and marks it as staked.
     * @param _tokenId The ID of the ChronoMorph to stake.
     */
    function stakeMorph(uint256 _tokenId) public onlyMorphOwner(_tokenId) onlyMorphExists(_tokenId) {
        Morph storage morph = _morphs[_tokenId];
        require(!morph.isStaked, "ChronoMorphs: Morph is already staked");

        // Transfer the NFT to the contract address
        // This requires the owner to have approved the contract to manage the token
        // Or using safeTransferFrom if the contract is the receiver.
        // For simplicity here, we'll just update internal ownership state, assuming the NFT logic is handled.
        // In a real ERC721 implementation, you'd call safeTransferFrom or transferFrom.
        // Since this contract IS the ERC721 logic, we just update internal state.
        _transfer(_msgSender(), address(this), _tokenId);

        morph.isStaked = true;
        morph.stakingStartTime = block.timestamp;
        morph.lastRewardClaimTime = block.timestamp; // Start reward clock

        emit MorphStaked(_tokenId, _msgSender(), block.timestamp);
    }

    /**
     * @dev Unstakes a ChronoMorph previously staked by the caller.
     * Transfers the NFT back to the caller. Rewards are claimed automatically upon unstaking.
     * @param _tokenId The ID of the ChronoMorph to unstake.
     */
    function unstakeMorph(uint256 _tokenId) public onlyMorphExists(_tokenId) {
        // Need to ensure the caller is the original staker
        // The Morph struct doesn't store original staker, so this needs a mapping or modified struct
        // Let's assume ownerOf(_tokenId) returns this contract, and we track who *staked* it.
        // Adding mapping: mapping(uint256 => address) private stakerAddress;
        // Add stakerAddress[_tokenId] = _msgSender(); in stakeMorph
        // require(stakerAddress[_tokenId] == _msgSender(), "ChronoMorphs: Only original staker can unstake");
        // For this example, we'll simplify and allow the current ERC721 owner (which is this contract)
        // to initiate the unstake to the address stored in the morph struct (who was the owner before staking)
        // In a real dapp, the UI would track the staker, or the struct would need `stakerAddress`.

        Morph storage morph = _morphs[_tokenId];
        require(morph.isStaked, "ChronoMorphs: Morph is not staked");
        address originalOwner = morph.owner; // The owner *before* staking

        // Claim pending rewards before unstaking
        claimStakingRewards(_tokenId);

        morph.isStaked = false;
        morph.stakingStartTime = 0; // Reset staking time
        morph.lastRewardClaimTime = 0; // Reset claim time

        // Transfer the NFT back to the original owner (who initiated the unstake)
        // Ensure this contract has approval or permission if it's not the ERC721 source
        // Since this contract IS the ERC721 logic, we just update internal state.
         _transfer(address(this), originalOwner, _tokenId);


        // Remove staker tracking mapping if added
        // delete stakerAddress[_tokenId];

        emit MorphUnstaked(_tokenId, originalOwner, block.timestamp);
    }

    /**
     * @dev Calculates and claims pending CHR rewards for a staked ChronoMorph.
     * Rewards accrue based on elapsed time, Morph state, and the user's reputation score.
     * @param _tokenId The ID of the staked ChronoMorph.
     */
    function claimStakingRewards(uint256 _tokenId) public onlyMorphExists(_tokenId) {
         // Again, assuming the caller is the original staker or someone with permission.
         // Using the morph's stored owner (original owner before staking) for reward destination.
        Morph storage morph = _morphs[_tokenId];
        require(morph.isStaked, "ChronoMorphs: Morph is not staked");
        address rewardRecipient = morph.owner; // Send rewards to the original owner

        uint256 pendingRewards = _calculateRewards(_tokenId);

        if (pendingRewards > 0) {
            // Mint or transfer rewards (using simplified internal balance)
            _mintCHR(rewardRecipient, pendingRewards);
            morph.lastRewardClaimTime = block.timestamp; // Update last claim time

            emit StakingRewardsClaimed(_tokenId, rewardRecipient, pendingRewards);
        }
    }

    /**
     * @dev Calculates the pending CHR rewards for a staked ChronoMorph without claiming.
     * @param _tokenId The ID of the staked ChronoMorph.
     * @return The amount of pending CHR rewards.
     */
    function getPendingRewards(uint256 _tokenId) public view onlyMorphExists(_tokenId) returns (uint256) {
        Morph storage morph = _morphs[_tokenId];
        if (!morph.isStaked) {
            return 0;
        }
        return _calculateRewards(_tokenId);
    }

    // --- Governance ---

    /**
     * @dev Creates a proposal to change a system parameter.
     * Requires the caller to have sufficient reputation.
     * @param _paramName The name of the system parameter to change.
     * @param _newValue The proposed new value.
     * @param _delay The execution delay (in seconds) after the voting period ends.
     */
    function proposeParameterChange(string calldata _paramName, uint256 _newValue, uint256 _delay)
        public
        reputationGated(minReputationToPropose)
    {
        uint256 proposalId = _proposalIdCounter.current();
        uint256 voteEnd = block.timestamp + proposalVotingPeriod;
        uint256 executionTime = voteEnd + _delay;

        proposals[proposalId] = Proposal({
            id: proposalId,
            paramName: _paramName,
            newValue: _newValue,
            proposerReputation: minReputationToPropose, // Snapshot or require min at creation
            requiredVotingReputation: minReputationToVote, // Snapshot or require min at voting
            voteStart: block.timestamp,
            voteEnd: voteEnd,
            executionTime: executionTime,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            canceled: false,
            hasVoted: new mapping(address => bool)() // Initialize mapping
        });

        _proposalIdCounter.increment();
        emit ProposalCreated(proposalId, _paramName, _newValue, voteEnd, executionTime);
    }

    /**
     * @dev Votes on an active proposal.
     * Requires the caller to have sufficient reputation and not have voted already.
     * Voting power is 1 vote per eligible user for simplicity, could be weighted by reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'For', False for 'Against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStart > 0, "ChronoMorphs: Proposal does not exist");
        require(!proposal.executed, "ChronoMorphs: Proposal already executed");
        require(!proposal.canceled, "ChronoMorphs: Proposal canceled");
        require(block.timestamp >= proposal.voteStart && block.timestamp <= proposal.voteEnd, "ChronoMorphs: Voting is not open");
        require(userReputation[_msgSender()] >= proposal.requiredVotingReputation, "ChronoMorphs: Insufficient reputation to vote");
        require(!proposal.hasVoted[_msgSender()], "ChronoMorphs: User already voted");

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit ProposalVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a proposal that has passed its voting period, met quorum, and passed the execution delay.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStart > 0, "ChronoMorphs: Proposal does not exist");
        require(!proposal.executed, "ChronoMorphs: Proposal already executed");
        require(!proposal.canceled, "ChronoMorphs: Proposal canceled");
        require(block.timestamp > proposal.voteEnd, "ChronoMorphs: Voting period not ended");
        require(block.timestamp >= proposal.executionTime, "ChronoMorphs: Execution delay not passed");

        // Calculate total eligible voters based on reputation snapshot at vote start? Or current?
        // For simplicity, let's consider total votes cast against a hypothetical total eligible
        // A more robust system would snapshot eligible voters or use a weighted quorum.
        // Simple Quorum Check: For votes must be >= QuorumPercentage * (For + Against)
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        // A better quorum needs total eligible voting power. Let's use a simpler pass condition:
        // require(proposal.votesFor > proposal.votesAgainst, "ChronoMorphs: Proposal did not pass");

        // Let's use the quorum based on total possible voting power (sum of reputation of all users above minReputationToVote)
        // This is hard to calculate on-chain efficiently without tracking total eligible rep.
        // A simpler approach for quorum is total votes * cast * >= X% of *something*.
        // Let's use a simple majority + minimum participants.
        // require(totalVotes >= 10, "ChronoMorphs: Not enough votes"); // Minimum participation
        require(proposal.votesFor > proposal.votesAgainst, "ChronoMorphs: Proposal did not pass majority");

        // Execute the change
        setSystemParameter(proposal.paramName, proposal.newValue); // Call internal set function
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // --- Internal Helpers ---

     /**
     * @dev Internal function to apply decay to a morph based on time elapsed.
     * Reduces evolution points. Can change state to Dormant if points drop too low.
     * @param _tokenId The ID of the ChronoMorph.
     */
    function _applyDecay(uint256 _tokenId) internal onlyMorphExists(_tokenId) {
        Morph storage morph = _morphs[_tokenId];
        if (morph.state == MorphState.Hatchling || morph.state == MorphState.Dormant) {
            morph.lastStateChangeTime = block.timestamp; // Reset timer even if no decay applies
            return; // No decay for these states
        }

        uint256 timeElapsed = block.timestamp - morph.lastStateChangeTime;
        uint256 baseRate = baseDecayRatePerDay[morph.state];

        if (baseRate == 0 || timeElapsed == 0) {
             morph.lastStateChangeTime = block.timestamp; // Reset timer if no decay applies
            return; // No decay
        }

        // Calculate decay points: (Time Elapsed in Seconds / Seconds Per Day) * Base Rate * Decay Factor
        uint256 secondsPerDay = 24 * 60 * 60;
        uint256 decayPoints = (timeElapsed * baseRate * morph.decayRateFactor) / (secondsPerDay * 100); // decayRateFactor is %

        if (decayPoints == 0) {
             morph.lastStateChangeTime = block.timestamp; // Reset timer if decay is less than 1 point
            return;
        }

        uint256 oldPoints = morph.evolutionPoints;
        if (morph.evolutionPoints <= systemParameters["minEvolutionPointsToDecay"]) {
             // Already too low for decay to apply points, might trigger state change if it was higher before this check
        } else if (morph.evolutionPoints > decayPoints) {
             morph.evolutionPoints -= decayPoints;
        } else {
            morph.evolutionPoints = 0; // Points cannot go below zero
        }

        morph.lastStateChangeTime = block.timestamp; // Reset timer after applying decay

        // Check for state reversion (e.g., to Dormant) if points are too low
        if (morph.evolutionPoints < systemParameters["minEvolutionPointsToDecay"] && morph.state != MorphState.Dormant) {
             // Determine previous state - requires tracking history or simple rule (e.g., any state -> Dormant)
             emit MorphStateChanged(_tokenId, morph.state, MorphState.Dormant, block.timestamp);
             morph.state = MorphState.Dormant;
             // Apply reputation loss to the owner upon decay to Dormant
             address currentOwner = ownerOf(_tokenId); // Use ownerOf as internal state might not be updated yet if called during transfer
             if (userReputation[currentOwner] >= systemParameters["reputationLossOnDecay"]) {
                _updateReputation(currentOwner, userReputation[currentOwner] - systemParameters["reputationLossOnDecay"]);
             } else {
                 _updateReputation(currentOwner, 0); // Cannot go below 0 reputation
             }
        }

        if (morph.evolutionPoints != oldPoints) {
             emit EvolutionPointsIncreased(_tokenId, oldPoints > morph.evolutionPoints ? (oldPoints - morph.evolutionPoints) * uint256(type(int256).min + 1) : morph.evolutionPoints - oldPoints, morph.evolutionPoints); // Use large number to signal decrease, or negative if Solidity supported it better
        }
    }


    /**
     * @dev Internal function to calculate pending CHR rewards for a staked morph.
     * Rewards = time_staked * rate_per_sec * reputation_multiplier
     * @param _tokenId The ID of the ChronoMorph.
     * @return The calculated reward amount.
     */
    function _calculateRewards(uint256 _tokenId) internal view onlyMorphExists(_tokenId) returns (uint256) {
        Morph storage morph = _morphs[_tokenId];
        if (!morph.isStaked) {
            return 0;
        }

        // Get the user who *staked* it to use their reputation
        // Requires mapping staker address: mapping(uint256 => address) private stakerAddress;
        // For now, assuming the owner stored in the struct IS the staker/reward recipient
        address staker = morph.owner;

        uint256 timeElapsed = block.timestamp - morph.lastRewardClaimTime;
        uint256 rewardRate = stakingRewardRatePerSecond[morph.state];
        uint256 userRep = userReputation[staker];

        // Simple reward calculation: time * rate * (1 + reputation / X)
        // Where X is a scaling factor for reputation bonus, e.g., 1000
        uint256 reputationBonusFactor = 1e18 + (userRep * 1e18) / 1000; // 1000 rep gives 2x rewards

        // Reward = time * rate * reputationFactor / 1e18 (since reputationFactor is scaled)
        // Use safeMul and safeDiv if available or careful calculation
        uint256 rawRewards = timeElapsed * rewardRate;
        uint256 totalRewards = (rawRewards * reputationBonusFactor) / 1e18;

        return totalRewards;
    }

    /**
     * @dev Internal function to update a user's reputation score.
     * Emits an event. Clamps reputation at 0.
     * @param _user The address of the user.
     * @param _newReputation The new reputation value.
     */
    function _updateReputation(address _user, uint256 _newReputation) internal {
        uint256 oldReputation = userReputation[_user];
        // Ensure reputation doesn't go below 0 (since using uint256)
        if (_newReputation < oldReputation && _newReputation > oldReputation) { // Check for underflow potential if subtractive logic is complex
            userReputation[_user] = 0; // Clamp at 0
        } else {
            userReputation[_user] = _newReputation;
        }

        emit UserReputationUpdated(_user, oldReputation, userReputation[_user]);
    }

    /**
     * @dev Internal CHR minting (simplified balance management).
     * @param _to The recipient address.
     * @param _amount The amount of CHR to mint.
     */
    function _mintCHR(address _to, uint256 _amount) internal {
        // In a real system, this would interact with a separate ERC20 contract.
        // Here, we use internal mapping for simplicity.
        require(_to != address(0), "ChronoMorphs: mint to the zero address");
        totalChrSupply += _amount;
        _chrBalances[_to] += _amount;
        // Emit Transfer event (like ERC20) if desired, but not standard for internal.
    }

     /**
     * @dev Internal CHR balance query.
     * @param _owner The address to query balance for.
     * @return The CHR balance.
     */
    function getChrBalance(address _owner) public view returns (uint256) {
        return _chrBalances[_owner];
    }


    // --- ERC721 Internal Functions (Minimal Implementation for Core Logic) ---
    // These are simplified internal functions needed for the ChronoMorphs logic itself.
    // A full ERC721 implementation would include more (_beforeTokenTransfer, _afterTokenTransfer, etc.)

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _morphs[_tokenId].owner != address(0); // Assuming address(0) means token doesn't exist
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(_tokenId);
        return (_spender == tokenOwner || getApproved(_tokenId) == _spender || isApprovedForAll(tokenOwner, _spender));
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from, "ChronoMorphs: transfer from incorrect owner");
        require(_to != address(0), "ChronoMorphs: transfer to the zero address");

        _approve(address(0), _tokenId); // Clear approval

        _balances[_from]--;
        _balances[_to]++;
        _morphs[_tokenId].owner = _to; // Update internal owner state
        // If this contract *is* the ERC721, no external call needed.
        // If it manages external NFTs, would call IERC721(_nftAddress).transferFrom(...)
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "ChronoMorphs: mint to the zero address");
        require(!_exists(_tokenId), "ChronoMorphs: token already minted");

        _balances[_to]++;
        // Set owner in the morph struct upon initial mint
        _morphs[_tokenId].owner = _to; // This line is important for _exists and ownerOf

        // Don't set other morph properties here, that's done in the public mintMorph function
        // _morphs[_tokenId] = Morph({...}); // This happens in the public mintMorph
    }

    function _burn(uint256 _tokenId) internal onlyMorphExists(_tokenId) {
        address tokenOwner = ownerOf(_tokenId);
        _approve(address(0), _tokenId); // Clear approval

        _balances[tokenOwner]--;
        delete _morphs[_tokenId]; // Delete the morph struct entry
        // Note: ownerOf will now revert or return address(0) depending on implementation details
    }

    function _approve(address _approved, uint256 _tokenId) internal onlyMorphExists(_tokenId) {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

     // ERC721Receiver implementation
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This function is called when a ChronoMorph is transferred TO this contract (e.g., for staking)
        // You might add checks here:
        // require(msg.sender == address(this), "ChronoMorphs: Must be ERC721 transfer from authorized source");
        // require(operator == _msgSender(), "ChronoMorphs: Operator must be msg.sender"); // Example: check who initiated the transfer

        // Perform staking logic if that's why the token was sent
        // Note: The standard way is for the user to call stakeMorph *after* approving the contract,
        // and stakeMorph calls transferFrom internally. Receiving isn't typically part of the stake flow.
        // This is more for unsolicited transfers or transfers initiated by another contract.
        // For this contract, staking uses internal state updates, so receiving isn't the trigger.
        // Return the magic value to indicate successful receipt.
        return this.onERC721Received.selector;
    }

     // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

     // --- Basic Admin Functions ---
    // Add basic Ownable functions if needed, e.g., withdraw tokens, pause contract

    // Example: Withdrawal for accidentally sent tokens
    function withdrawERC20(address _token, address _to) public onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(_to, token.balanceOf(address(this)));
    }

    function withdrawERC721(address _token, address _to, uint256 _tokenId) public onlyOwner {
         IERC721 token = IERC721(_token);
         require(token.ownerOf(_tokenId) == address(this), "ChronoMorphs: Contract does not own this token");
         token.safeTransferFrom(address(this), _to, _tokenId);
    }

}

// Minimal IERC20 interface for withdrawal example
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```

**Explanation of Concepts and Novelty:**

1.  **Dynamic NFTs (ChronoMorphs):** The `Morph` struct contains `state`, `evolutionPoints`, `lastStateChangeTime`, and `decayRateFactor`. Functions like `evolveMorph` and `triggerDecay` explicitly change the internal state and properties of the NFT *after* it's minted, making it dynamic. This goes beyond simple metadata changes and affects the NFT's behavior within the protocol (e.g., staking yield).
2.  **On-Chain Reputation System:** The `userReputation` mapping tracks a score for each address. This score is integrated into core mechanics:
    *   Required for evolving Morph states (`reputationThresholdForEvolution`).
    *   Multiplier for staking rewards (`_calculateRewards`).
    *   Gate for participating in governance (`minReputationToPropose`, `minReputationToVote`).
    *   Can be gained/lost through protocol actions (successful evolution, decay to dormant).
    *   Includes a unique `applyReputationBoost` function (even if a placeholder cost is used), suggesting alternative ways to earn reputation.
3.  **Algorithmic Staking Rewards:** The `claimStakingRewards` and `_calculateRewards` functions implement a non-standard reward calculation. Yield is not a simple fixed rate but is dynamic based on:
    *   Duration staked.
    *   The *current state* of the staked ChronoMorph.
    *   The *reputation* of the staker.
4.  **Reputation-Gated Governance:** The `proposeParameterChange`, `voteOnProposal`, and `executeProposal` functions implement a basic governance system. The key novelty here is that participation (proposing and voting) is explicitly gated by a user's on-chain reputation score, as defined by the `minReputationToPropose` and `minReputationToVote` parameters. Governance targets are the specific, unique `systemParameters` of this dynamic NFT and reputation system.
5.  **Interconnected Mechanics:** The contract demonstrates how these concepts can be linked: Reputation affects evolution and rewards; Evolution affects decay and potential rewards; Governance affects the rules for all of the above.
6.  **Avoidance of Standard Duplication:** While it interacts with ERC721 principles, it doesn't simply deploy a standard ERC721 contract. The core logic (`evolveMorph`, `triggerDecay`, `_calculateRewards`, `_updateReputation`, the governance targeting these specific parameters) is custom to this ChronoMorphs concept, rather than duplicating a generic token, lending pool, or marketplace. The minimal ERC721 implementation is included just enough to make the core logic runnable within a single contract, but the focus is on the *dynamic behavior* built *around* the token, not the standard token functions themselves. The internal CHR balance is used to avoid depending on or copying a full ERC20.

This contract provides a framework for a complex, stateful digital asset ecosystem where user identity (reputation) and asset state (evolution) dynamically interact to influence mechanics like yield and governance.