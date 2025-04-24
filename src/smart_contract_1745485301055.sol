Okay, let's create a smart contract concept that is interesting, advanced, creative, and trendy, while aiming to be distinct from common open-source examples. We'll build a "Dynamic On-Chain Ecosystem Simulation" focusing on "Ethereal Gardens".

**Concept:** Users stake a dedicated 'Energy Token' (ET) to "cultivate" unique, dynamic 'Organism NFTs' (ONFT). The ONFTs' attributes (like Vitality, Resilience) grow over time based on the staked ET. Users earn a 'Reputation Token' (RT) for their consistent cultivation. The RT confers governance rights over global parameters affecting organism growth and potentially allows triggering ecosystem events. This creates a closed-loop ecosystem driven by staking, dynamic NFTs, and community governance.

**Advanced Concepts Used:**
1.  **Dynamic NFT State:** NFT attributes are not static metadata but stored and updated directly on-chain based on user interaction (staking time, energy) and ecosystem events.
2.  **Multi-Token Interaction:** Seamless interaction between three distinct tokens (ERC-20 for staking ET, ERC-20 for governance/reputation RT, ERC-721 for the dynamic ONFT).
3.  **Staking Linked to NFT State:** Staking isn't just about earning a passive reward; it actively influences the state and value of a specific NFT.
4.  **Reputation System:** An ERC-20 token earned via active participation (staking) that serves as governance power.
5.  **On-Chain Governance:** A basic DAO structure allowing RT holders to propose and vote on changes to ecosystem parameters.
6.  **Simulated Ecosystem Events:** Mechanism for applying global or targeted effects to ONFTs (potentially triggered by governance or an oracle/keeper).
7.  **Cross-NFT Interaction:** A function allowing an owner to use one of their ONFTs to influence another (e.g., transfer 'vitality' at a cost).

**Outline and Function Summary**

*   **Contract Name:** `EtherealGardens`
*   **Core Tokens:** `EnergyToken` (ET), `ReputationToken` (RT), `OrganismNFT` (ONFT) - Assumes these are deployed separately.
*   **Inherits:** `Ownable`, `Pausable` (from OpenZeppelin) for basic access control and emergency pausing.

**Outline:**

1.  **State Variables:** Addresses of token contracts, mappings for organism states, user reputation, governance proposals, and global parameters.
2.  **Structs:** `OrganismState`, `Proposal`, `GovernanceParameters`.
3.  **Events:** To log key actions (Mint, Stake, Unstake, ReputationClaim, ProposalCreated, etc.).
4.  **Constructor:** Initialize contract owner, pausable state, and initial governance parameters. Requires setting token addresses post-deployment.
5.  **Admin/Setup Functions:** Set token addresses, pause/unpause.
6.  **Core Ecosystem Functions:**
    *   Minting/Burning ONFTs.
    *   Staking/Unstaking ET for ONFTs.
    *   Claiming earned RT.
    *   Internal helpers for calculating dynamic state and reputation gain.
7.  **Dynamic State & Interaction Functions:**
    *   Getting current calculated state of an ONFT.
    *   Cross-pollinating/influencing ONFTs.
    *   Applying effects from global/ecosystem events.
8.  **Governance Functions:**
    *   Creating proposals (parameter changes).
    *   Voting on proposals.
    *   Executing successful proposals.
    *   Canceling proposals.
    *   Setting governance parameters (admin/initial setup).
9.  **View Functions:** Querying organism states, user reputation, proposal details, global parameters, token totals within the contract.

**Function Summary (>= 20 Functions):**

