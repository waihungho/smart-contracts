Okay, let's create a concept for a smart contract that represents a unique, dynamic digital asset (like virtual land or a futuristic artifact) that can be fractionalized, has evolving properties influenced by simulated "quantum" events, and is governed by its fractional owners.

We'll call this the `QuantumEstate` contract. It manages `EstateNFT`s (Non-Fungible Tokens representing the unique assets) and allows these NFTs to be broken down into fungible `EstateShares`, managed directly within the `QuantumEstate` contract per NFT.

**Concept:**

The `QuantumEstate` contract acts as a registry and management layer for unique digital assets (`EstateNFT`s). Each `EstateNFT` has dynamic properties that can change over time, influenced by a function simulating external, unpredictable "quantum fluctuations". The full owner of an `EstateNFT` can choose to *fractionalize* it, converting their full ownership into a large number of fungible shares specific to that NFT. These shares can be transferred. Fractional owners collectively govern the `EstateNFT` through proposals and votes weighted by their share balance. Yields can be attached to estates and claimed proportionally by fractional owners.

**Novel/Advanced Concepts:**

1.  **Internal, Per-NFT Fractionalization:** Fractional shares are managed *within* the main contract, mapped directly to the NFT ID, rather than deploying a separate ERC-20 for each fractionalized asset. This simplifies deployment overhead but makes the shares specific to this contract.
2.  **Dynamic State with Simulated External Influence:** Each NFT has properties that can change based on internal logic triggered by a function simulating external events ("quantum fluctuations"). This could be hooked up to an oracle for real-world data influence, or use pseudo-randomness based on block data.
3.  **Fractional Ownership Governance:** Fractional owners of a *specific* estate can propose and vote on changes or actions related *only* to that estate, creating micro-DAOs around each asset.
4.  **Yield Bearing:** Estates can accumulate yield (e.g., ETH or other tokens deposited) claimable by fractional owners.

---

**Contract: QuantumEstate**

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary OpenZeppelin libraries (`ERC721`, `Ownable`, `AccessControl`).
2.  **Structs:** Define data structures for Estate properties, governance proposals, and voting state.
3.  **Enums:** Define states for proposals.
4.  **Events:** Declare events for key actions (minting, fractionalizing, state change, voting, etc.).
5.  **State Variables:** Store contract owner, NFT counter, mappings for estate data, fractional share balances, governance info, yield balances, and access control roles.
6.  **Access Control:** Define roles (Owner, StateTriggerRole).
7.  **Constructor:** Initialize the ERC721 contract, set owner, and grant roles.
8.  **NFT Management Functions:** Minting, getting details, transferring full ownership (only when consolidated).
9.  **Fractionalization Functions:** Fractionalizing, consolidating, transferring shares, querying balances.
10. **Dynamic State Functions:** Triggering state updates, getting current state, setting parameters.
11. **Governance Functions:** Proposing votes, casting votes, executing proposals, querying proposal state, getting voting power.
12. **Yield Management Functions:** Depositing yield, claiming yield, querying yield balance.
13. **Configuration/Utility Functions:** Setting metadata, granting/revoking roles.
14. **Internal Helper Functions:** Logic for state updates, voting mechanics, access checks.

**Function Summary:**

