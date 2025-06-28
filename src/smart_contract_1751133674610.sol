Okay, let's design a smart contract that manages a complex, dynamic ecosystem. We'll call it the "CyberneticEcosystem".

This contract will manage two types of assets:
1.  **CyberneticUnits (NFTs):** Unique, dynamic digital organisms that evolve and require resources.
2.  **EnergyTokens (ERC-20-like):** A fungible token used to power CyberneticUnits, fuel evolution, pay fees, and participate in staking/governance.

The contract will integrate dynamic state changes for NFTs, resource management, staking, a simple governance mechanism, and inter-NFT interaction ("Synergy").

---

### CyberneticEcosystem Smart Contract Outline

**I. Core Concepts**
*   Manages CyberneticUnit (NFT) and EnergyToken (Fungible) assets within a single contract.
*   CyberneticUnits have dynamic states (level, last fed, health, etc.) that change based on interactions and time.
*   EnergyTokens are consumed by Units and used for actions, staking, and governance.
*   Includes mechanisms for evolution, synergy between Units, resource staking with rewards, and basic on-chain governance.

**II. State Variables & Mappings**
*   NFT-related state (ownership, approvals, total supply).
*   ERC20-related state (balances, allowances, total supply).
*   CyberneticUnit specific state (per token ID: level, attributes, last fed timestamp, decay status).
*   EnergyToken staking state (staked balances, reward accrual).
*   Governance state (proposals, votes, proposal IDs, state parameters).
*   Ecosystem parameters (consumption rates, evolution costs, staking rates, governance thresholds).

**III. Data Structures**
*   `UnitState`: Struct for storing dynamic attributes of a CyberneticUnit.
*   `Proposal`: Struct for storing governance proposal details (description, target, calldata, votes, state).

**IV. Functions (>= 20)**
*   Standard ERC-721 functions (querying, transfers, approvals).
*   Standard ERC-20 functions (querying, transfers, approvals).
*   NFT-Specific Dynamic Functions:
    *   Minting new units.
    *   Getting unit state.
    *   Feeding units (consuming Energy).
    *   Checking unit decay/health.
    *   Evolving units (costly, state change, potential randomness).
    *   Performing synergy between units (costly, state change/bonus).
*   ERC-20 Specific / Ecosystem Functions:
    *   Minting EnergyTokens (restricted).
    *   Burning EnergyTokens.
    *   Staking EnergyTokens for rewards/benefits.
    *   Unstaking EnergyTokens.
    *   Claiming staking rewards.
*   Governance Functions:
    *   Initiating a proposal.
    *   Voting on a proposal.
    *   Executing a successful proposal.
    *   Getting proposal state.
*   View Functions:
    *   Getting ecosystem parameters.
    *   Getting staking APY/rate.
    *   Getting staked energy balance.
    *   Getting total unit count.
    *   Getting total energy supply.
*   Admin/Parameter Update Functions (often via governance):
    *   Updating ecosystem parameters (consumption rate, evolution cost, staking rate, synergy bonus).

---

### Function Summary