1.  `constructor()`: Initializes contract with owner and basic governance parameters.
2.  `setTokenAddresses(address _et, address _rt, address _onft)`: Admin function to set the addresses of the required external token contracts.
3.  `pause()`: Admin/Owner function to pause contract operations (inherited from `Pausable`).
4.  `unpause()`: Admin/Owner function to unpause contract operations (inherited from `Pausable`).
5.  `mintOrganism(uint256 energyCost)`: Allows a user to mint a new ONFT by paying a specific amount of ET.
6.  `burnOrganism(uint256 tokenId)`: Allows the owner of an ONFT to burn it (optional: may return some ET or other resource).
7.  `stakeEnergyForOrganism(uint256 tokenId, uint256 amount)`: Stakes `amount` of ET from the user for the specified `tokenId`. Updates ONFT state and calculates potential RT earnings.
8.  `unstakeEnergyFromOrganism(uint256 tokenId)`: Unstakes *all* ET staked for `tokenId`. Calculates final growth and earned RT for the period. Updates ONFT state.
9.  `claimReputation()`: Allows a user to claim their accumulated RT earned from staking.
10. `getCurrentOrganismState(uint256 tokenId) public view returns (OrganismState memory)`: Calculates and returns the *current* potential state of the ONFT, accounting for elapsed time since last state update. Does *not* change state.
11. `getOrganismStoredState(uint256 tokenId) public view returns (OrganismState memory)`: Returns the raw, stored state of the ONFT as of its last update.
12. `calculateGrowth(uint256 tokenId, uint48 timestamp) internal view returns (uint256 vitalityGain, uint256 resilienceGain, uint256 complexityGain)`: Internal helper to calculate growth gains based on staked energy, time elapsed since `lastGrowthTimestamp`, and global growth rates.
13. `calculateReputationEarned(address user, uint256 stakedAmount, uint48 timestamp) internal view returns (uint256 reputationGained)`: Internal helper to calculate RT earned based on staked amount, duration, and global RT rate.
14. `crossPollinateStats(uint256 sourceTokenId, uint256 targetTokenId, uint256 vitalityAmount, uint256 resilienceAmount, uint256 complexityAmount)`: Allows an ONFT owner to transfer specific stats from one owned ONFT (`source`) to another (`target`), potentially consuming ET or reducing source stats permanently.
15. `applyGlobalEventEffect(uint256 tokenId, bytes memory effectData) external onlyKeeperOrGovernance`: Applies an external effect (`effectData`) to a specific `tokenId`. Callable by a designated keeper address or via governance. `effectData` could encode positive/negative stat changes, etc.
16. `proposeParameterChange(bytes memory proposalData)`: Allows an RT holder (above min threshold) to propose changing a governance parameter. Requires staking minimum RT. `proposalData` encodes the parameter index/value to change.
17. `voteOnProposal(uint256 proposalId, bool vote)`: Allows an RT holder to vote Yes/No on an active proposal using their RT balance as voting power.
18. `executeProposal(uint256 proposalId)`: Allows anyone to execute a proposal that has met the required vote threshold and voting period has ended. Updates parameters.
19. `cancelProposal(uint256 proposalId)`: Allows anyone to cancel an unsuccessful or expired proposal. Returns proposer's stake.
20. `setGovernanceParameters(uint256 votingPeriod, uint256 minReputationToPropose, uint256 requiredVotesNumerator, uint256 requiredVotesDenominator)`: Admin/initial setup function to configure governance constants. Can potentially be called by governance itself after the initial setup.
21. `getUserReputationEarned(address user) public view returns (uint256)`: Returns the amount of RT a user has earned but not yet claimed.
22. `getProposalState(uint256 proposalId) public view returns (Proposal memory)`: Returns details of a specific proposal.
23. `getGlobalParameters() public view returns (GovernanceParameters memory)`: Returns the current global governance parameters.
24. `getTotalEnergyStaked() public view returns (uint256)`: Returns the total amount of ET currently staked within the contract across all ONFTs.
25. `getOrganismEnergyStaked(uint256 tokenId) public view returns (uint256)`: Returns the amount of ET staked specifically for a given ONFT.
26. `setKeeperAddress(address _keeper)`: Admin function to set the address authorized to trigger certain events (like `applyGlobalEventEffect`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although Solidity 0.8+ checks overflow by default, SafeMath can clarify intent for complex calculations or be useful if needing older Solidity versions for parts. Let's stick to native checks for simplicity in 0.8+.
import "@openzeppelin/contracts/utils/Address.sol"; // For token interactions

// Custom Errors
error EtherealGardens__NotOrganismOwner(uint256 tokenId, address caller);
error EtherealGardens__TokenAddressesNotSet();
error EtherealGardens__EnergyStakeTooLow(uint256 requiredAmount);
error EtherealGardens__NoEnergyStakedForOrganism(uint256 tokenId);
error EtherealGardens__NothingToClaim(address user);
error EtherealGardens__InvalidProposalData();
error EtherealGardens__InsufficientReputationToPropose(uint256 required);
error EtherealGardens__AlreadyVoted(uint256 proposalId, address voter);
error EtherealGardens__ProposalVotingPeriodNotEnded(uint256 proposalId);
error EtherealGardens__ProposalNotExecutable(uint256 proposalId); // Not enough votes, or already executed/canceled
error EtherealGardens__ProposalAlreadyExecutedOrCanceled(uint256 proposalId);
error EtherealGardens__NotKeeperOrGovernance();
error EtherealGardens__InsufficientSourceStats(string statName, uint256 required);
error EtherealGardens__CannotCrossPollinateSameOrganism(uint256 tokenId);
error EtherealGardens__CrossPollinateCostTooHigh(uint256 required);
error EtherealGardens__ProposalNotFound(uint256 proposalId);


contract EtherealGardens is Ownable, Pausable, ReentrancyGuard {
    using Address for address;

    // --- State Variables ---

    // Token Contracts
    IERC20 public energyToken; // ET
    IERC20 public reputationToken; // RT
    IERC721 public organismNFT; // ONFT

    // Organism State
    struct OrganismState {
        uint256 vitality;
        uint256 resilience;
        uint256 complexity;
        uint48 lastGrowthTimestamp; // Use uint48 for efficiency (Unix timestamp fits)
        uint256 stakedEnergy;
        address owner; // Store owner here for quick access, supplement with ERC721 ownerOf
    }
    mapping(uint256 => OrganismState) private organismStates; // tokenId => OrganismState

    // Reputation Tracking
    mapping(address => uint256) private unclaimedReputation; // user => accumulated RT not yet claimed

    // Governance
    struct Proposal {
        uint256 proposalId;
        address proposer;
        bytes data; // Encoded function call for parameter change (or identifier for complex proposals)
        uint48 voteStartTime; // Use uint48
        uint48 voteEndTime; // Use uint48
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) voted; // user => hasVoted
        bool executed;
        bool canceled;
    }

    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal
    uint256 private nextProposalId; // Counter for unique proposal IDs

    struct GovernanceParameters {
        uint256 vitalityGrowthRate; // Per ET per second, scaled
        uint256 resilienceGrowthRate; // Per ET per second, scaled
        uint256 complexityGrowthRate; // Per ET per second, scaled
        uint256 reputationEarnRate; // Per ET staked per second, scaled
        uint256 minEnergyToStake; // Minimum ET required per stake
        uint255 minReputationToPropose; // Minimum RT balance to create a proposal
        uint48 votingPeriod; // Duration of voting in seconds (uint48)
        uint256 requiredVotesNumerator; // Numerator for required vote percentage (e.g., 51)
        uint256 requiredVotesDenominator; // Denominator for required vote percentage (e.g., 100)
        uint256 crossPollinateCostET; // Cost in ET for cross-pollination
        uint256 crossPollinateStatTransferRatio; // Percentage of stat transferred (e.g., 100 = 100%, 10 = 10%)
        uint256 crossPollinateStatReductionRatio; // Percentage of stat reduced from source (e.g., 50 = 50%)
    }

    GovernanceParameters public govParams;

    // Keeper Address (for triggering events)
    address public keeperAddress;

    // --- Events ---

    event TokenAddressesSet(address indexed et, address indexed rt, address indexed onft);
    event OrganismMinted(address indexed owner, uint256 indexed tokenId, uint256 energyCost);
    event OrganismBurned(address indexed owner, uint256 indexed tokenId);
    event EnergyStaked(address indexed user, uint256 indexed tokenId, uint256 amount);
    event EnergyUnstaked(address indexed user, uint256 indexed tokenId, uint256 amount, uint256 growthGained, uint256 reputationGained);
    event ReputationClaimed(address indexed user, uint256 amount);
    event OrganismStateUpdated(uint256 indexed tokenId, OrganismState newState); // Log state after any update
    event CrossPollinationOccurred(uint256 indexed sourceTokenId, uint256 indexed targetTokenId, uint256 vitalityTransferred, uint256 resilienceTransferred, uint256 complexityTransferred, uint256 energyConsumed);
    event GlobalEventApplied(uint256 indexed tokenId, bytes effectData); // tokenId 0 means applied globally
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes data, uint48 voteEndTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool vote, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event GovernanceParametersSet(GovernanceParameters params);
    event KeeperAddressSet(address indexed keeper);

    // --- Modifiers ---

    modifier onlyKeeperOrGovernance() {
        // Simplistic check: Either the designated keeper or holds sufficient RT and calls via a governance execution mechanism
        // (Note: A real governance execution would call this *from* the contract itself, verifying the call originated from a successful proposal execution flow).
        // For this example, we'll allow the keeper or the current owner (simulating governance execution admin).
        // A proper DAO would require more complex call forwarding/execution logic.
        require(_msgSender() == keeperAddress || _msgSender() == owner(), EtherealGardens__NotKeeperOrGovernance());
        _;
    }

    // --- Constructor ---

    constructor() Ownable(_msgSender()) Pausable(false) {
        // Set initial default governance parameters
        govParams = GovernanceParameters({
            vitalityGrowthRate: 1e12, // Example rates, adjust scaling
            resilienceGrowthRate: 1e12,
            complexityGrowthRate: 1e12,
            reputationEarnRate: 1e10, // 100 RT per ET per second (scaled)
            minEnergyToStake: 1e16, // 0.01 ET
            minReputationToPropose: 100e18, // 100 RT
            votingPeriod: 7 days, // 7 days voting period
            requiredVotesNumerator: 51, // 51%
            requiredVotesDenominator: 100,
            crossPollinateCostET: 1e17, // 0.1 ET
            crossPollinateStatTransferRatio: 20, // 20% transfer
            crossPollinateStatReductionRatio: 10 // 10% reduction from source
        });

        nextProposalId = 1;
    }

    // --- Admin/Setup Functions ---

    function setTokenAddresses(address _et, address _rt, address _onft) public onlyOwner {
        require(_et.isContract() && _rt.isContract() && _onft.isContract(), "Invalid token addresses");
        energyToken = IERC20(_et);
        reputationToken = IERC20(_rt);
        organismNFT = IERC721(_onft);
        emit TokenAddressesSet(_et, _rt, _onft);
    }

    // pause() and unpause() inherited from Pausable

    function setKeeperAddress(address _keeper) public onlyOwner {
        keeperAddress = _keeper;
        emit KeeperAddressSet(_keeper);
    }

    // --- Core Ecosystem Functions ---

    function mintOrganism(uint256 energyCost) public nonReentrant whenNotPaused {
        require(address(energyToken) != address(0) && address(organismNFT) != address(0), EtherealGardens__TokenAddressesNotSet());
        require(energyCost > 0, "Mint cost must be > 0");

        // Assume organismNFT contract has a mint function callable by this contract
        // This requires the ONFT contract to have a minter role or similar access control
        // For this example, we'll simulate the minting call and focus on the ET payment.
        // In a real system, you'd call organismNFT.safeMint(msg.sender, newItemId);
        // Let's assume the ONFT contract provides a function like `mintAndTransfer(address to, uint256 energyCost)` that returns the new token ID.
        // Since we don't have the actual ONFT contract code, let's simulate a simple mint and get the ID.
        // A common pattern is for the EtherealGardens contract to be the minter, and the ONFT contract allows this address.
        // We'll need to interact with the ONFT contract to get the next ID or rely on its return value.
        // For simplicity here, let's assume the ONFT contract allows this contract to mint and we get the ID.
        // A safer approach would be a pull pattern where user calls ONFT contract's mint, which then calls back EtherealGardens to deduct ET.

        // Let's use a simplified push pattern for demonstration:
        uint256 newItemId = organismNFT.totalSupply() + 1; // This is NOT how ERC721 works, use a proper mint function call!
        // Proper way requires organismNFT contract to have a function like:
        // function mint(address to) external returns (uint256 tokenId);
        // uint256 newItemId = organismNFT.mint(msg.sender); // Assuming this exists and returns the ID

        // For the sake of this example code compile-ability without a paired ONFT:
        // We'll just log the theoretical mint and focus on the state update.
        // A real implementation MUST interact with a real ERC721 contract.
        // uint256 newItemId = organismNFT.nextAvailableTokenId(); // Example placeholder

        // Transfer ET from user to contract
        energyToken.transferFrom(msg.sender, address(this), energyCost);

        // Initialize state for the new organism
        OrganismState memory newState;
        newState.vitality = 0;
        newState.resilience = 0;
        newState.complexity = 0;
        newState.lastGrowthTimestamp = uint48(block.timestamp);
        newState.stakedEnergy = 0;
        newState.owner = msg.sender;

        // Assuming organismNFT has been minted by now with newItemId
        organismStates[newItemId] = newState;

        emit OrganismMinted(msg.sender, newItemId, energyCost);
    }

    // function burnOrganism(uint256 tokenId) public nonReentrant whenNotPaused {
    //     require(organismNFT.ownerOf(tokenId) == msg.sender, EtherealGardens__NotOrganismOwner(tokenId, msg.sender));
    //     // Calculate final state and potential reputation before burning
    //     _updateOrganismGrowthAndReputation(tokenId);
    //
    //     // Unstake any remaining energy
    //     uint256 remainingEnergy = organismStates[tokenId].stakedEnergy;
    //     if (remainingEnergy > 0) {
    //         energyToken.transfer(msg.sender, remainingEnergy); // Return energy
    //     }
    //
    //     // Burn the NFT - requires organismNFT contract to have a burn function callable by this contract
    //     // organismNFT.burn(tokenId); // Example placeholder
    //
    //     // Clear state
    //     delete organismStates[tokenId];
    //
    //     emit OrganismBurned(msg.sender, tokenId);
    // }

    function stakeEnergyForOrganism(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused {
        require(address(energyToken) != address(0) && address(organismNFT) != address(0), EtherealGardens__TokenAddressesNotSet());
        require(organismNFT.ownerOf(tokenId) == msg.sender, EtherealGardens__NotOrganismOwner(tokenId, msg.sender));
        require(amount >= govParams.minEnergyToStake, EtherealGardens__EnergyStakeTooLow(govParams.minEnergyToStake));

        // Update state based on time elapsed before staking more
        _updateOrganismGrowthAndReputation(tokenId);

        // Transfer ET from user to contract
        energyToken.transferFrom(msg.sender, address(this), amount);

        organismStates[tokenId].stakedEnergy += amount;

        emit EnergyStaked(msg.sender, tokenId, amount);
        // Emit state update event after modifying staked energy
        emit OrganismStateUpdated(tokenId, organismStates[tokenId]);
    }

    function unstakeEnergyFromOrganism(uint256 tokenId) public nonReentrant whenNotPaused {
        require(address(energyToken) != address(0) && address(organismNFT) != address(0), EtherealGardens__TokenAddressesNotSet());
        require(organismNFT.ownerOf(tokenId) == msg.sender, EtherealGardens__NotOrganismOwner(tokenId, msg.sender));

        // Update state based on time elapsed before unstaking
        (uint256 growthGained, uint256 reputationGained) = _updateOrganismGrowthAndReputation(tokenId);

        uint256 stakedAmount = organismStates[tokenId].stakedEnergy;
        require(stakedAmount > 0, EtherealGardens__NoEnergyStakedForOrganism(tokenId));

        // Reset staked energy for this organism
        organismStates[tokenId].stakedEnergy = 0;
        // organismStates[tokenId].lastGrowthTimestamp = uint48(block.timestamp); // State already updated by _update...

        // Transfer ET back to user
        energyToken.transfer(msg.sender, stakedAmount);

        emit EnergyUnstaked(msg.sender, tokenId, stakedAmount, growthGained, reputationGained);
        // Emit state update event after unstaking
        emit OrganismStateUpdated(tokenId, organismStates[tokenId]);
    }

    function claimReputation() public nonReentrant whenNotPaused {
        require(address(reputationToken) != address(0), EtherealGardens__TokenAddressesNotSet());

        // Before claiming, ensure all potential reputation from active stakes is calculated
        // Iterate through all ONFTs owned by the user? This could be gas-intensive.
        // Alternative: Reputation calculation is triggered *only* on stake/unstake/claim/transfer.
        // Let's modify _updateOrganismGrowthAndReputation to update the user's unclaimed balance directly.

        uint256 amountToClaim = unclaimedReputation[_msgSender()];
        require(amountToClaim > 0, EtherealGardens__NothingToClaim(_msgSender()));

        unclaimedReputation[_msgSender()] = 0;

        // Mint/transfer RT to user - requires reputationToken to have a mint/transfer function callable by this contract
        // reputationToken.mint(msg.sender, amountToClaim); // If this contract is minter
        reputationToken.transfer(_msgSender(), amountToClaim); // If tokens pre-exist or contract holds a supply

        emit ReputationClaimed(_msgSender(), amountToClaim);
    }

    // --- Dynamic State & Interaction ---

    // Internal helper to calculate and apply growth and reputation gains
    // Called by stake, unstake, claim, crossPollinate, applyGlobalEventEffect, transfer hook (if implemented)
    // Returns growth and reputation earned *in this update*
    function _updateOrganismGrowthAndReputation(uint256 tokenId) internal returns (uint256 growthGained, uint256 reputationGained) {
        OrganismState storage state = organismStates[tokenId];
        uint48 lastTimestamp = state.lastGrowthTimestamp;
        uint48 currentTimestamp = uint48(block.timestamp);
        uint256 stakedEnergy = state.stakedEnergy;
        address organismOwner = state.owner; // Use stored owner or fetch ownerOf(tokenId)? Stored is faster. Ensure consistency.

        if (stakedEnergy == 0 || currentTimestamp <= lastTimestamp) {
             state.lastGrowthTimestamp = currentTimestamp;
             return (0, 0); // No growth or reputation if no energy or time hasn't passed
        }

        uint256 timeElapsed = currentTimestamp - lastTimestamp;

        // Calculate Growth
        // Growth scales with staked energy and time
        growthGained = (stakedEnergy * timeElapsed * govParams.vitalityGrowthRate) / (1e18); // Example scaling factor
        state.vitality += growthGained; // Apply growth directly to state

        uint256 resilienceGained = (stakedEnergy * timeElapsed * govParams.resilienceGrowthRate) / (1e18); // Example scaling factor
        state.resilience += resilienceGained;

        uint256 complexityGained = (stakedEnergy * timeElapsed * govParams.complexityGrowthRate) / (1e18); // Example scaling factor
        state.complexity += complexityGained;

        // Calculate Reputation
        // Reputation scales with staked energy and time
        reputationGained = (stakedEnergy * timeElapsed * govParams.reputationEarnRate) / (1e18); // Example scaling factor
        unclaimedReputation[organismOwner] += reputationGained; // Add to user's unclaimed balance

        state.lastGrowthTimestamp = currentTimestamp; // Update timestamp

        emit OrganismStateUpdated(tokenId, state);

        return (growthGained + resilienceGained + complexityGained, reputationGained); // Return total growth sum and rep gained
    }


    // View function to see the current potential state including pending growth
    function getCurrentOrganismState(uint256 tokenId) public view returns (OrganismState memory) {
        OrganismState memory state = organismStates[tokenId];
        uint48 lastTimestamp = state.lastGrowthTimestamp;
        uint48 currentTimestamp = uint48(block.timestamp);
        uint256 stakedEnergy = state.stakedEnergy;

        if (stakedEnergy > 0 && currentTimestamp > lastTimestamp) {
            uint256 timeElapsed = currentTimestamp - lastTimestamp;

            // Calculate potential growth without modifying state
            uint256 vitalityGain = (stakedEnergy * timeElapsed * govParams.vitalityGrowthRate) / (1e18);
            uint256 resilienceGain = (stakedEnergy * timeElapsed * govParams.resilienceGrowthRate) / (1e18);
            uint256 complexityGain = (stakedEnergy * timeElapsed * govParams.complexityGrowthRate) / (1e18);

            state.vitality += vitalityGain;
            state.resilience += resilienceGain;
            state.complexity += complexityGain;
            // Note: state.lastGrowthTimestamp is NOT updated in this view function
        }
        return state;
    }

     // View function to see the raw stored state
    function getOrganismStoredState(uint256 tokenId) public view returns (OrganismState memory) {
        return organismStates[tokenId];
    }

    function crossPollinateStats(uint256 sourceTokenId, uint256 targetTokenId, uint256 vitalityAmount, uint256 resilienceAmount, uint256 complexityAmount) public nonReentrant whenNotPaused {
        require(sourceTokenId != targetTokenId, EtherealGardens__CannotCrossPollinateSameOrganism(sourceTokenId));
        require(organismNFT.ownerOf(sourceTokenId) == msg.sender, EtherealGardens__NotOrganismOwner(sourceTokenId, msg.sender));
        require(organismNFT.ownerOf(targetTokenId) == msg.sender, EtherealGardens__NotOrganismOwner(targetTokenId, msg.sender));
        require(address(energyToken) != address(0), EtherealGardens__TokenAddressesNotSet());

        // Ensure state is up-to-date before checking stats and transferring
        _updateOrganismGrowthAndReputation(sourceTokenId);
        _updateOrganismGrowthAndReputation(targetTokenId);

        OrganismState storage sourceState = organismStates[sourceTokenId];
        OrganismState storage targetState = organismStates[targetTokenId];

        // Check if source has enough stats (after growth update)
        require(sourceState.vitality >= vitalityAmount, EtherealGardens__InsufficientSourceStats("Vitality", vitalityAmount));
        require(sourceState.resilience >= resilienceAmount, EtherealGardens__InsufficientSourceStats("Resilience", resilienceAmount));
        require(sourceState.complexity >= complexityAmount, EtherealGardens__InsufficientSourceStats("Complexity", complexityAmount));

        // Calculate costs and transfers based on config
        // Let's make it transfer a percentage of the *requested* amount
        uint256 actualVitalityTransfer = (vitalityAmount * govParams.crossPollinateStatTransferRatio) / 100;
        uint256 actualResilienceTransfer = (resilienceAmount * govParams.crossPollinateStatTransferRatio) / 100;
        uint256 actualComplexityTransfer = (complexityAmount * govParams.crossPollinateStatTransferRatio) / 100;

        // Reduce source stats based on reduction ratio (e.g., half of the requested amount is lost from source)
        uint256 vitalityReduction = (vitalityAmount * govParams.crossPollinateStatReductionRatio) / 100;
        uint256 resilienceReduction = (resilienceAmount * govParams.crossPollinateStatReductionRatio) / 100;
        uint256 complexityReduction = (complexityAmount * govParams.crossPollinateStatReductionRatio) / 100;

        // Apply stat changes
        sourceState.vitality -= vitalityReduction; // Reduce source
        sourceState.resilience -= resilienceReduction;
        sourceState.complexity -= complexityReduction;

        targetState.vitality += actualVitalityTransfer; // Add to target
        targetState.resilience += actualResilienceTransfer;
        targetState.complexity += actualComplexityTransfer;

        // Consume ET for the operation
        energyToken.transferFrom(msg.sender, address(this), govParams.crossPollinateCostET);

        emit CrossPollinationOccurred(
            sourceTokenId,
            targetTokenId,
            actualVitalityTransfer,
            actualResilienceTransfer,
            actualComplexityTransfer,
            govParams.crossPollinateCostET
        );
        emit OrganismStateUpdated(sourceTokenId, sourceState);
        emit OrganismStateUpdated(targetTokenId, targetState);
    }

    // Function to apply effects from external events (e.g., weather, solar flares)
    // effectData is bytes to allow flexibility in defining effects (e.g., ABI encoded struct)
    function applyGlobalEventEffect(uint256 tokenId, bytes memory effectData) external onlyKeeperOrGovernance whenNotPaused {
        // This function's logic depends heavily on how 'effectData' is structured and interpreted.
        // Example: effectData could encode a struct { int256 vitalityModifier, int256 resilienceModifier, int256 complexityModifier }
        // or it could identify a pre-defined event type.

        // We need to update the organism state before applying external effects
        _updateOrganismGrowthAndReputation(tokenId);

        OrganismState storage state = organismStates[tokenId];

        // --- Example Implementation (Basic) ---
        // Let's assume effectData is a simple integer multiplier for all stats (e.g., 1100 for +10%, 900 for -10%)
        // This is very basic; real implementation needs robust data decoding.
        require(effectData.length >= 32, "Invalid effectData format"); // Assume uint256 encoded
        uint256 multiplier = abi.decode(effectData, (uint256)); // Potentially unsafe decoding

        state.vitality = (state.vitality * multiplier) / 1000; // 1000 = 100%
        state.resilience = (state.resilience * multiplier) / 1000;
        state.complexity = (state.complexity * multiplier) / 1000;
        // --- End Example Implementation ---

        emit GlobalEventApplied(tokenId, effectData);
        emit OrganismStateUpdated(tokenId, state);
    }

    // --- Governance Functions ---

    // Note: A robust DAO would likely use a separate Governor contract
    // and a Timelock contract. This is a simplified in-contract example.

    function proposeParameterChange(bytes memory proposalData) public nonReentrant whenNotPaused {
        require(address(reputationToken) != address(0), EtherealGardens__TokenAddressesNotSet());
        // User must have enough RT to propose (and potentially stake it)
        // Let's require minimum balance, staking adds complexity (recover on cancel/execute)
        require(reputationToken.balanceOf(msg.sender) >= govParams.minReputationToPropose, EtherealGardens__InsufficientReputationToPropose(govParams.minReputationToPropose));

        uint256 proposalId = nextProposalId++;
        uint48 voteStartTime = uint48(block.timestamp);
        uint48 voteEndTime = voteStartTime + govParams.votingPeriod;

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            data: proposalData,
            voteStartTime: voteStartTime,
            voteEndTime: voteEndTime,
            yesVotes: 0,
            noVotes: 0,
            voted: new mapping(address => bool)(), // Initialize new mapping
            executed: false,
            canceled: false
        });

        emit ProposalCreated(proposalId, msg.sender, proposalData, voteEndTime);
    }

    function voteOnProposal(uint256 proposalId, bool vote) public nonReentrant whenNotPaused {
         require(address(reputationToken) != address(0), EtherealGardens__TokenAddressesNotSet());
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalId == proposalId && proposal.proposer != address(0), EtherealGardens__ProposalNotFound(proposalId)); // Check if proposal exists
        require(!proposal.executed && !proposal.canceled, EtherealGardens__ProposalAlreadyExecutedOrCanceled(proposalId));
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period is not active");
        require(!proposal.voted[msg.sender], EtherealGardens__AlreadyVoted(proposalId, msg.sender));

        uint256 votingPower = reputationToken.balanceOf(msg.sender); // Voting power is current RT balance
        require(votingPower > 0, "User has no voting power (RT balance)");

        proposal.voted[msg.sender] = true;
        if (vote) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        emit Voted(proposalId, msg.sender, vote, votingPower);
    }

    function executeProposal(uint256 proposalId) public nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalId == proposalId && proposal.proposer != address(0), EtherealGardens__ProposalNotFound(proposalId)); // Check if proposal exists
        require(!proposal.executed && !proposal.canceled, EtherealGardens__ProposalAlreadyExecutedOrCanceled(proposalId));
        require(block.timestamp > proposal.voteEndTime, EtherealGardens__ProposalVotingPeriodNotEnded(proposalId));

        // Check if proposal passed (simple majority based on voted tokens)
        // Total votes = yesVotes + noVotes. Need yesVotes / totalVotes >= requiredNumerator / requiredDenominator
        // Avoid division by zero if no one voted
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes > 0, EtherealGardens__ProposalNotExecutable(proposalId)); // Must have at least one vote

        bool passed = (proposal.yesVotes * govParams.requiredVotesDenominator) >= (totalVotes * govParams.requiredVotesNumerator);
        require(passed, EtherealGardens__ProposalNotExecutable(proposalId)); // Proposal did not pass

        // --- Execute the proposal action ---
        // This requires decoding proposal.data and calling the target function.
        // A robust system would use a separate contract or a dispatcher pattern.
        // For this example, we'll assume proposal.data directly sets a specific governance parameter.
        // Example: `proposalData` could be `abi.encode(parameterIndex, newValue)`

        // Let's assume a simple switch based on a prefix in `proposalData`
        require(proposal.data.length >= 32 + 32, EtherealGardens__InvalidProposalData()); // Needs at least index (uint256) and value (uint256)

        (uint256 paramIndex, uint256 newValue) = abi.decode(proposal.data, (uint256, uint256));

        // This switch structure is error-prone if proposalData is complex.
        // A better approach is the contract proposing *itself* calling a specific internal setter.
        // For simplicity here, we directly modify state based on index.
        if (paramIndex == 1) govParams.vitalityGrowthRate = newValue;
        else if (paramIndex == 2) govParams.resilienceGrowthRate = newValue;
        else if (paramIndex == 3) govParams.complexityGrowthRate = newValue;
        else if (paramIndex == 4) govParams.reputationEarnRate = newValue;
        else if (paramIndex == 5) govParams.minEnergyToStake = newValue;
        else if (paramIndex == 6) govParams.minReputationToPropose = uint255(newValue); // Needs care if newValue exceeds uint255
        // Note: Voting period and required votes are best set by the admin initially or via a separate, trusted process
        // else if (paramIndex == 7) govParams.votingPeriod = uint48(newValue); // Needs careful casting
        // else if (paramIndex == 8) govParams.requiredVotesNumerator = newValue;
        // else if (paramIndex == 9) govParams.requiredVotesDenominator = newValue;
        else if (paramIndex == 10) govParams.crossPollinateCostET = newValue;
        else if (paramIndex == 11) govParams.crossPollinateStatTransferRatio = newValue;
         else if (paramIndex == 12) govParams.crossPollinateStatReductionRatio = newValue;
        else revert("Invalid parameter index for execution");


        proposal.executed = true;
        emit ProposalExecuted(proposalId);
        emit GovernanceParametersSet(govParams); // Emit updated parameters
    }

    function cancelProposal(uint256 proposalId) public nonReentrant whenNotPaused {
         Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalId == proposalId && proposal.proposer != address(0), EtherealGardens__ProposalNotFound(proposalId)); // Check if proposal exists
        require(!proposal.executed && !proposal.canceled, EtherealGardens__ProposalAlreadyExecutedOrCanceled(proposalId));
        // Can be canceled by proposer before end, or anyone after end if not passed
        require(msg.sender == proposal.proposer || block.timestamp > proposal.voteEndTime, "Only proposer can cancel before vote ends");

        bool passed = false;
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        if (totalVotes > 0) {
             passed = (proposal.yesVotes * govParams.requiredVotesDenominator) >= (totalVotes * govParams.requiredNumerator);
        }

        require(msg.sender == proposal.proposer || !passed, "Cannot cancel a passed proposal after voting ends");

        proposal.canceled = true;
        // In a system with staked RT, you'd return the stake here
        emit ProposalCanceled(proposalId);
    }

    // Admin function to set governance constants initially (or via a separate governance proposal type)
    function setGovernanceParameters(
        uint256 _vitalityGrowthRate,
        uint256 _resilienceGrowthRate,
        uint256 _complexityGrowthRate,
        uint256 _reputationEarnRate,
        uint256 _minEnergyToStake,
        uint255 _minReputationToPropose,
        uint48 _votingPeriod,
        uint256 _requiredVotesNumerator,
        uint256 _requiredVotesDenominator,
        uint256 _crossPollinateCostET,
        uint256 _crossPollinateStatTransferRatio,
        uint256 _crossPollinateStatReductionRatio
    ) public onlyOwner { // Or make this callable only by governance execution
        govParams = GovernanceParameters({
            vitalityGrowthRate: _vitalityGrowthRate,
            resilienceGrowthRate: _resilienceGrowthRate,
            complexityGrowthRate: _complexityGrowthRate,
            reputationEarnRate: _reputationEarnRate,
            minEnergyToStake: _minEnergyToStake,
            minReputationToPropose: _minReputationToPropose,
            votingPeriod: _votingPeriod,
            requiredVotesNumerator: _requiredVotesNumerator,
            requiredVotesDenominator: _requiredVotesDenominator,
            crossPollinateCostET: _crossPollinateCostET,
            crossPollinateStatTransferRatio: _crossPollinateStatTransferRatio,
            crossPollinateStatReductionRatio: _crossPollinateStatReductionRatio
        });
        emit GovernanceParametersSet(govParams);
    }


    // --- View Functions ---

    function getUserReputationEarned(address user) public view returns (uint256) {
        return unclaimedReputation[user];
    }

    // getProposalState is public automatically via mapping public proposals

    // getGlobalParameters is public automatically via public govParams

    function getTotalEnergyStaked() public view returns (uint256) {
        if (address(energyToken) == address(0)) return 0;
        return energyToken.balanceOf(address(this)) - reputationToken.balanceOf(address(this)); // Assumes contract only holds staked ET and potentially RT if minted to itself
        // A more accurate way would be to sum stakedEnergy across all organisms, but that's expensive.
        // This relies on accounting: total ET in contract = staked ET + any ET collected for fees (like minting/crosspollination).
        // Need careful accounting if adding more ET collection points.
        // Let's simplify: Assume contract only holds staked ET and RT it needs for distribution.
        // The minting/crosspollination ET is "burned" from the user perspective by sending it here.
        // If RT is minted *by* this contract, its balance here is not "staked" ET.
        // Let's assume RT is pre-minted or minted elsewhere and sent here for distribution.
        // So, contract ET balance minus any buffer = total staked ET.
        // A simpler view function might just return the contract's ET balance.
        return energyToken.balanceOf(address(this)); // Simplified
    }

     function getTotalReputationMinted() public view returns (uint256) {
         if (address(reputationToken) == address(0)) return 0;
         // If RT is minted *by* this contract:
         // return reputationToken.totalSupply(); // Requires RT to be Ownable or have public supply view
         // If RT is transferred *to* this contract for distribution:
         return reputationToken.balanceOf(address(this)) + sumUnclaimedReputation(); // Requires summing all unclaimed... expensive.
         // Simplest: If RT is minted externally and transferred here for distribution, just show balance.
         return reputationToken.balanceOf(address(this)); // Very simplified - doesn't show claimed or pending
     }

    // This is expensive! Do not use on-chain iteration for large sets.
    // For off-chain tools, you'd get this data differently (e.g., subgraph, events).
    // function sumUnclaimedReputation() private view returns (uint256 total) {
    //    // This cannot be efficiently iterated on-chain
    //    // for (address user : allUsersWhoEarnedReputation) { // Need a way to track all users
    //    //     total += unclaimedReputation[user];
    //    // }
    //    // return total;
    //    // Placeholder - a real implementation avoids this.
    //    return 0;
    // }


    // getOrganismCount() public view returns (uint256) { return organismNFT.totalSupply(); } // Requires public totalSupply on ONFT

    // getOrganismOwner(uint256 tokenId) public view returns (address) { return organismNFT.ownerOf(tokenId); } // From ERC721

    function getOrganismEnergyStaked(uint256 tokenId) public view returns (uint256) {
        // Check if organism exists in state (optional, but robust)
        // require(organismStates[tokenId].owner != address(0), "Organism does not exist"); // Needs tracking existence
        return organismStates[tokenId].stakedEnergy;
    }

    // Additional view functions possible:
    // - Get active proposal IDs
    // - Get voting power of a user for a specific proposal (if voting power changes over time)
    // - Get list of organisms owned by user (requires iterating ERC721 balance, expensive on-chain)
    // - Get specific growth/reputation rates from govParams (public govParams already allows this)
}
```

**Explanation and Considerations:**

1.  **Token Addresses:** The contract relies on external ERC-20 and ERC-721 contracts for the tokens. Addresses must be set after deployment using `setTokenAddresses`.
2.  **Dynamic State:** The `OrganismState` struct stores the core attributes (`vitality`, `resilience`, `complexity`), the last time growth was calculated (`lastGrowthTimestamp`), the amount of staked energy (`stakedEnergy`), and the owner.
3.  **Growth Calculation:** The `_updateOrganismGrowthAndReputation` function is central. It calculates how much the stats and reputation have increased based on the time elapsed since the last update and the amount of staked energy. It applies the growth to the organism's stored state and adds earned reputation to the user's `unclaimedReputation`. This function is called *before* any action that might depend on or change the staking state (stake, unstake, claim, cross-pollinate, apply event). `getCurrentOrganismState` provides a view *without* triggering a state update.
4.  **Reputation:** RT is earned proportionally to staked ET and time. The user must call `claimReputation` to transfer the accumulated RT to their wallet.
5.  **Cross-Pollination:** A creative function allowing owners to transfer stats between their ONFTs. It consumes ET and reduces stats from the source ONFT, simulating a cost and drain. The transfer amount is a percentage of the *requested* amount, and the reduction from the source is a percentage of the *requested* amount (controlled by `govParams`).
6.  **Global Events:** `applyGlobalEventEffect` provides a hook for external factors. It's secured by `onlyKeeperOrGovernance`, meaning either a designated `keeperAddress` or a successful governance execution can call it. The `effectData` is a flexible way to pass parameters defining the event's impact. The example implementation is basic; a real one would need robust data parsing.
7.  **Governance:** A simplified in-contract DAO allows RT holders to propose and vote on changing global parameters (`govParams`). Execution requires the voting period to end and the proposal to meet the required vote threshold. The execution logic assumes a simple mapping of parameter index to the state variable, which is brittle. A real DAO would use a more secure and flexible execution pattern (e.g., calling internal functions via `delegatecall` from a trusted source).
8.  **Pausable and ReentrancyGuard:** Standard OpenZeppelin patterns for emergency pausing and preventing re-entrancy, especially important with external token calls.
9.  **Gas Costs:** Storing and updating state on-chain is expensive. The `OrganismState` struct is designed to be relatively compact. View functions that calculate dynamic state (`getCurrentOrganismState`) are fine, but functions requiring iteration (like summing all unclaimed reputation across users) are avoided for on-chain calls.
10. **Modularity:** Assumes token contracts exist. A full system would involve deploying and linking these.
11. **Error Handling:** Uses custom errors (Solidity 0.8+) for clearer debugging messages.
12. **Missing Features (for brevity/complexity):** Transferring ONFTs while staked (needs handling of reputation and ownership of staked energy), chilling periods on unstaking, slashing mechanics, more complex event types or cross-NFT interactions, gas optimizations for larger-scale use, a dedicated governance executor contract. The `mintOrganism` function is a placeholder; a real implementation needs careful coordination with the ONFT contract's minting logic. The governance execution is a simplification; real DAOs are more complex.

This contract provides a foundation for a dynamic on-chain ecosystem, combining multiple advanced concepts beyond simple token transfers or static NFTs. Remember that deploying and testing such a system requires careful design and auditing of the associated token contracts as well.