1.  `constructor(address initialOwner)`: Initializes the contract, the ERC721 collection, and sets up roles.
2.  `mintEstate(address owner)`: Mints a new `EstateNFT` and assigns initial default properties. Requires `DEFAULT_ADMIN_ROLE`.
3.  `transferEstateOwnership(address from, address to, uint256 estateId)`: Transfers the full `EstateNFT`. Requires the estate to be fully consolidated (no shares outstanding). Uses ERC721 `_transfer`.
4.  `fractionalizeEstate(uint256 estateId, uint256 totalShares)`: Converts full ownership of an `EstateNFT` into a specified number of fractional shares. Only callable by the current owner, requires no shares exist for the estate.
5.  `consolidateEstate(uint256 estateId)`: Converts all outstanding shares of an `EstateNFT` back into full ownership, transferring the NFT to the caller if they hold all shares. Only callable if the caller holds 100% of shares.
6.  `transferEstateShares(uint256 estateId, address from, address to, uint256 amount)`: Transfers fractional shares for a specific estate between users. Requires approval or sender is `from`.
7.  `burnEstateShares(uint256 estateId, address account, uint256 amount)`: Burns fractional shares (e.g., for specific game mechanics or if needed). Requires `DEFAULT_ADMIN_ROLE`.
8.  `getEstateShareBalance(uint256 estateId, address account)`: Returns the fractional share balance for a user on a specific estate.
9.  `getTotalEstateShares(uint256 estateId)`: Returns the total number of fractional shares issued for an estate.
10. `getEstateOwner(uint256 estateId)`: Returns the current full owner of the `EstateNFT`. If fractionalized, returns address(0).
11. `getEstateProperties(uint256 estateId)`: Returns the current dynamic properties of an estate.
12. `triggerQuantumFluctuation(uint256 estateId)`: Triggers an update to the dynamic properties of an estate based on internal simulation logic. Requires `STATE_TRIGGER_ROLE`.
13. `setEstateStateParameters(uint256 estateId, uint256 param1, uint256 param2, uint256 param3)`: Sets parameters influencing how the quantum state evolves for a specific estate. Requires `DEFAULT_ADMIN_ROLE`.
14. `getEstateStateParameters(uint256 estateId)`: Retrieves the state evolution parameters for an estate.
15. `proposeEstateGovernanceVote(uint256 estateId, string memory description, bytes memory proposalData, uint64 durationBlocks)`: Allows a fractional owner to propose a governance vote on a specific estate. Requires a minimum share balance.
16. `voteOnEstateProposal(uint256 estateId, uint256 proposalId, bool support)`: Casts a vote on an active governance proposal for an estate. Voting power is based on shares held at the time of voting.
17. `executeEstateProposal(uint256 estateId, uint256 proposalId)`: Executes a proposal that has met the voting requirements (quorum and majority).
18. `getEstateProposalState(uint256 estateId, uint256 proposalId)`: Returns the current state of a governance proposal.
19. `getEstateVotingPower(uint256 estateId, address account)`: Returns the current voting power (shares) for a user on a specific estate.
20. `depositEstateYield(uint256 estateId) payable`: Allows depositing native currency (ETH) as yield for a specific estate. Callable by anyone.
21. `claimEstateYield(uint256 estateId)`: Allows a fractional owner to claim their proportional share of the accumulated yield for an estate.
22. `getEstateYieldBalance(uint256 estateId)`: Returns the total native currency yield balance for an estate.
23. `setEstateMetadata(uint256 estateId, string memory name, string memory description, string memory tokenURI)`: Sets descriptive metadata and token URI for an estate. Requires owner or admin.
24. `grantStateTriggerRole(address account)`: Grants the `STATE_TRIGGER_ROLE`. Requires `DEFAULT_ADMIN_ROLE`.
25. `revokeStateTriggerRole(address account)`: Revokes the `STATE_TRIGGER_ROLE`. Requires `DEFAULT_ADMIN_ROLE`.
26. `isStateTrigger(address account)`: Checks if an address has the `STATE_TRIGGER_ROLE`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ handles overflow, good practice with complex math
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // For interacting with external tokens if needed for yield (using ETH for simplicity here)