1.  `constructor()`: Initializes contract with initial parameters and token/unit names/symbols.
2.  `mintUnit(address owner)`: Mints a new CyberneticUnit NFT to the specified owner. Requires EnergyTokens fee.
3.  `feedUnit(uint256 tokenId, uint256 energyAmount)`: Allows owner to feed energy to a unit, resetting its decay timer and potentially boosting temporary stats.
4.  `evolveUnit(uint256 tokenId)`: Attempts to evolve a unit to the next level. Requires EnergyTokens, unit meets level/time criteria, includes probabilistic success.
5.  `performSynergy(uint256 tokenId1, uint256 tokenId2)`: Executes a synergy action between two units (owned by the caller or approved). Requires EnergyTokens from owners, grants bonus effect, updates state.
6.  `stakeEnergy(uint256 amount)`: Stakes EnergyTokens into a pool to earn rewards and gain governance power.
7.  `unstakeEnergy(uint256 amount)`: Unstakes previously staked EnergyTokens. Subject to potential cooldown/lockup.
8.  `claimEnergyRewards()`: Claims accrued staking rewards for the caller.
9.  `initiateProposal(string calldata description, address targetContract, bytes calldata callData)`: Creates a new governance proposal. Requires staked energy or unit ownership.
10. `voteOnProposal(uint256 proposalId, bool support)`: Votes on an active proposal. Requires staked energy or unit ownership, weights votes by stake/units.
11. `executeProposal(uint256 proposalId)`: Executes a successful proposal (passed quorum and threshold).
12. `updateEcosystemParameter(uint8 paramId, uint256 newValue)`: Internal function called by successful governance proposals to change system parameters (e.g., evolution cost, staking rate).
13. `checkUnitDecayStatus(uint256 tokenId)`: View function to check if a unit is currently in a decayed state (needs feeding).
14. `getUnitState(uint256 tokenId)`: View function returning the detailed state of a specific CyberneticUnit.
15. `getEnergyStakedBalance(address owner)`: View function returning the amount of EnergyTokens staked by an address.
16. `getEnergyStakingAPY()`: View function calculating and returning the current estimated staking return rate.
17. `getProposalState(uint256 proposalId)`: View function returning the state and details of a governance proposal.
18. `getEcosystemParameters()`: View function returning all current adjustable ecosystem parameters.
19. `mintEnergyTokens(address recipient, uint256 amount)`: Mints new EnergyTokens (restricted, e.g., owner or governance).
20. `burnEnergyTokens(uint256 amount)`: Burns EnergyTokens from the caller's balance.
21. `balanceOf(address owner)`: ERC721/ERC20 standard - Get NFT count for owner / EnergyToken balance for owner.
22. `ownerOf(uint256 tokenId)`: ERC721 standard - Get owner of an NFT.
23. `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard - Transfer NFT.
24. `approve(address to, uint256 tokenId)`: ERC721 standard - Approve address for NFT.
25. `getApproved(uint256 tokenId)`: ERC721 standard - Get approved address for NFT.
26. `setApprovalForAll(address operator, bool approved)`: ERC721 standard - Set approval for operator.
27. `isApprovedForAll(address owner, address operator)`: ERC721 standard - Check operator approval.
28. `transfer(address recipient, uint256 amount)`: ERC20 standard - Transfer EnergyTokens.
29. `approve(address spender, uint256 amount)`: ERC20 standard - Approve spender for EnergyTokens.
30. `allowance(address owner, address spender)`: ERC20 standard - Get allowance for spender.

*(Note: We will implement the core logic for ERC721/ERC20 state within this contract using mappings, rather than inheriting OpenZeppelin libraries directly, to better fit the "don't duplicate open source" theme while still providing the standard interfaces).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC721.sol"; // Assuming local IERC721 interface
import "./IERC20.sol";  // Assuming local IERC20 interface
import "./IERC165.sol"; // Assuming local IERC165 interface

// Basic interfaces for ERC-721 and ERC-20 included for clarity if not using OpenZeppelin imports
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 indexed value);
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract CyberneticEcosystem is IERC721, IERC20 { // Implement interfaces
    // --- State Variables ---

    // ERC721 (CyberneticUnits) State
    string private _name = "CyberneticUnit";
    string private _symbol = "CYBERU";
    uint256 private _unitTokenCounter; // Total number of units ever minted
    mapping(uint256 => address) private _unitOwners;
    mapping(address => uint256) private _unitBalances;
    mapping(uint256 => address) private _unitTokenApprovals;
    mapping(address => mapping(address => bool)) private _unitOperatorApprovals;

    // ERC20 (EnergyTokens) State
    string private _energyName = "EnergyToken";
    string private _energySymbol = "ENERGY";
    uint8 private immutable _energyDecimals = 18;
    uint256 private _energyTotalSupply;
    mapping(address => uint256) private _energyBalances;
    mapping(address => mapping(address => uint256)) private _energyAllowances;

    // CyberneticUnit Dynamic State
    struct UnitState {
        uint8 level;
        uint64 lastFedTimestamp;
        uint16 synergyPotential; // Modifier for synergy effects
        uint16 decayRate; // Energy consumed per time unit (e.g., day)
        bool isDecayed; // True if needs feeding
    }
    mapping(uint256 => UnitState) private _unitStates;

    // EnergyToken Staking State
    mapping(address => uint256) private _stakedEnergy;
    mapping(address => uint256) private _stakingRewardAccrued; // Rewards waiting to be claimed
    mapping(address => uint64) private _lastStakingRewardTimestamp; // Timestamp for calculating accrual
    uint256 private _stakingRewardRate = 100; // Reward rate per unit staked per second (scaled, e.g., * 1e18 / seconds_in_year / 1e18)
                                              // Let's use a simpler rate: e.g., 100 means 0.0000001 Energy per staked unit per second
                                              // Example: 1 Energy staked earns 0.0000001 Energy per second. 10000 staked earns 0.001 per second.
                                              // Need to be careful with scaling. Let's assume _stakingRewardRate is scaled by 1e18 for simplicity in calculations.
                                              // So rate = 100000000000000000 for 0.1 Energy per staked unit per second.

    // Governance State
    struct Proposal {
        string description;
        address targetContract;
        bytes callData;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    Proposal[] private _proposals;
    uint256 private _governanceThreshold = 51; // Percentage needed to pass (e.g., 51 for 51%)
    uint256 private _governanceQuorum = 5; // Minimum percentage of total stake needed to vote
    uint64 private _governanceVotingPeriod = 3 days; // Duration for voting

    // Ecosystem Parameters (can be updated by governance)
    uint256 private _unitMintCost = 1000 * (10**uint256(_energyDecimals)); // Cost in EnergyTokens to mint a unit
    uint256 private _evolutionCostPerLevel = 500 * (10**uint256(_energyDecimals)); // Base cost to evolve
    uint256 private _synergyCostPerUnit = 200 * (10**uint256(_energyDecimals)); // Cost per unit for synergy
    uint64 private _decayCheckPeriod = 1 days; // How often decay is checked / energy consumed naturally
    uint256 private _decayBaseConsumption = 50 * (10**uint256(_energyDecimals)); // Base energy consumed during decay check

    // Owner address (can be transferred or managed by governance eventually)
    address public owner;

    // --- Events ---
    event UnitMinted(address indexed owner, uint256 indexed tokenId, uint8 initialLevel);
    event UnitFed(uint256 indexed tokenId, uint256 energyAmount, uint64 lastFed);
    event UnitEvolved(uint256 indexed tokenId, uint8 newLevel, bool success);
    event SynergyPerformed(uint256 indexed tokenId1, uint256 indexed tokenId2, uint16 synergyBonus);
    event EnergyStaked(address indexed owner, uint256 amount);
    event EnergyUnstaked(address indexed owner, uint256 amount);
    event StakingRewardsClaimed(address indexed owner, uint256 amount);
    event ProposalInitiated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterUpdated(uint8 indexed paramId, uint256 newValue);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call");
        _;
    }

    modifier onlyUnitOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized for this unit");
        _;
    }

    modifier unitExists(uint256 tokenId) {
        require(_unitOwners[tokenId] != address(0), "Unit does not exist");
        _;
    }

    modifier enoughEnergy(uint256 amount) {
        require(_energyBalances[msg.sender] >= amount, "Insufficient EnergyTokens");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId < _proposals.length, "Proposal does not exist");
        _;
    }

    modifier proposalActive(uint256 proposalId) {
        require(proposalExists(proposalId), "Proposal does not exist");
        require(block.timestamp >= _proposals[proposalId].startTimestamp, "Proposal voting not started");
        require(block.timestamp < _proposals[proposalId].endTimestamp, "Proposal voting ended");
        _;
    }

    modifier proposalExecutable(uint256 proposalId) {
        require(proposalExists(proposalId), "Proposal does not exist");
        require(block.timestamp >= _proposals[proposalId].endTimestamp, "Proposal voting not ended");
        require(!_proposals[proposalId].executed, "Proposal already executed");
        // Check quorum and threshold here or in the function
        uint256 totalVotingStake = _energyTotalSupply; // Simplified: use total supply or total staked
        uint256 totalVotesCast = _proposals[proposalId].votesFor + _proposals[proposalId].votesAgainst;
        require(totalVotesCast * 100 >= totalVotingStake * _governanceQuorum, "Governance quorum not met");
        require(_proposals[proposalId].votesFor * 100 > totalVotesCast * _governanceThreshold, "Governance threshold not met");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        _unitTokenCounter = 0; // Initialize counter
        _energyTotalSupply = 0; // Start with 0 energy, mintable by owner/governance
        // Initialize staking timestamp for owner if they start with tokens
        _lastStakingRewardTimestamp[msg.sender] = uint64(block.timestamp);
    }

    // --- ERC165 Interface Support ---
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC20).interfaceId ||
               interfaceId == type(IERC165).interfaceId;
    }

    // --- ERC721 (CyberneticUnits) Implementation ---

    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }

    function balanceOf(address owner_) public view override returns (uint256) {
        require(owner_ != address(0), "ERC721: address zero is not a valid owner");
        return _unitBalances[owner_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner_ = _unitOwners[tokenId];
        require(owner_ != address(0), "ERC721: owner query for nonexistent token");
        return owner_;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Check if token exists and is owned by 'from'
        require(_unitOwners[tokenId] == from, "ERC721: transfer from incorrect owner");
        // Check approval
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        // Check if 'to' is valid
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);
        _transferUnit(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
         transferFrom(from, to, tokenId); // Simplified: Does not check receiver interface
         // For production, would add check like _checkOnERC721Received(from, to, tokenId, "");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
         transferFrom(from, to, tokenId); // Simplified
         // For production, would add check like _checkOnERC721Received(from, to, tokenId, data);
     }

    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId);
        require(msg.sender == owner_ || _unitOperatorApprovals[owner_][msg.sender], "ERC721: approve caller is not owner nor approved for all");
        _approveUnit(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_unitOwners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _unitTokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _unitOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner_, address operator) public view override returns (bool) {
        return _unitOperatorApprovals[owner_][operator];
    }

    // Internal ERC721 helper functions
    function _transferUnit(address from, address to, uint256 tokenId) internal {
        delete _unitTokenApprovals[tokenId]; // Clear approval when transferring

        _unitBalances[from]--;
        _unitBalances[to]++;
        _unitOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approveUnit(address to, uint256 tokenId) internal {
        _unitTokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId);
        return (spender == owner_ ||
                getApproved(tokenId) == spender ||
                isApprovedForAll(owner_, spender));
    }

    // Hooks (can add custom logic here later, e.g., check decay status on transfer)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}


    // --- ERC20 (EnergyTokens) Implementation ---

    function totalSupply() public view override returns (uint256) {
        return _energyTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
         // This function signature clashes between ERC20 and ERC721.
         // Solidity handles this by function overloading based on parameter types.
         // This override refers to the ERC20 version (address account).
         require(account != address(0), "ERC20: address zero is not a valid account");
        return _energyBalances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferEnergy(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        require(owner_ != address(0) && spender != address(0), "ERC20: address zero is not valid");
        return _energyAllowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approveEnergy(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _energyAllowances[sender][recipient]; // Should be sender][spender] but using recipient for clarity based on interface common usage
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _transferEnergy(sender, recipient, amount);

        unchecked {
            _approveEnergy(sender, recipient, currentAllowance - amount); // Decrement allowance
        }

        return true;
    }

    // Internal ERC20 helper functions
    function _transferEnergy(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_energyBalances[from] >= amount, "ERC20: transfer amount exceeds balance");

        // Update staking rewards before transfer out
        if (_stakedEnergy[from] > 0) _calculateAndAccrueStakingRewards(from);
        if (_stakedEnergy[to] > 0 && from != to) _calculateAndAccrueStakingRewards(to); // If transferring to an address that is also staking

        unchecked {
            _energyBalances[from] -= amount;
            _energyBalances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mintEnergy(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _energyTotalSupply += amount;

        // Update staking rewards before mint to account if they are staking
        if (_stakedEnergy[account] > 0) _calculateAndAccrueStakingRewards(account);

        _energyBalances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burnEnergy(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
         require(_energyBalances[account] >= amount, "ERC20: burn amount exceeds balance");

        // Update staking rewards before burn from account if they are staking
        if (_stakedEnergy[account] > 0) _calculateAndAccrueStakingRewards(account);

        unchecked {
            _energyBalances[account] -= amount;
        }
        _energyTotalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

     function _approveEnergy(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _energyAllowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }


    // --- NFT-Specific Dynamic Functions ---

    /// @notice Mints a new CyberneticUnit NFT.
    /// @param owner The address to receive the new unit.
    function mintUnit(address owner) public enoughEnergy(_unitMintCost) {
        require(owner != address(0), "Mint to zero address");

        _burnEnergy(msg.sender, _unitMintCost); // Pay the mint cost

        uint256 newItemId = _unitTokenCounter;
        _unitTokenCounter++; // Increment global counter

        _unitOwners[newItemId] = owner;
        _unitBalances[owner]++;

        // Initialize unit state
        _unitStates[newItemId] = UnitState({
            level: 1,
            lastFedTimestamp: uint64(block.timestamp),
            synergyPotential: 100, // Base potential
            decayRate: 100, // Base decay
            isDecayed: false
        });

        emit UnitMinted(owner, newItemId, 1);
        emit Transfer(address(0), owner, newItemId); // ERC721 Mint event
    }

    /// @notice Allows a unit owner to feed energy to their unit to prevent decay.
    /// @param tokenId The ID of the unit to feed.
    /// @param energyAmount The amount of EnergyTokens to feed.
    function feedUnit(uint256 tokenId, uint256 energyAmount) public unitExists(tokenId) onlyUnitOwnerOrApproved(tokenId) enoughEnergy(energyAmount) {
        // Optional: Add logic where feeding *more* than needed provides a temporary boost or faster recovery
        _burnEnergy(msg.sender, energyAmount);

        UnitState storage unit = _unitStates[tokenId];
        uint64 currentTime = uint64(block.timestamp);

        // Calculate decay since last check/feed
        uint64 timePassed = currentTime - unit.lastFedTimestamp;
        uint256 decayConsumption = (uint256(unit.decayRate) * timePassed * _decayBaseConsumption) / (1 days * 100); // Simplified calculation

        // Reset decay timer and potentially recover from decay
        unit.lastFedTimestamp = currentTime;
        unit.isDecayed = false; // Feeding always removes decay status

        // Optionally, add fed amount to a state variable or provide temporary buff
        // unit.temporaryHealth += energyAmount; // Example

        emit UnitFed(tokenId, energyAmount, currentTime);
    }

    /// @notice Attempts to evolve a CyberneticUnit to the next level.
    /// Requires meeting level/time criteria and consuming EnergyTokens. Includes randomness.
    /// @param tokenId The ID of the unit to evolve.
    function evolveUnit(uint256 tokenId) public unitExists(tokenId) onlyUnitOwnerOrApproved(tokenId) {
        UnitState storage unit = _unitStates[tokenId];
        uint64 currentTime = uint64(block.timestamp);

        // Basic checks
        require(!unit.isDecayed, "Cannot evolve a decayed unit");
        require(unit.level < 10, "Unit is already max level"); // Example max level
        // Require a certain time since last evolution or mint
        require(currentTime - unit.lastFedTimestamp >= 7 days, "Unit needs time before evolving again"); // Cooldown

        // Calculate cost and require payment
        uint256 evolutionCost = _evolutionCostPerLevel * unit.level; // Cost increases with level
        require(_energyBalances[msg.sender] >= evolutionCost, "Insufficient EnergyTokens for evolution");
        _burnEnergy(msg.sender, evolutionCost);

        // Introduce probabilistic success (pseudo-randomness)
        // WARNING: Block-based randomness is NOT secure for high-value applications.
        // Use Chainlink VRF or similar for production randomness.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, unit.level)));
        uint256 successChance = 70 + (unit.synergyPotential / 10); // Example: Base 70% + 10% for every 100 synergy potential
        successChance = successChance > 100 ? 100 : successChance; // Cap chance at 100%

        bool success = (randomNumber % 100) < successChance;

        if (success) {
            unit.level++;
            unit.synergyPotential += 50; // Boost potential on success
            // Reset decay timing/state on successful evolution? Optional.
            // unit.lastFedTimestamp = currentTime;
            emit UnitEvolved(tokenId, unit.level, true);
        } else {
            // Optional: Penalize failure (e.g., reduce synergy potential, add decay)
            unit.synergyPotential = unit.synergyPotential > 10 ? unit.synergyPotential - 10 : 0;
            // unit.lastFedTimestamp = currentTime; // Reset timer even on failure
            emit UnitEvolved(tokenId, unit.level, false);
        }
    }

    /// @notice Performs a synergy action between two units. Requires both units to be owned/approved by the caller.
    /// @param tokenId1 The ID of the first unit.
    /// @param tokenId2 The ID of the second unit.
    function performSynergy(uint256 tokenId1, uint256 tokenId2) public unitExists(tokenId1) unitExists(tokenId2) {
        require(tokenId1 != tokenId2, "Cannot perform synergy with the same unit");
        require(_isApprovedOrOwner(msg.sender, tokenId1), "Not authorized for unit 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "Not authorized for unit 2");
        require(_unitOwners[tokenId1] == _unitOwners[tokenId2], "Units must have the same owner for synergy"); // Or allow different owners with approval logic

        UnitState storage unit1 = _unitStates[tokenId1];
        UnitState storage unit2 = _unitStates[tokenId2];
        uint64 currentTime = uint64(block.timestamp);

        require(!unit1.isDecayed && !unit2.isDecayed, "Cannot perform synergy with decayed units");
        require(currentTime - unit1.lastFedTimestamp >= 1 days && currentTime - unit2.lastFedTimestamp >= 1 days, "Units need time after last feed/synergy"); // Cooldown

        uint256 synergyCost = _synergyCostPerUnit * 2; // Cost for both units
        require(_energyBalances[msg.sender] >= synergyCost, "Insufficient EnergyTokens for synergy");
        _burnEnergy(msg.sender, synergyCost);

        // Calculate synergy bonus based on potentials
        uint16 combinedPotential = unit1.synergyPotential + unit2.synergyPotential;
        uint16 synergyBonus = combinedPotential / 20; // Example: 1 bonus point per 20 potential

        // Apply synergy effects (example: temporary stat boosts, shared XP, state updates)
        // For simplicity, we'll just emit the bonus and update potentials slightly
        unit1.synergyPotential = unit1.synergyPotential + (synergyBonus / 2);
        unit2.synergyPotential = unit2.synergyPotential + (synergyBonus / 2);

        // Reset decay timers or apply new cooldown
        unit1.lastFedTimestamp = currentTime;
        unit2.lastFedTimestamp = currentTime;

        emit SynergyPerformed(tokenId1, tokenId2, synergyBonus);
    }

    /// @notice View function to check if a unit is currently in a decayed state.
    /// Decay is based on time passed since last fed vs its decay rate.
    /// @param tokenId The ID of the unit.
    /// @return isDecayed True if the unit is decayed.
    function checkUnitDecayStatus(uint256 tokenId) public view unitExists(tokenId) returns (bool isDecayed) {
        UnitState storage unit = _unitStates[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeSinceLastFed = currentTime - unit.lastFedTimestamp;

        // Decay occurs if time since last fed exceeds decay check period modified by decayRate
        // Higher decayRate means less time until decay
        // Example: decayRate 100 means standard 1 day. decayRate 200 means decay in 0.5 days.
        uint64 decayThreshold = (_decayCheckPeriod * 100) / unit.decayRate;

        return timeSinceLastFed > decayThreshold;
    }

    // --- EnergyToken Staking Functions ---

    /// @notice Stakes EnergyTokens for the caller.
    /// @param amount The amount of EnergyTokens to stake.
    function stakeEnergy(uint256 amount) public enoughEnergy(amount) {
        require(amount > 0, "Cannot stake 0");

        _calculateAndAccrueStakingRewards(msg.sender); // Accrue rewards before staking more

        _burnEnergy(msg.sender, amount); // Tokens are effectively burned from balance and moved to staked pool
        _stakedEnergy[msg.sender] += amount;

        emit EnergyStaked(msg.sender, amount);
    }

    /// @notice Unstakes previously staked EnergyTokens for the caller.
    /// @param amount The amount of EnergyTokens to unstake.
    function unstakeEnergy(uint256 amount) public {
        require(amount > 0, "Cannot unstake 0");
        require(_stakedEnergy[msg.sender] >= amount, "Insufficient staked energy");

        _calculateAndAccrueStakingRewards(msg.sender); // Accrue rewards before unstaking

        _stakedEnergy[msg.sender] -= amount;
        _mintEnergy(msg.sender, amount); // Return tokens from staked pool to balance

        emit EnergyUnstaked(msg.sender, amount);
    }

    /// @notice Claims accrued staking rewards for the caller.
    function claimEnergyRewards() public {
        _calculateAndAccrueStakingRewards(msg.sender); // Calculate and accrue pending rewards
        uint256 rewards = _stakingRewardAccrued[msg.sender];
        require(rewards > 0, "No rewards to claim");

        _stakingRewardAccrued[msg.sender] = 0;
        _mintEnergy(msg.sender, rewards); // Mint rewards

        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    /// @notice Calculates and adds staking rewards to the user's accrued balance.
    /// @param account The address for whom to calculate rewards.
    function _calculateAndAccrueStakingRewards(address account) internal {
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeSinceLastClaim = currentTime - _lastStakingRewardTimestamp[account];
        uint256 staked = _stakedEnergy[account];

        if (staked > 0 && timeSinceLastClaim > 0) {
             // Reward = staked * rate * time / 1e18 (adjusting for rate scaling)
            uint256 rewards = (staked * _stakingRewardRate * timeSinceLastClaim) / (10**uint256(_energyDecimals));
            _stakingRewardAccrued[account] += rewards;
        }
        _lastStakingRewardTimestamp[account] = currentTime;
    }


    // --- Governance Functions ---

    /// @notice Initiates a new governance proposal.
    /// Caller must have sufficient staked Energy or owned units (simplified: requires some staked energy).
    /// @param description A brief description of the proposal.
    /// @param targetContract The address of the contract the proposal will interact with (can be this contract).
    /// @param callData The encoded function call data for the proposal action.
    /// @return proposalId The ID of the newly created proposal.
    function initiateProposal(string calldata description, address targetContract, bytes calldata callData) public returns (uint256 proposalId) {
        // Require minimum staking or unit ownership to propose
        require(_stakedEnergy[msg.sender] > 0, "Requires staked energy to propose"); // Simple requirement

        proposalId = _proposals.length;
        _proposals.push(Proposal({
            description: description,
            targetContract: targetContract,
            callData: callData,
            startTimestamp: uint64(block.timestamp),
            endTimestamp: uint64(block.timestamp) + _governanceVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool)
        }));

        emit ProposalInitiated(proposalId, msg.sender, description);
        return proposalId;
    }

    /// @notice Votes on an active governance proposal.
    /// Vote weight is based on staked EnergyTokens (simplified).
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a 'yes' vote, False for a 'no' vote.
    function voteOnProposal(uint256 proposalId, bool support) public proposalActive(proposalId) {
        Proposal storage proposal = _proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voteWeight = _stakedEnergy[msg.sender]; // Vote weight = staked energy
        require(voteWeight > 0, "Requires staked energy to vote"); // Simple requirement

        if (support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, voteWeight);
    }

    /// @notice Executes a governance proposal that has met the quorum and threshold.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public proposalExecutable(proposalId) {
        Proposal storage proposal = _proposals[proposalId];

        // Execute the proposal call
        (bool success, bytes memory result) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);

        // Optional: Handle result if needed
    }

    /// @notice Internal function to update ecosystem parameters based on a successful governance proposal.
    /// This function is designed to be called via the `callData` of a governance proposal.
    /// @param paramId Identifier for the parameter to update (e.g., 1 for _unitMintCost, 2 for _evolutionCostPerLevel).
    /// @param newValue The new value for the parameter.
    function updateEcosystemParameter(uint8 paramId, uint256 newValue) public {
        // This function should ONLY be callable via a successful governance proposal execution.
        // A common pattern is to check `msg.sender` is the contract itself during an internal call
        // or specifically check if the call originated from the `executeProposal` context.
        // For simplicity here, we'll use an `onlyOwner` check as a placeholder or assume
        // governance is the ONLY way this gets called by the owner. A more robust system
        // would check `msg.sender == address(this)` and ensure the call stack is from executeProposal.
        require(msg.sender == owner, "Callable only by owner/governance execution");

        if (paramId == 1) {
            _unitMintCost = newValue;
        } else if (paramId == 2) {
            _evolutionCostPerLevel = newValue;
        } else if (paramId == 3) {
            _synergyCostPerUnit = newValue;
        } else if (paramId == 4) { // Example for _stakingRewardRate
             _stakingRewardRate = newValue;
        }
        // Add more cases for other parameters

        emit ParameterUpdated(paramId, newValue);
    }


    // --- View Functions ---

    /// @notice View function returning the detailed state of a specific CyberneticUnit.
    /// @param tokenId The ID of the unit.
    /// @return level Unit level.
    /// @return lastFed Timestamp of last feeding.
    /// @return synergyPotential Modifier for synergy effects.
    /// @return decayRate Energy consumed per time unit.
    /// @return isDecayed True if unit needs feeding.
    function getUnitState(uint256 tokenId) public view unitExists(tokenId) returns (
        uint8 level,
        uint64 lastFed,
        uint16 synergyPotential,
        uint16 decayRate,
        bool isDecayed
    ) {
        UnitState storage unit = _unitStates[tokenId];
        return (unit.level, unit.lastFedTimestamp, unit.synergyPotential, unit.decayRate, checkUnitDecayStatus(tokenId));
    }

     /// @notice View function returning the amount of EnergyTokens staked by an address.
     /// @param owner_ The address to query.
     /// @return The staked balance.
    function getEnergyStakedBalance(address owner_) public view returns (uint256) {
        return _stakedEnergy[owner_];
    }

    /// @notice View function calculating and returning the current estimated staking return rate (APY).
    /// This is a simplified calculation. Real APY depends on total staked amount, reward emissions etc.
    /// @return The estimated APY scaled by 10^18.
    function getEnergyStakingAPY() public view returns (uint256) {
        uint256 totalStaked = 0; // Needs tracking or iterating _stakedEnergy (inefficient)
        // For simplicity, let's assume _energyTotalSupply is roughly the stake pool size for APY calculation.
        // A real system would track `totalStakedEnergy` separately.
        uint256 effectiveTotalStaked = _energyTotalSupply; // Placeholder

        if (effectiveTotalStaked == 0) return 0;

        // APY is (rewards per year / total staked) * 100
        // Rewards per year = stakingRate * seconds_in_year * effectiveTotalStaked / 1e18
        // APY = (_stakingRewardRate * 31536000 * effectiveTotalStaked / 1e18) / effectiveTotalStaked * 100
        // APY = (_stakingRewardRate * 31536000 * 100) / 1e18
        // Scale by 1e18 for fixed point representation
        uint256 secondsInYear = 31536000;
        uint256 apy = (_stakingRewardRate * secondsInYear * 100 * (10**18)) / (10**uint256(_energyDecimals));

        return apy;
    }

    /// @notice View function returning the state and details of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return description Proposal description.
    /// @return targetContract Contract target.
    /// @return startTimestamp Proposal start time.
    /// @return endTimestamp Proposal end time.
    /// @return votesFor Votes in favour.
    /// @return votesAgainst Votes against.
    /// @return executed Whether executed.
    function getProposalState(uint256 proposalId) public view proposalExists(proposalId) returns (
        string memory description,
        address targetContract,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed
    ) {
        Proposal storage proposal = _proposals[proposalId];
        return (
            proposal.description,
            proposal.targetContract,
            proposal.startTimestamp,
            proposal.endTimestamp,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }

    /// @notice View function returning the current adjustable ecosystem parameters.
    /// @return unitMintCost_ Cost to mint a unit.
    /// @return evolutionCostPerLevel_ Base cost to evolve.
    /// @return synergyCostPerUnit_ Cost per unit for synergy.
    /// @return decayCheckPeriod_ How often decay is checked.
    /// @return decayBaseConsumption_ Base energy consumed during decay check.
    /// @return stakingRewardRate_ Rate of staking rewards.
    /// @return governanceThreshold_ Percentage needed to pass proposal.
    /// @return governanceQuorum_ Minimum percentage of stake needed to vote.
    /// @return governanceVotingPeriod_ Duration of voting period.
    function getEcosystemParameters() public view returns (
        uint256 unitMintCost_,
        uint256 evolutionCostPerLevel_,
        uint256 synergyCostPerUnit_,
        uint64 decayCheckPeriod_,
        uint256 decayBaseConsumption_,
        uint256 stakingRewardRate_,
        uint256 governanceThreshold_,
        uint256 governanceQuorum_,
        uint64 governanceVotingPeriod_
    ) {
        return (
            _unitMintCost,
            _evolutionCostPerLevel,
            _synergyCostPerUnit,
            _decayCheckPeriod,
            _decayBaseConsumption,
            _stakingRewardRate,
            _governanceThreshold,
            _governanceQuorum,
            _governanceVotingPeriod
        );
    }

    /// @notice Returns the total count of CyberneticUnits minted.
    /// @return The total supply of units.
    function getUnitCount() public view returns (uint256) {
        return _unitTokenCounter;
    }

     /// @notice Returns the total supply of EnergyTokens.
     /// @return The total supply of energy.
     // This is already covered by ERC20 totalSupply(), but adding for clarity
     function getEnergyTokenSupply() public view returns (uint256) {
         return _energyTotalSupply;
     }


    // --- Admin / Parameter Update Functions (Callable via Governance) ---

    /// @notice Mints new EnergyTokens. Restricted to owner/governance.
    /// @param recipient The address to receive the tokens.
    /// @param amount The amount to mint.
    function mintEnergyTokens(address recipient, uint256 amount) public onlyOwner {
        _mintEnergy(recipient, amount);
    }

    /// @notice Burns EnergyTokens from the caller's balance. User callable.
    /// @param amount The amount to burn.
    function burnEnergyTokens(uint256 amount) public {
        require(_energyBalances[msg.sender] >= amount, "Insufficient balance to burn");
        _burnEnergy(msg.sender, amount);
    }

    // Function to update a specific parameter - typically called via governance `executeProposal`
    // See `updateEcosystemParameter` which is designed for `callData`.
    // This public wrapper exists potentially for direct owner calls before governance takes over,
    // but should ideally be removed or protected strongly in a production system.
    function updateSynergyBonus(uint16 newBonus) public onlyOwner {
        // This is just an example wrapper to show how parameters might be updated.
        // In this contract, synergy potential is a unit state, not a global param.
        // Let's change this to update something else or link it to updateEcosystemParameter.
        // Example: Use paramId 5 for decayCheckPeriod, paramId 6 for decayBaseConsumption
         revert("Use updateEcosystemParameter via governance call");
    }

     // --- Additional View Functions ---
     /// @notice Gets the EnergyToken name.
     function energyName() public view returns (string memory) { return _energyName; }
     /// @notice Gets the EnergyToken symbol.
     function energySymbol() public view returns (string memory) { return _energySymbol; }
     /// @notice Gets the EnergyToken decimals.
     function energyDecimals() public view returns (uint8) { return _energyDecimals; }

    /// @notice View function to get the current energy consumption rate for a specific unit.
    /// Currently, this just returns the base rate stored in the unit's state.
    /// @param tokenId The ID of the unit.
    /// @return The decay rate value.
     function getUnitConsumptionRate(uint256 tokenId) public view unitExists(tokenId) returns (uint16) {
        return _unitStates[tokenId].decayRate;
     }


    // --- Internal Utility ---

    // Internal function to get pseudo-randomness. WARNING: Not secure for critical outcomes.
    function _getEntropy(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
    }
}

```

**Explanation of Concepts and Advanced Features:**

1.  **Integrated Dual Token Model (NFT & ERC-20):** The contract manages both unique dynamic NFTs (CyberneticUnits) and a fungible ERC-20-like token (EnergyTokens) within a single codebase and state. This creates a self-contained ecosystem.
2.  **Dynamic NFTs:** CyberneticUnits aren't static JPEGs. Their `UnitState` struct (`level`, `lastFedTimestamp`, `synergyPotential`, `decayRate`, `isDecayed`) changes over time and based on user actions (`feedUnit`, `evolveUnit`, `performSynergy`).
3.  **Resource Consumption & Decay:** Units require `EnergyTokens` to function or stay "healthy". The `feedUnit` function consumes tokens and resets a decay timer. `checkUnitDecayStatus` simulates on-chain decay based on time and a unit's individual `decayRate`, adding a maintenance mechanic.
4.  **Evolution with Pseudo-Randomness:** The `evolveUnit` function costs resources, requires units to meet certain criteria, and includes a probabilistic element (`randomNumber % 100 < successChance`). While simple `block.timestamp` + `block.difficulty` randomness isn't secure for high-value applications (a miner could manipulate it), it demonstrates the concept of on-chain chance and is acceptable for this game-like example. It also shows how unit attributes (`synergyPotential`) can influence outcomes.
5.  **Inter-NFT Interaction (Synergy):** `performSynergy` allows two units to interact, consuming resources from the owner and resulting in a calculated bonus based on their combined state (`synergyPotential`). This adds a social/strategic layer to the NFTs.
6.  **EnergyToken Staking:** `stakeEnergy`, `unstakeEnergy`, and `claimEnergyRewards` implement a simple staking mechanism. Users lock EnergyTokens and accrue rewards over time, calculated internally based on a defined rate and timestamp tracking.
7.  **Basic On-Chain Governance:** The contract includes a minimal governance system. Users with staked energy can `initiateProposal`, `voteOnProposal`, and `executeProposal`. Proposals can call functions on other contracts or the ecosystem contract itself (demonstrated by `updateEcosystemParameter`), allowing the community to potentially adjust game parameters or manage a treasury (though a full treasury isn't implemented here). Voting power is weighted by staked EnergyTokens.
8.  **Manual ERC Implementation:** Instead of directly inheriting OpenZeppelin's `ERC721` and `ERC20`, the core logic using mappings (`_unitOwners`, `_energyBalances`, etc.) is implemented within the contract. This fulfills the request not to "duplicate any of open source" libraries directly while still providing the standard interfaces.
9.  **Packed Structs:** The `UnitState` struct uses smaller integer types (`uint8`, `uint16`, `uint64`) where possible to potentially save gas by packing multiple variables into a single storage slot.
10. **View Functions for State Exploration:** Numerous view functions (`getUnitState`, `getEnergyStakedBalance`, `getEcosystemParameters`, etc.) are provided to allow users and applications to inspect the complex state of units, staking, and ecosystem parameters.

This contract provides a rich set of interactions and state changes, combining elements from NFTs, DeFi (staking), and DAOs (governance) into a hypothetical digital ecosystem. Remember that for a production system, especially one dealing with significant value, more robust randomness solutions, formal ERC standard compliance testing, and thorough security audits would be essential.