// --- Contract: QuantumEstate ---
//
// Outline:
// 1. Pragma and Imports
// 2. Structs and Enums
// 3. Events
// 4. State Variables (Mappings, Counters, Roles)
// 5. Access Control Roles Definition
// 6. Constructor
// 7. NFT Management Functions (Mint, Transfer, Get Details)
// 8. Fractionalization Functions (Fractionalize, Consolidate, Transfer Shares, Balances)
// 9. Dynamic State & Simulation Functions (Trigger Update, Get State, Set Params)
// 10. Governance Functions (Propose, Vote, Execute, Get State, Get Voting Power)
// 11. Yield Management Functions (Deposit, Claim, Get Balance)
// 12. Configuration & Utility Functions (Metadata, Roles)
// 13. Internal Helper Functions
//
// Function Summary:
// constructor(address initialOwner): Initializes ERC721, sets admin, defines roles.
// mintEstate(address owner): Mints a new Estate NFT with initial properties.
// transferEstateOwnership(address from, address to, uint256 estateId): Transfers full NFT ownership (requires consolidation).
// fractionalizeEstate(uint256 estateId, uint256 totalShares): Converts full NFT to shares.
// consolidateEstate(uint256 estateId): Converts shares back to full NFT ownership.
// transferEstateShares(uint256 estateId, address from, address to, uint256 amount): Transfers internal fractional shares.
// burnEstateShares(uint256 estateId, address account, uint256 amount): Burns internal fractional shares (admin function).
// getEstateShareBalance(uint256 estateId, address account): Gets share balance for an account on an estate.
// getTotalEstateShares(uint256 estateId): Gets total shares issued for an estate.
// getEstateOwner(uint256 estateId): Gets the current full NFT owner (returns address(0) if fractionalized).
// getEstateProperties(uint256 estateId): Gets the dynamic properties of an estate.
// triggerQuantumFluctuation(uint256 estateId): Triggers a state update based on simulation.
// setEstateStateParameters(uint256 estateId, uint256 param1, uint256 param2, uint256 param3): Sets parameters affecting state evolution.
// getEstateStateParameters(uint256 estateId): Gets state evolution parameters.
// proposeEstateGovernanceVote(uint256 estateId, string memory description, bytes memory proposalData, uint64 durationBlocks): Creates a governance proposal.
// voteOnEstateProposal(uint256 estateId, uint256 proposalId, bool support): Casts a vote on a proposal.
// executeEstateProposal(uint256 estateId, uint256 proposalId): Executes a proposal if it passes.
// getEstateProposalState(uint256 estateId, uint256 proposalId): Gets the state of a proposal.
// getEstateVotingPower(uint256 estateId, address account): Gets share balance for voting power calculation.
// depositEstateYield(uint256 estateId) payable: Deposits native currency yield for an estate.
// claimEstateYield(uint256 estateId): Allows fractional owners to claim yield.
// getEstateYieldBalance(uint256 estateId): Gets total yield balance for an estate.
// setEstateMetadata(uint256 estateId, string memory name, string memory description, string memory tokenURI): Sets metadata.
// grantStateTriggerRole(address account): Grants role to trigger state updates.
// revokeStateTriggerRole(address account): Revokes state trigger role.
// isStateTrigger(address account): Checks if account has state trigger role.

contract QuantumEstate is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20; // In case we add external token yield later

    // --- 4. State Variables ---
    bytes32 public constant STATE_TRIGGER_ROLE = keccak256("STATE_TRIGGER_ROLE");

    Counters.Counter private _estateIds;

    // Struct to hold dynamic properties of an estate
    struct EstateProperties {
        uint256 fertility; // Example property 1 (e.g., affects yield)
        uint256 energyLevel; // Example property 2 (e.g., affects interaction cost)
        uint256 mutationProbability; // Example property 3 (e.g., chance of random change)
        uint64 lastFluctuationBlock; // Block number of the last state update
    }

    // Struct to hold parameters influencing state evolution
    struct EstateStateParameters {
        uint256 fertilityBase;
        uint256 energyBase;
        uint256 mutationBase;
        uint256 fluctuationMagnitude; // How much properties can change
    }

    // Mapping from estateId to its dynamic properties
    mapping(uint256 => EstateProperties) private _estateProperties;
    // Mapping from estateId to its state evolution parameters
    mapping(uint256 => EstateStateParameters) private _estateStateParameters;

    // Mapping from estateId to user address to their fractional share balance
    mapping(uint256 => mapping(address => uint256)) private _estateShares;
    // Mapping from estateId to the total number of fractional shares issued
    mapping(uint256 => uint256) private _totalEstateShares;

    // Struct for governance proposals
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct EstateProposal {
        uint256 estateId;
        uint256 id;
        string description;
        bytes proposalData; // Data payload for execution
        uint64 startBlock;
        uint64 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Track voters
        ProposalState state;
    }

    // Mapping from estateId to proposalId to proposal data
    mapping(uint256 => mapping(uint256 => EstateProposal)) private _estateProposals;
    // Mapping from estateId to the counter for proposals
    mapping(uint256 => uint256) private _estateProposalCounters;
    // Mapping from estateId to governance parameters (e.g., voting period, quorum, min proposal shares)
    mapping(uint256 => EstateGovernanceParams) private _estateGovernanceParams;

    struct EstateGovernanceParams {
        uint64 votingPeriodBlocks; // How long voting lasts
        uint256 quorumPercentage; // Percentage of total shares needed to vote
        uint256 minProposalShares; // Minimum shares required to create a proposal
    }

    // Mapping from estateId to accumulated native currency yield
    mapping(uint256 => uint256) private _estateYieldBalance;

    // Mapping for metadata (can be off-chain, but storing pointers/simple data on-chain)
    mapping(uint256 => string) private _estateNames;
    mapping(uint256 => string) private _estateDescriptions;


    // --- 3. Events ---
    event EstateMinted(uint256 indexed estateId, address indexed owner, EstateProperties initialProperties);
    event EstateFractionalized(uint256 indexed estateId, address indexed owner, uint256 totalShares);
    event EstateConsolidated(uint256 indexed estateId, address indexed newOwner);
    event EstateSharesTransfer(uint256 indexed estateId, address indexed from, address indexed to, uint256 amount);
    event EstateStateUpdated(uint256 indexed estateId, EstateProperties newProperties, uint64 blockNumber);
    event EstateProposalCreated(uint256 indexed estateId, uint256 indexed proposalId, string description, uint64 endBlock);
    event EstateVoted(uint256 indexed estateId, uint256 indexed proposalId, address indexed voter, uint256 votingPower, bool support);
    event EstateProposalStateChanged(uint256 indexed estateId, uint256 indexed proposalId, ProposalState newState);
    event EstateYieldDeposited(uint256 indexed estateId, address indexed depositor, uint256 amount);
    event EstateYieldClaimed(uint256 indexed estateId, address indexed claimant, uint256 amount);
    event EstateMetadataUpdated(uint256 indexed estateId, string name, string description, string tokenURI);


    // --- 6. Constructor ---
    constructor(address initialOwner) ERC721("QuantumEstateNFT", "QEN") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        // Grant the initial owner the STATE_TRIGGER_ROLE as well, or have a separate admin assign it
        _grantRole(STATE_TRIGGER_ROLE, initialOwner);
    }

    // --- 5. Access Control Roles Definition ---
    // DEFAULT_ADMIN_ROLE and STATE_TRIGGER_ROLE defined above

    // Overrides for AccessControl
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- 7. NFT Management Functions ---
    function mintEstate(address owner) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        _estateIds.increment();
        uint256 newItemId = _estateIds.current();
        _safeMint(owner, newItemId);

        // Initialize default properties and parameters
        EstateProperties memory initialProps = EstateProperties({
            fertility: 50, // Default values
            energyLevel: 100,
            mutationProbability: 10,
            lastFluctuationBlock: block.number
        });
        _estateProperties[newItemId] = initialProps;

        EstateStateParameters memory defaultParams = EstateStateParameters({
            fertilityBase: 50,
            energyBase: 100,
            mutationBase: 10,
            fluctuationMagnitude: 20 // Default max change percentage
        });
         _estateStateParameters[newItemId] = defaultParams;

        // Initialize default governance parameters
        EstateGovernanceParams memory defaultGovParams = EstateGovernanceParams({
             votingPeriodBlocks: 100, // Example: ~20 mins on Ethereum mainnet (13s/block)
             quorumPercentage: 10,    // Example: 10% of shares must vote
             minProposalShares: 1     // Example: Anyone with at least 1 share can propose
        });
        _estateGovernanceParams[newItemId] = defaultGovParams;


        emit EstateMinted(newItemId, owner, initialProps);
        return newItemId;
    }

    // Standard ERC721 transfer function - only works if not fractionalized
    function transferFrom(address from, address to, uint256 estateId) public override {
        require(_totalEstateShares[estateId] == 0, "Estate is fractionalized");
        super.transferFrom(from, to, estateId);
    }

    // Standard ERC721 safe transfer - only works if not fractionalized
    function safeTransferFrom(address from, address to, uint256 estateId) public override {
         require(_totalEstateShares[estateId] == 0, "Estate is fractionalized");
        super.safeTransferFrom(from, to, estateId);
    }

     // Standard ERC721 safe transfer with data - only works if not fractionalized
    function safeTransferFrom(address from, address to, uint256 estateId, bytes memory data) public override {
         require(_totalEstateShares[estateId] == 0, "Estate is fractionalized");
        super.safeTransferFrom(from, to, estateId, data);
    }

     // Override to check if fractionalized
    function ownerOf(uint256 estateId) public view override returns (address) {
         if (_totalEstateShares[estateId] > 0) {
             // If fractionalized, there's no single owner from ERC721 perspective
             return address(0); // Indicates fractionalized state
         }
        return super.ownerOf(estateId);
    }

    function getEstateDetails(uint256 estateId) public view returns (address currentOwner, uint256 totalShares, EstateProperties memory properties, EstateGovernanceParams memory govParams) {
        currentOwner = ownerOf(estateId); // Will be address(0) if fractionalized
        totalShares = _totalEstateShares[estateId];
        properties = _estateProperties[estateId];
        govParams = _estateGovernanceParams[estateId];
        // Note: This doesn't return metadata or yield
        return (currentOwner, totalShares, properties, govParams);
    }


    // --- 8. Fractionalization Functions ---

    function fractionalizeEstate(uint256 estateId, uint256 totalSharesToMint) public {
        address currentOwner = ownerOf(estateId);
        require(currentOwner == msg.sender, "Caller is not the full owner");
        require(_totalEstateShares[estateId] == 0, "Estate is already fractionalized");
        require(totalSharesToMint > 0, "Must mint more than 0 shares");

        // Burn the NFT from the owner
        _burn(estateId);

        // Mint shares to the owner
        _estateShares[estateId][msg.sender] = totalSharesToMint;
        _totalEstateShares[estateId] = totalSharesToMint;

        emit EstateFractionalized(estateId, msg.sender, totalSharesToMint);
    }

    function consolidateEstate(uint256 estateId) public {
        require(_totalEstateShares[estateId] > 0, "Estate is not fractionalized");
        require(_estateShares[estateId][msg.sender] == _totalEstateShares[estateId], "Caller does not own all shares");

        // Burn all shares
        delete _estateShares[estateId]; // Clears all balances for this estateId
        _totalEstateShares[estateId] = 0;

        // Mint the NFT back to the caller
        _safeMint(msg.sender, estateId);

        emit EstateConsolidated(estateId, msg.sender);
    }

    function transferEstateShares(uint256 estateId, address to, uint256 amount) public {
        require(_totalEstateShares[estateId] > 0, "Estate is not fractionalized");
        require(to != address(0), "Transfer to the zero address");
        require(_estateShares[estateId][msg.sender] >= amount, "Insufficient shares");

        _estateShares[estateId][msg.sender] = _estateShares[estateId][msg.sender].sub(amount);
        _estateShares[estateId][to] = _estateShares[estateId][to].add(amount);

        emit EstateSharesTransfer(estateId, msg.sender, to, amount);
    }

     function burnEstateShares(uint256 estateId, address account, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_totalEstateShares[estateId] > 0, "Estate is not fractionalized");
        require(_estateShares[estateId][account] >= amount, "Insufficient shares for burning");
        require(_totalEstateShares[estateId] >= amount, "Total shares less than amount to burn");

        _estateShares[estateId][account] = _estateShares[estateId][account].sub(amount);
        _totalEstateShares[estateId] = _totalEstateShares[estateId].sub(amount);

        // Note: This is an unusual function for fractional ownership and should be used with caution.
        // It reduces the total supply of shares for an estate.
    }

    function getEstateShareBalance(uint256 estateId, address account) public view returns (uint256) {
        return _estateShares[estateId][account];
    }

    function getTotalEstateShares(uint256 estateId) public view returns (uint256) {
        return _totalEstateShares[estateId];
    }

    function getEstateOwner(uint256 estateId) public view returns (address) {
        return ownerOf(estateId); // Uses the overridden function
    }


    // --- 9. Dynamic State & Simulation Functions ---

    // Internal function to update state - can be called by triggerQuantumFluctuation
    function _updateEstateState(uint256 estateId) internal {
        EstateProperties storage props = _estateProperties[estateId];
        EstateStateParameters memory params = _estateStateParameters[estateId];

        // Simple simulation logic based on block data and parameters
        // NOTE: In a real-world scenario, this would need a secure oracle for true randomness/external input.
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, estateId)));

        uint256 fertilityChange = (pseudoRandom % (params.fluctuationMagnitude * 2 + 1)) - params.fluctuationMagnitude; // Change between -magnitude and +magnitude
        uint256 energyChange = (pseudoRandom * 2 % (params.fluctuationMagnitude * 2 + 1)) - params.fluctuationMagnitude;
        uint256 mutationChange = (pseudoRandom * 3 % (params.fluctuationMagnitude + 1)) - (params.fluctuationMagnitude / 2); // Smaller range for mutation

        // Apply changes, ensuring properties stay non-negative
        props.fertility = (props.fertility + fertilityChange > 0) ? props.fertility + fertilityChange : 0;
        props.energyLevel = (props.energyLevel + energyChange > 0) ? props.energyLevel + energyChange : 0;
        props.mutationProbability = (props.mutationProbability + mutationChange > 0) ? props.mutationProbability + mutationChange : 0;

        // Clamp properties within reasonable bounds (optional, but good practice)
        props.fertility = props.fertility > 100 ? 100 : props.fertility;
        props.energyLevel = props.energyLevel > 200 ? 200 : props.energyLevel;
        props.mutationProbability = props.mutationProbability > 50 ? 50 : props.mutationProbability;


        props.lastFluctuationBlock = block.number;

        emit EstateStateUpdated(estateId, props, block.number);
    }

    // Callable function to trigger a state update for a specific estate
    function triggerQuantumFluctuation(uint256 estateId) public onlyRole(STATE_TRIGGER_ROLE) {
         require(exists(estateId), "Estate does not exist"); // Use ERC721 exists check
        _updateEstateState(estateId);
    }

    // Set parameters that influence the range and type of state changes
    function setEstateStateParameters(uint256 estateId, uint256 fertilityBase, uint256 energyBase, uint256 mutationBase, uint256 fluctuationMagnitude) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(exists(estateId), "Estate does not exist");
        _estateStateParameters[estateId] = EstateStateParameters({
            fertilityBase: fertilityBase,
            energyBase: energyBase,
            mutationBase: mutationBase,
            fluctuationMagnitude: fluctuationMagnitude
        });
    }

    function getEstateStateParameters(uint256 estateId) public view returns (EstateStateParameters memory) {
        require(exists(estateId), "Estate does not exist");
        return _estateStateParameters[estateId];
    }

    function getEstateQuantumState(uint256 estateId) public view returns (EstateProperties memory) {
         require(exists(estateId), "Estate does not exist");
        return _estateProperties[estateId];
    }


    // --- 10. Governance Functions ---

    function proposeEstateGovernanceVote(uint256 estateId, string memory description, bytes memory proposalData, uint64 durationBlocks) public {
        require(exists(estateId), "Estate does not exist");
        require(_totalEstateShares[estateId] > 0, "Estate is not fractionalized for governance");
        require(durationBlocks > 0, "Duration must be greater than 0");
        EstateGovernanceParams memory govParams = _estateGovernanceParams[estateId];
        require(_estateShares[estateId][msg.sender] >= govParams.minProposalShares, "Insufficient shares to propose");

        _estateProposalCounters[estateId]++;
        uint256 proposalId = _estateProposalCounters[estateId];

        EstateProposal storage proposal = _estateProposals[estateId][proposalId];
        proposal.estateId = estateId;
        proposal.id = proposalId;
        proposal.description = description;
        proposal.proposalData = proposalData; // This data can encode the action to be taken
        proposal.startBlock = block.number;
        proposal.endBlock = block.number + durationBlocks;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.state = ProposalState.Active;
        // hasVoted mapping is part of the struct storage

        emit EstateProposalCreated(estateId, proposalId, description, proposal.endBlock);
    }

    function voteOnEstateProposal(uint256 estateId, uint256 proposalId, bool support) public {
        require(exists(estateId), "Estate does not exist");
        EstateProposal storage proposal = _estateProposals[estateId][proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.number <= proposal.endBlock, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 votingPower = _estateShares[estateId][msg.sender];
        require(votingPower > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }

        emit EstateVoted(estateId, proposalId, msg.sender, votingPower, support);
    }

     function executeEstateProposal(uint256 estateId, uint256 proposalId) public {
        require(exists(estateId), "Estate does not exist");
        EstateProposal storage proposal = _estateProposals[estateId][proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not in Active state");
        require(block.number > proposal.endBlock, "Voting period has not ended");

        EstateGovernanceParams memory govParams = _estateGovernanceParams[estateId];
        uint256 totalShares = _totalEstateShares[estateId]; // Shares at the time of execution matters for quorum

        // Calculate total votes cast
        uint256 totalVotesCast = proposal.votesFor.add(proposal.votesAgainst);

        // Check quorum: total votes cast must be >= quorum percentage of total shares
        bool quorumMet = totalVotesCast.mul(100) >= totalShares.mul(govParams.quorumPercentage);

        // Check majority: votesFor must be strictly greater than votesAgainst
        bool majorityMet = proposal.votesFor > proposal.votesAgainst;

        if (quorumMet && majorityMet) {
            proposal.state = ProposalState.Succeeded;
            emit EstateProposalStateChanged(estateId, proposalId, ProposalState.Succeeded);

            // --- Execute the proposal's action ---
            // The `proposalData` bytes need to be decoded and acted upon.
            // This is a complex part and depends on the types of actions governance can take.
            // For demonstration, let's imagine it calls a specific internal function based on the data.
            // In a real DAO, you might decode function signatures and parameters.
            // Example: data could encode `abi.encodeWithSignature("setEstateMetadata(uint256,string,string,string)", estateId, "NewName", "NewDesc", "new/uri")`
            // A simple way here is to have a predefined set of executable actions tied to `proposalData`.
            // For now, we'll just mark it as executed without implementing a complex execution engine.
            // A realistic implementation would need a robust `_execute(bytes memory data)` function.
            // require(_execute(proposal.proposalData), "Proposal execution failed"); // Placeholder

            proposal.state = ProposalState.Executed; // Assuming execution succeeds for demo
            emit EstateProposalStateChanged(estateId, proposalId, ProposalState.Executed);

        } else {
            proposal.state = ProposalState.Failed;
             emit EstateProposalStateChanged(estateId, proposalId, ProposalState.Failed);
        }
    }

    function getEstateProposalState(uint256 estateId, uint256 proposalId) public view returns (ProposalState) {
        require(exists(estateId), "Estate does not exist");
        require(proposalId > 0 && proposalId <= _estateProposalCounters[estateId], "Invalid proposal ID");
        return _estateProposals[estateId][proposalId].state;
    }

     function getEstateVotingPower(uint256 estateId, address account) public view returns (uint256) {
         require(exists(estateId), "Estate does not exist");
         // Voting power is simply the current share balance
        return _estateShares[estateId][account];
     }

     function getEstateGovernanceParams(uint256 estateId) public view returns (EstateGovernanceParams memory) {
          require(exists(estateId), "Estate does not exist");
         return _estateGovernanceParams[estateId];
     }

    function setEstateGovernanceParams(uint256 estateId, uint64 votingPeriodBlocks, uint256 quorumPercentage, uint256 minProposalShares) public onlyRole(DEFAULT_ADMIN_ROLE) {
         require(exists(estateId), "Estate does not exist");
         require(quorumPercentage <= 100, "Quorum percentage cannot exceed 100");
         _estateGovernanceParams[estateId] = EstateGovernanceParams({
              votingPeriodBlocks: votingPeriodBlocks,
              quorumPercentage: quorumPercentage,
              minProposalShares: minProposalShares
         });
    }


    // --- 11. Yield Management Functions ---

    function depositEstateYield(uint256 estateId) public payable {
        require(exists(estateId), "Estate does not exist");
        require(msg.value > 0, "Must send positive amount");

        _estateYieldBalance[estateId] = _estateYieldBalance[estateId].add(msg.value);

        emit EstateYieldDeposited(estateId, msg.sender, msg.value);
    }

    function claimEstateYield(uint256 estateId) public {
        require(exists(estateId), "Estate does not exist");
        uint256 totalYield = _estateYieldBalance[estateId];
        require(totalYield > 0, "No yield available for this estate");

        uint256 totalShares = _totalEstateShares[estateId];
         // If not fractionalized, only the owner can claim
        if (totalShares == 0) {
            require(ownerOf(estateId) == msg.sender, "Not the owner or fractional owner");
             uint256 amountToClaim = totalYield;
            _estateYieldBalance[estateId] = 0; // Claiming all yield

            (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
            require(success, "ETH transfer failed");
            emit EstateYieldClaimed(estateId, msg.sender, amountToClaim);

        } else {
            // Calculate proportional share for fractional owner
            uint256 claimantShares = _estateShares[estateId][msg.sender];
            require(claimantShares > 0, "Caller has no shares in this estate");

            // Avoid division by zero if something went wrong with totalShares
             require(totalShares > 0, "Total shares is zero, cannot claim yield");

            uint256 amountToClaim = totalYield.mul(claimantShares).div(totalShares);

            // Deduct claimed amount from the estate's balance
            _estateYieldBalance[estateId] = _estateYieldBalance[estateId].sub(amountToClaim);

            (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
            require(success, "ETH transfer failed");

            emit EstateYieldClaimed(estateId, msg.sender, amountToClaim);
        }
    }

    function getEstateYieldBalance(uint256 estateId) public view returns (uint256) {
        require(exists(estateId), "Estate does not exist");
        return _estateYieldBalance[estateId];
    }


    // --- 12. Configuration & Utility Functions ---

     function setEstateMetadata(uint256 estateId, string memory name, string memory description, string memory tokenURI) public {
        require(exists(estateId), "Estate does not exist");
        // Either the full owner or the admin can set metadata
        require(ownerOf(estateId) == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized to set metadata");

        _estateNames[estateId] = name;
        _estateDescriptions[estateId] = description;
        // Note: ERC721 `tokenURI` function is virtual, you'd override it if storing URIs per token
        // For this example, we store name/description separately but include tokenURI in event
        emit EstateMetadataUpdated(estateId, name, description, tokenURI);
     }

    function grantStateTriggerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(STATE_TRIGGER_ROLE, account);
    }

    function revokeStateTriggerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(STATE_TRIGGER_ROLE, account);
    }

     function isStateTrigger(address account) public view returns (bool) {
         return hasRole(STATE_TRIGGER_ROLE, account);
     }

    // --- 13. Internal Helper Functions ---
    // (Most logic is inline or uses OpenZeppelin helpers)
     function exists(uint256 estateId) internal view returns (bool) {
         // Check if the token ID has been minted. ERC721's _exists is internal
         // A simple check is against the counter, assuming sequential minting starting from 1.
         return estateId > 0 && estateId <= _estateIds.current();
     }

    // The ERC721 tokenURI function can be overridden here if needed
    // function tokenURI(uint256 tokenId) public view override returns (string memory) { ... }

    // Placeholder for proposal execution logic (complex in a real DAO)
    // function _execute(bytes memory data) internal returns (bool) { ... }
}
```