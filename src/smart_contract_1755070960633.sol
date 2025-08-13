The `AetherCanvas` contract is designed as a decentralized platform for collaborative, evolving digital art. It merges concepts of on-chain generative art, dynamic parameters, community governance, NFT ownership, and fractionalization. The core idea is that users collectively influence evolving art parameters, which represent the "DNA" of a live, dynamic artwork. Periodically, "snapshots" of this evolving art can be minted as unique NFTs through a decentralized voting process, and these NFTs can then be fractionally owned by multiple users. The contract aims to be distinct by providing a unique system of parameter influence, art evolution, and integrated fractionalization without directly copying existing open-source implementations for core features.

---

## Contract: `AetherCanvas`

**License:** MIT
**Solidity Version:** `^0.8.20`

---

### Outline

1.  **Enums and Structs**:
    *   `ArtParameter`: Defines the type and current value of an evolving art parameter.
    *   `SnapshotProposal`: Details for proposing an NFT snapshot of the current art state.
    *   `GeneralProposal`: Generic structure for all other governance proposals (parameter changes, algorithm upgrades).
    *   `ProposalType`: Enum to distinguish between different types of governance proposals.
    *   `ProposalState`: Enum to track the lifecycle of a proposal (Pending, Active, Succeeded, Failed, Executed).
    *   `SharesInfo`: Information about fractional shares for a minted NFT.

2.  **State Variables**:
    *   **Core Contract**: `owner`, `paused`.
    *   **Art Parameters**: `artParameters` (mapping of parameter index to `ArtParameter` struct), `artParameterInfluences` (mapping of parameter index to accumulated influence).
    *   **Evolution Engine**: `lastEvolutionCycleTime`, `evolutionCycleDuration`, `influenceDecayRate`.
    *   **NFT Management (ERC-721-like)**: `_tokenOwners`, `_tokenApprovals`, `_operatorApprovals`, `_tokenIdCounter`, `_tokenURIs`, `_nftTotalSupply`.
    *   **Fractionalization (Custom ERC-20-like)**: `_nftShares`, `_nftShareBalances`, `_nftShareAllowances`, `_totalSharesIssued`.
    *   **Governance**: `snapshotProposals`, `generalProposals`, `_proposalIdCounter`, `minVotesForProposal`, `proposalVotingPeriod`.
    *   **Treasury**: `influenceCost` (cost to influence a parameter), `treasury` (tracks contract's ETH balance).
    *   **Art Algorithm**: `artAlgorithmReference` (address of an external contract interpreting art parameters for rendering).

3.  **Events**:
    *   `OwnershipTransferred`: On contract ownership change.
    *   `Paused`, `Unpaused`: On contract pause/unpause.
    *   `ParameterInfluenced`: When a user influences an art parameter.
    *   `ArtEvolved`: When the art state advances.
    *   `ArtAlgorithmReferenceSet`: When the art algorithm contract is updated.
    *   `SnapshotProposed`: When a new NFT snapshot proposal is created.
    *   `VoteCast`: When a vote is cast on any proposal.
    *   `SnapshotMinted`: When an NFT is successfully minted from a snapshot.
    *   `NFTFractionalized`: When an NFT is broken into shares.
    *   `SharesTransferred`, `SharesApproved`: For custom fractional share transfers/approvals.
    *   `ParameterChangeProposed`, `AlgorithmUpgradeProposed`: When a governance proposal is made.
    *   `ProposalExecuted`: When a governance proposal is successfully executed.
    *   `TreasuryWithdrawal`: When funds are withdrawn from the treasury.

4.  **Custom Modifiers**:
    *   `onlyOwner()`: Restricts function calls to the contract owner.
    *   `whenNotPaused()`: Ensures the contract is not paused.
    *   `whenPaused()`: Ensures the contract is paused.
    *   `isValidProposal(uint256 _proposalId, ProposalType _type)`: Checks if a proposal exists and is of the correct type.

5.  **Constructor**:
    *   Initializes the contract owner, sets initial art parameters, and configures evolution/governance timings.

6.  **Core Art Generation & Evolution Functions**: (9 functions)
    *   Manages the dynamic art parameters, allows user influence, and implements the art's evolution logic over time.

7.  **NFT Minting & Fractionalization Functions**: (5 functions)
    *   Handles the creation of snapshot proposals, community voting for minting, and the fractionalization of minted NFTs into tradable shares. Includes manual ERC-721 interfaces for minted NFTs and custom ERC-20-like interfaces for shares.

8.  **Governance & Treasury Functions**: (6 functions)
    *   Enables decentralized decision-making through proposals and voting for critical changes like parameter adjustments or algorithm upgrades, and manages the contract's treasury.

9.  **Utility & Admin Functions**: (13 functions)
    *   Provides basic administrative controls (pause/unpause, ownership transfer) and manually implements essential ERC-721 (for `AetherCanvas` NFTs) and custom ERC-20 (for fractional shares) interfaces to avoid direct open-source library duplication.

---

### Function Summary

**I. Core Art Generation & Evolution:**

1.  `getCurrentArtStateHash() external view returns (bytes32)`: Generates a unique, deterministic hash representing the current state of all art parameters. This hash can serve as an on-chain identifier for the live art's appearance.
2.  `getArtParameters() external view returns (bytes32[] memory, uint256[] memory, uint256[] memory)`: Returns the current values of all evolving art parameters, their accumulated influence, and their base influence.
3.  `influenceParameter(uint256 _paramIndex) external payable`: Allows a user to contribute `influenceCost` ETH to increase the accumulated influence for a specific art parameter, nudging the art's evolution in a desired direction.
4.  `triggerEvolutionCycle() external`: Advances the art's state based on accumulated influences and time. This function applies the net influence to parameters, decays old influences, and can introduce time-based changes, simulating a dynamic, evolving system.
5.  `getEvolutionCycleInfo() external view returns (uint256, uint256, uint256)`: Provides details about the current evolution cycle: the last time an evolution occurred, the duration of each cycle, and the current progress.
6.  `setArtAlgorithmReference(address _newAlgContract) external onlyOwner`: Allows the contract owner (or eventually DAO) to set the address of an external contract that defines how the on-chain art parameters are interpreted and rendered into visual art.
7.  `requestOracleFeedUpdate(bytes32 _feedKey) external pure`: (Conceptual/Placeholder) Simulates a request to an external oracle for data. In a real scenario, this would integrate with an oracle network (e.g., Chainlink) to fetch external data (like weather, market prices) that could influence art parameters.
8.  `getLiveArtSVGFragment(uint256 _paramIndex) external view returns (string memory)`: Returns a conceptual string fragment representing a part of the live art's SVG based on a single parameter. This is for off-chain rendering, indicating what visual component a parameter controls.
9.  `getLiveArtRenderParameters() external view returns (bytes32[] memory)`: Returns all current art parameter values in a format suitable for an external rendering engine to generate the complete visual artwork.

**II. NFT Minting & Fractionalization:**

10. `proposeArtSnapshot() external`: Initiates a governance proposal to mint the current, live state of the evolving art as a permanent, unique NFT. Requires the art to have evolved sufficiently.
11. `voteForSnapshotProposal(uint256 _proposalId, bool _support) external`: Allows users to cast their vote (for or against) on a specific snapshot proposal. Voting power could be tied to past influence contributions or locked tokens.
12. `mintSnapshotNFT(uint256 _proposalId) external`: Executes the minting of an NFT if the corresponding snapshot proposal has passed its voting period and met the approval threshold. Resets influence counters for the next evolution cycle.
13. `fractionalizeNFT(uint256 _tokenId, uint256 _shares) external`: Allows the owner of a minted NFT to break it down into a specified number of fungible "shares," which can then be traded, enabling collective ownership.
14. `getNFTSharesInfo(uint256 _tokenId) external view returns (bool, uint256, uint256)`: Retrieves information about a specific NFT's fractionalization status, including whether it's fractionalized, the total shares issued, and the number of shares currently held by the contract.

**III. Governance & Treasury:**

15. `submitParameterChangeProposal(uint256 _paramIndex, uint256 _newValue) external`: Allows any user to submit a governance proposal to directly change a specific art parameter to a new target value, subject to community vote.
16. `submitAlgorithmUpgradeProposal(address _newAlgContract) external`: Allows any user to propose upgrading the `artAlgorithmReference` contract, which defines how art parameters are interpreted and rendered.
17. `voteOnGeneralProposal(uint256 _proposalId, bool _support) external`: Allows users to cast their vote on general governance proposals (parameter changes, algorithm upgrades).
18. `executeProposal(uint256 _proposalId) external`: Executes a governance proposal (snapshot, parameter change, algorithm upgrade) if it has passed its voting period and met the necessary approval criteria.
19. `getProposalInfo(uint256 _proposalId) external view returns (GeneralProposal calldata)`: Retrieves detailed information about a specific general governance proposal, including its state, votes, and target.
20. `withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner`: Allows the contract owner (or later, DAO) to withdraw accumulated funds from the contract's treasury, which are collected from `influenceParameter` calls.

**IV. Utility & ERC-721/ERC-20 Compliance (Manual Implementation):**

21. `pause() external onlyOwner whenNotPaused`: Puts the contract into a paused state, preventing most state-changing operations.
22. `unpause() external onlyOwner whenPaused`: Resumes contract operations from a paused state.
23. `transferContractOwnership(address _newOwner) external onlyOwner`: Transfers administrative ownership of the contract to a new address.
24. `balanceOf(address _owner) external view returns (uint256)`: (ERC-721-like) Returns the number of NFTs owned by a given address.
25. `ownerOf(uint256 _tokenId) external view returns (address)`: (ERC-721-like) Returns the address of the owner of a specific NFT.
26. `approve(address _to, uint256 _tokenId) external`: (ERC-721-like) Approves an address to transfer a specific NFT.
27. `getApproved(uint256 _tokenId) external view returns (address)`: (ERC-721-like) Returns the approved address for a specific NFT.
28. `setApprovalForAll(address _operator, bool _approved) external`: (ERC-721-like) Grants or revokes approval for an operator to manage all of the caller's NFTs.
29. `isApprovedForAll(address _owner, address _operator) external view returns (bool)`: (ERC-721-like) Checks if an operator is approved for all NFTs owned by an address.
30. `transferFrom(address _from, address _to, uint256 _tokenId) internal`: (ERC-721-like) Internal function for transferring NFT ownership.
31. `safeTransferFrom(address _from, address _to, uint256 _tokenId) external`: (ERC-721-like) Safely transfers NFT ownership, checking if the recipient is a contract that can receive NFTs.
32. `safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external`: (ERC-721-like) Overloaded safe transfer function with additional data.
33. `tokenURI(uint256 _tokenId) external view returns (string memory)`: (ERC-721-like) Returns the URI pointing to the metadata of a given NFT.
34. `sharesBalanceOf(address _account, uint256 _nftTokenId) external view returns (uint256)`: (Custom ERC-20-like) Returns the balance of fractional shares for a specific NFT held by an account.
35. `transferShares(address _to, uint256 _nftTokenId, uint256 _amount) external`: (Custom ERC-20-like) Transfers `_amount` of shares for a specific NFT from the caller to `_to`.
36. `approveShares(address _spender, uint256 _nftTokenId, uint256 _amount) external`: (Custom ERC-20-like) Allows `_spender` to withdraw `_amount` of shares for a specific NFT from the caller's balance.
37. `sharesAllowance(address _owner, address _spender, uint256 _nftTokenId) external view returns (uint256)`: (Custom ERC-20-like) Returns the amount of shares that `_spender` is allowed to spend on behalf of `_owner` for a specific NFT.
38. `transferSharesFrom(address _from, address _to, uint256 _nftTokenId, uint256 _amount) external`: (Custom ERC-20-like) Transfers `_amount` of shares for a specific NFT from `_from` to `_to`, with approval from `_from`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AetherCanvas
 * @dev A Decentralized, On-Chain AI-Assisted Generative Art & Fractional Ownership Platform.
 *
 * Outline:
 * 1.  Enums and Structs: Defines data structures for art parameters, snapshot proposals,
 *     and general governance proposals.
 * 2.  State Variables: Stores core contract configuration, art parameters, evolution state,
 *     NFT metadata, and governance-related data.
 * 3.  Events: Declares events for transparency and off-chain monitoring of key actions.
 * 4.  Custom Modifiers: Implements basic access control (ownership), pausing, and proposal state checks.
 * 5.  Constructor: Initializes the contract with an owner and initial art parameters.
 * 6.  Core Art Generation & Evolution Functions:
 *     - Functions to read current art state and parameters.
 *     - Mechanisms for users to "influence" art parameters.
 *     - Logic for the art to "evolve" based on influences and time.
 *     - Functions to set references to external algorithm contracts or oracle data.
 *     - Functions to get SVG fragments/parameters for off-chain rendering of live art.
 * 7.  NFT Minting & Fractionalization Functions:
 *     - Functions to propose and vote on minting a snapshot of the evolving art.
 *     - Logic to mint a unique ERC-721 compliant NFT.
 *     - Mechanism to fractionalize a minted NFT into tradable shares.
 * 8.  Governance & Treasury Functions:
 *     - Functions for users to submit and vote on various proposals (parameter changes,
 *       algorithm upgrades).
 *     - Logic to execute passed proposals.
 *     - Functions for managing the contract's treasury funds.
 * 9.  Utility & Admin Functions:
 *     - Basic administrative functions like pausing the contract or transferring ownership.
 *     - ERC-721 compliance functions (ownerOf, balanceOf, transferFrom, etc.) implemented manually.
 *     - ERC-20 compliance functions (balanceOf, transfer, approve, etc.) for fractional shares,
 *       also implemented manually for the custom share token.
 */

/**
 * Function Summary:
 *
 * I. Core Art Generation & Evolution:
 * 1.  `getCurrentArtStateHash()`: Pure function generating a unique hash of the current art parameters.
 * 2.  `getArtParameters()`: Returns the current set of evolving art parameters.
 * 3.  `influenceParameter(uint256 _paramIndex)`: Allows users to pay to influence a specific art parameter.
 * 4.  `triggerEvolutionCycle()`: Advances the art's state based on accumulated influences and time, decaying old influences.
 * 5.  `getEvolutionCycleInfo()`: Provides details about the current evolution cycle progress.
 * 6.  `setArtAlgorithmReference(address _newAlgContract)`: Owner/DAO sets the address of a contract defining art rendering logic.
 * 7.  `requestOracleFeedUpdate(bytes32 _feedKey)`: (Conceptual) Simulates a request for external data influencing art.
 * 8.  `getLiveArtSVGFragment(uint256 _paramIndex)`: Returns a conceptual SVG fragment string based on a parameter for off-chain rendering.
 * 9.  `getLiveArtRenderParameters()`: Returns all art parameters formatted for external rendering.
 *
 * II. NFT Minting & Fractionalization:
 * 10. `proposeArtSnapshot()`: Initiates a proposal to mint the current art state as an NFT.
 * 11. `voteForSnapshotProposal(uint256 _proposalId, bool _support)`: Allows users to vote on a snapshot proposal.
 * 12. `mintSnapshotNFT(uint256 _proposalId)`: Mints an NFT if the snapshot proposal passes.
 * 13. `fractionalizeNFT(uint256 _tokenId, uint256 _shares)`: Breaks down a minted NFT into fungible shares.
 * 14. `getNFTSharesInfo(uint256 _tokenId)`: Retrieves details about fractionalized NFT shares.
 *
 * III. Governance & Treasury:
 * 15. `submitParameterChangeProposal(uint256 _paramIndex, bytes32 _newValue)`: Proposes a direct change to an art parameter.
 * 16. `submitAlgorithmUpgradeProposal(address _newAlgContract)`: Proposes to upgrade the art algorithm contract.
 * 17. `voteOnGeneralProposal(uint256 _proposalId, bool _support)`: Allows users to vote on general governance proposals.
 * 18. `executeProposal(uint256 _proposalId)`: Executes a governance proposal if it has passed.
 * 19. `getProposalInfo(uint256 _proposalId)`: Retrieves details about a specific governance proposal.
 * 20. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allows the owner/DAO to withdraw funds from the treasury.
 *
 * IV. Utility & ERC-721/ERC-20 Compliance (Manual Implementation):
 * 21. `pause()`: Puts the contract into a paused state.
 * 22. `unpause()`: Resumes contract operations.
 * 23. `transferContractOwnership(address _newOwner)`: Transfers administrative ownership of the contract.
 * 24. `balanceOf(address _owner)`: Returns the number of NFTs owned by an address (ERC-721).
 * 25. `ownerOf(uint256 _tokenId)`: Returns the owner of a specific NFT (ERC-721).
 * 26. `approve(address _to, uint256 _tokenId)`: Grants approval to an address for a specific NFT (ERC-721).
 * 27. `getApproved(uint256 _tokenId)`: Returns the approved address for an NFT (ERC-721).
 * 28. `setApprovalForAll(address _operator, bool _approved)`: Grants/revokes operator approval for all NFTs (ERC-721).
 * 29. `isApprovedForAll(address _owner, address _operator)`: Checks operator approval (ERC-721).
 * 30. `transferFrom(address _from, address _to, uint256 _tokenId)`: Transfers NFT (ERC-721).
 * 31. `safeTransferFrom(address _from, address _to, uint256 _tokenId)`: Safely transfers NFT (ERC-721).
 * 32. `safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data)`: Overloaded safe transfer (ERC-721).
 * 33. `tokenURI(uint256 _tokenId)`: Returns URI for an NFT (ERC-721).
 * 34. `sharesBalanceOf(address _account, uint256 _nftTokenId)`: Returns share balance for a specific NFT (Custom ERC-20-like).
 * 35. `transferShares(address _to, uint256 _nftTokenId, uint256 _amount)`: Transfers shares for a specific NFT (Custom ERC-20-like).
 * 36. `approveShares(address _spender, uint256 _nftTokenId, uint256 _amount)`: Approve shares for a specific NFT (Custom ERC-20-like).
 * 37. `sharesAllowance(address _owner, uint256 _spender, uint256 _nftTokenId)`: Returns shares allowance (Custom ERC-20-like).
 * 38. `transferSharesFrom(address _from, address _to, uint256 _nftTokenId, uint256 _amount)`: Transfer shares from (Custom ERC-20-like).
 */
contract AetherCanvas {
    // --- Enums and Structs ---

    // Structure for an evolving art parameter
    struct ArtParameter {
        bytes32 value; // Current value of the parameter (e.g., color hex, shape ID)
        uint256 baseInfluence; // Base influence for this parameter, constant
    }

    // Details for a snapshot proposal (to mint an NFT)
    struct SnapshotProposal {
        bytes32 artStateHash; // Hash of the art state at the time of proposal
        uint256 proposalTime; // Timestamp when proposal was made
        uint256 votesFor; // Accumulated votes for this proposal
        uint256 votesAgainst; // Accumulated votes against this proposal
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed; // True if NFT has been minted from this proposal
    }

    // Generic structure for other governance proposals
    struct GeneralProposal {
        ProposalType proposalType; // Type of proposal
        uint256 proposalTime; // Timestamp when proposal was made
        uint256 votesFor; // Accumulated votes for this proposal
        uint256 votesAgainst; // Accumulated votes against this proposal
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed; // True if the proposal has been executed

        // Data specific to proposal type
        uint256 paramIndex; // For PARAMETER_CHANGE
        bytes32 newParamValue; // For PARAMETER_CHANGE
        address newAlgorithmContract; // For ALGORITHM_UPGRADE
    }

    enum ProposalType {
        SNAPSHOT_MINT,
        PARAMETER_CHANGE,
        ALGORITHM_UPGRADE
    }

    enum ProposalState {
        PENDING,
        ACTIVE,
        SUCCEEDED,
        FAILED,
        EXECUTED
    }

    // Information about fractional shares for a specific NFT
    struct SharesInfo {
        bool isFractionalized; // True if the NFT has been fractionalized
        uint256 totalShares; // Total shares created for this NFT
        mapping(address => uint256) balances; // Balances of shares per address
        mapping(address => mapping(address => uint256)) allowances; // Allowances for shares
    }

    // --- State Variables ---

    // Core Contract
    address public owner;
    bool public paused;

    // Art Parameters & Evolution
    mapping(uint256 => ArtParameter) public artParameters;
    uint256[] public artParameterIndices; // To iterate through parameters
    mapping(uint256 => uint256) public artParameterInfluences; // Accumulated influence for next cycle

    uint256 public lastEvolutionCycleTime;
    uint256 public evolutionCycleDuration; // Time in seconds for one evolution cycle
    uint256 public influenceDecayRate; // Percentage (0-100) by which influence decays per cycle

    // NFT Management (Manual ERC-721-like implementation)
    mapping(uint256 => address) private _tokenOwners; // tokenId => owner
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved
    uint256 private _tokenIdCounter; // Next available token ID
    mapping(uint256 => string) private _tokenURIs; // tokenId => URI
    uint256 public _nftTotalSupply;

    // Fractionalization (Custom ERC-20-like implementation per NFT)
    mapping(uint256 => SharesInfo) public _nftShares; // tokenId => SharesInfo

    // Governance
    mapping(uint256 => SnapshotProposal) public snapshotProposals;
    mapping(uint256 => GeneralProposal) public generalProposals;
    uint256 private _proposalIdCounter; // Counter for all proposals (snapshot & general)
    uint256 public minVotesForProposal; // Minimum votes required for a proposal to pass
    uint256 public proposalVotingPeriod; // Time in seconds for proposals to be voted on

    // Treasury
    uint256 public influenceCost; // Cost in wei to influence a parameter
    uint256 public treasury; // Funds held by the contract

    // Art Algorithm (external contract reference)
    address public artAlgorithmReference; // Address of a contract that handles SVG/metadata generation logic based on params

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    event ParameterInfluenced(uint256 indexed paramIndex, address indexed contributor, uint256 amount);
    event ArtEvolved(uint256 indexed cycleNumber, bytes32 newArtStateHash);
    event ArtAlgorithmReferenceSet(address indexed newAlgorithmContract);

    event SnapshotProposed(uint256 indexed proposalId, bytes32 artStateHash, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, ProposalType indexed proposalType, address indexed voter, bool support);
    event SnapshotMinted(uint256 indexed proposalId, uint256 indexed tokenId, address indexed minter, bytes32 artStateHash);
    event NFTFractionalized(uint256 indexed tokenId, uint256 shares);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC-721
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); // ERC-721
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // ERC-721

    event SharesTransfer(uint256 indexed nftTokenId, address indexed from, address indexed to, uint256 amount); // Custom
    event SharesApproval(uint256 indexed nftTokenId, address indexed owner, address indexed spender, uint256 amount); // Custom

    event ParameterChangeProposed(uint256 indexed proposalId, uint256 indexed paramIndex, bytes32 newParamValue, address indexed proposer);
    event AlgorithmUpgradeProposed(uint256 indexed proposalId, address indexed newAlgContract, address indexed proposer);
    event ProposalExecuted(uint256 indexed proposalId, ProposalType indexed proposalType, address indexed executor);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);

    // --- Custom Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier isValidProposal(uint256 _proposalId, ProposalType _type) {
        if (_type == ProposalType.SNAPSHOT_MINT) {
            require(_proposalId < _proposalIdCounter, "SnapshotProposal: invalid proposal ID");
            // Further checks if needed, e.g., require snapshotProposals[_proposalId].artStateHash != bytes32(0)
        } else {
            require(_proposalId < _proposalIdCounter, "GeneralProposal: invalid proposal ID");
            require(generalProposals[_proposalId].proposalType == _type, "GeneralProposal: type mismatch");
        }
        _;
    }

    // --- Constructor ---

    constructor(uint256 _evolutionCycleDuration, uint256 _influenceDecayRate, uint256 _minVotesForProposal, uint256 _proposalVotingPeriod, uint256 _influenceCost) {
        owner = msg.sender;
        paused = false;

        evolutionCycleDuration = _evolutionCycleDuration; // e.g., 24 hours in seconds
        influenceDecayRate = _influenceDecayRate; // e.g., 50 for 50% decay
        lastEvolutionCycleTime = block.timestamp;

        minVotesForProposal = _minVotesForProposal; // e.g., 100 votes
        proposalVotingPeriod = _proposalVotingPeriod; // e.g., 7 days in seconds
        _proposalIdCounter = 0;

        influenceCost = _influenceCost; // e.g., 0.01 ETH in wei

        // Initialize some default art parameters
        artParameterIndices.push(0);
        artParameters[0] = ArtParameter(0xFF0000FF, 100); // Param 0: Red color, base influence 100
        artParameterIndices.push(1);
        artParameters[1] = ArtParameter(0x00FF00FF, 50); // Param 1: Green color, base influence 50
        artParameterIndices.push(2);
        artParameters[2] = ArtParameter(0x0000FF00, 75); // Param 2: Blue component, base influence 75
        artParameterIndices.push(3);
        artParameters[3] = ArtParameter(0x00000001, 20); // Param 3: Shape type, base influence 20 (e.g., 1 for circle)

        emit OwnershipTransferred(address(0), msg.sender);
    }

    // --- I. Core Art Generation & Evolution ---

    /**
     * @dev Generates a unique, deterministic hash representing the current state of all art parameters.
     *      This hash can serve as an on-chain identifier for the live art's appearance.
     * @return bytes32 The SHA256 hash of all current art parameter values concatenated.
     */
    function getCurrentArtStateHash() public view returns (bytes32) {
        bytes memory data = new bytes(artParameterIndices.length * 32); // Each bytes32 is 32 bytes
        for (uint256 i = 0; i < artParameterIndices.length; i++) {
            assembly {
                mstore(add(data, add(0x20, mul(i, 0x20))), sload(add(artParameters.slot, mul(mload(add(artParameterIndices.slot, mul(i, 0x20))), 0x40)))) // Assuming ArtParameter is 2 32-byte slots, and value is first
            }
        }
        return keccak256(data);
    }

    /**
     * @dev Returns the current values of all evolving art parameters.
     * @return bytes32[] memory currentValues: Array of current parameter values.
     * @return uint256[] memory currentInfluences: Array of accumulated influences for each parameter.
     * @return uint256[] memory baseInfluences: Array of base influences for each parameter.
     */
    function getArtParameters() public view returns (bytes32[] memory currentValues, uint256[] memory currentInfluences, uint256[] memory baseInfluences) {
        currentValues = new bytes32[](artParameterIndices.length);
        currentInfluences = new uint256[](artParameterIndices.length);
        baseInfluences = new uint256[](artParameterIndices.length);

        for (uint256 i = 0; i < artParameterIndices.length; i++) {
            uint256 paramIdx = artParameterIndices[i];
            currentValues[i] = artParameters[paramIdx].value;
            currentInfluences[i] = artParameterInfluences[paramIdx];
            baseInfluences[i] = artParameters[paramIdx].baseInfluence;
        }
    }

    /**
     * @dev Allows a user to contribute `influenceCost` ETH to increase the accumulated influence for a specific art parameter,
     *      nudging the art's evolution in a desired direction.
     * @param _paramIndex The index of the art parameter to influence.
     */
    function influenceParameter(uint256 _paramIndex) external payable whenNotPaused {
        require(msg.value == influenceCost, "AetherCanvas: Incorrect influence cost sent");
        require(_paramIndex < artParameterIndices.length, "AetherCanvas: Invalid parameter index");

        artParameterInfluences[_paramIndex] += 1; // Each influence adds 1 unit
        treasury += msg.value; // Add funds to treasury

        emit ParameterInfluenced(_paramIndex, msg.sender, msg.value);
    }

    /**
     * @dev Advances the art's state based on accumulated influences and time.
     *      This function applies the net influence to parameters, decays old influences,
     *      and can introduce time-based changes, simulating a dynamic, evolving system.
     *      Callable by anyone, but includes a cycle duration check.
     */
    function triggerEvolutionCycle() external whenNotPaused {
        require(block.timestamp >= lastEvolutionCycleTime + evolutionCycleDuration, "AetherCanvas: Evolution cycle not yet complete");

        // Simple pseudo-randomness based on block data for subtle shifts
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenIdCounter)));

        for (uint256 i = 0; i < artParameterIndices.length; i++) {
            uint256 paramIdx = artParameterIndices[i];
            uint256 accumulatedInfluence = artParameterInfluences[paramIdx];
            bytes32 currentValue = artParameters[paramIdx].value;

            // Apply influence: for simplicity, let's say influence directly affects the byte representation
            // A more complex algorithm would interpret bytes32 as colors, shapes, etc.
            uint256 currentNum = uint256(currentValue);
            uint256 baseInfluence = artParameters[paramIdx].baseInfluence;

            // Example: Influence shifts value, then some entropy
            uint256 nextValue = (currentNum + accumulatedInfluence + (entropy % (baseInfluence / 2 + 1))) % (2**256); // Add accumulated influence and some noise

            // Decay influences for the next cycle
            artParameterInfluences[paramIdx] = (accumulatedInfluence * (100 - influenceDecayRate)) / 100;

            artParameters[paramIdx].value = bytes32(nextValue); // Update parameter value
        }

        lastEvolutionCycleTime = block.timestamp;
        emit ArtEvolved(block.number, getCurrentArtStateHash());
    }

    /**
     * @dev Provides details about the current evolution cycle progress.
     * @return uint256 lastCycleTime: Timestamp of the last evolution.
     * @return uint256 cycleDuration: Configured duration of a cycle in seconds.
     * @return uint256 timeUntilNextEvolution: Seconds remaining until the next evolution can be triggered.
     */
    function getEvolutionCycleInfo() external view returns (uint256 lastCycleTime, uint256 cycleDuration, uint256 timeUntilNextEvolution) {
        lastCycleTime = lastEvolutionCycleTime;
        cycleDuration = evolutionCycleDuration;
        if (block.timestamp < lastEvolutionCycleTime + evolutionCycleDuration) {
            timeUntilNextEvolution = (lastEvolutionCycleTime + evolutionCycleDuration) - block.timestamp;
        } else {
            timeUntilNextEvolution = 0;
        }
    }

    /**
     * @dev Allows the contract owner (or eventually DAO) to set the address of an external contract
     *      that defines how the on-chain art parameters are interpreted and rendered into visual art.
     * @param _newAlgContract The address of the new art algorithm contract.
     */
    function setArtAlgorithmReference(address _newAlgContract) external onlyOwner {
        require(_newAlgContract != address(0), "AetherCanvas: Algorithm contract cannot be zero address");
        artAlgorithmReference = _newAlgContract;
        emit ArtAlgorithmReferenceSet(_newAlgContract);
    }

    /**
     * @dev (Conceptual/Placeholder) Simulates a request to an external oracle for data.
     *      In a real scenario, this would integrate with an oracle network (e.g., Chainlink)
     *      to fetch external data (like weather, market prices) that could influence art parameters.
     * @param _feedKey Identifier for the data feed to request.
     */
    function requestOracleFeedUpdate(bytes32 _feedKey) external pure {
        // This function would typically interact with an oracle contract.
        // For this example, it's a placeholder to demonstrate the concept.
        // E.g., ChainlinkClient.requestBytes32(_jobId, _fee, _feedKey)
        revert("AetherCanvas: Oracle integration is conceptual and not fully implemented.");
    }

    /**
     * @dev Returns a conceptual string fragment representing a part of the live art's SVG
     *      based on a single parameter. This is for off-chain rendering, indicating what
     *      visual component a parameter controls.
     * @param _paramIndex The index of the art parameter.
     * @return string A conceptual SVG fragment string.
     */
    function getLiveArtSVGFragment(uint256 _paramIndex) external view returns (string memory) {
        require(_paramIndex < artParameterIndices.length, "AetherCanvas: Invalid parameter index");
        bytes32 paramValue = artParameters[_paramIndex].value;

        // This is a highly simplified example. Real SVG generation would be off-chain.
        // Here, we just return a string representation of the parameter.
        return string(abi.encodePacked("Param", Strings.toString(_paramIndex), ": ", Strings.toHexString(paramValue)));
    }

    /**
     * @dev Returns all current art parameter values in a format suitable for an external
     *      rendering engine to generate the complete visual artwork.
     * @return bytes32[] memory An array of all current art parameter values.
     */
    function getLiveArtRenderParameters() external view returns (bytes32[] memory) {
        bytes32[] memory currentValues = new bytes32[](artParameterIndices.length);
        for (uint256 i = 0; i < artParameterIndices.length; i++) {
            uint256 paramIdx = artParameterIndices[i];
            currentValues[i] = artParameters[paramIdx].value;
        }
        return currentValues;
    }

    // --- II. NFT Minting & Fractionalization ---

    /**
     * @dev Initiates a governance proposal to mint the current, live state of the evolving art as a permanent, unique NFT.
     *      Requires the art to have evolved sufficiently since the last snapshot/deployment.
     */
    function proposeArtSnapshot() external whenNotPaused {
        require(block.timestamp >= lastEvolutionCycleTime + evolutionCycleDuration * 2, "AetherCanvas: Art must evolve more before new snapshot proposal");
        // Could add more complex conditions: e.g., minimum accumulated influence threshold

        uint256 proposalId = _proposalIdCounter++;
        snapshotProposals[proposalId].artStateHash = getCurrentArtStateHash();
        snapshotProposals[proposalId].proposalTime = block.timestamp;
        snapshotProposals[proposalId].executed = false;

        emit SnapshotProposed(proposalId, snapshotProposals[proposalId].artStateHash, msg.sender);
    }

    /**
     * @dev Allows users to cast their vote (for or against) on a specific snapshot proposal.
     *      Voting power could be tied to past influence contributions or locked tokens (not implemented here).
     * @param _proposalId The ID of the snapshot proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteForSnapshotProposal(uint256 _proposalId, bool _support) external whenNotPaused isValidProposal(_proposalId, ProposalType.SNAPSHOT_MINT) {
        SnapshotProposal storage proposal = snapshotProposals[_proposalId];
        require(block.timestamp < proposal.proposalTime + proposalVotingPeriod, "SnapshotProposal: Voting period ended");
        require(!proposal.hasVoted[msg.sender], "SnapshotProposal: Already voted");
        require(!proposal.executed, "SnapshotProposal: Proposal already executed");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, ProposalType.SNAPSHOT_MINT, msg.sender, _support);
    }

    /**
     * @dev Executes the minting of an NFT if the corresponding snapshot proposal has passed its voting period
     *      and met the approval threshold. Resets influence counters for the next evolution cycle.
     * @param _proposalId The ID of the snapshot proposal to mint.
     */
    function mintSnapshotNFT(uint256 _proposalId) external whenNotPaused isValidProposal(_proposalId, ProposalType.SNAPSHOT_MINT) {
        SnapshotProposal storage proposal = snapshotProposals[_proposalId];
        require(block.timestamp >= proposal.proposalTime + proposalVotingPeriod, "SnapshotProposal: Voting period not ended");
        require(!proposal.executed, "SnapshotProposal: Proposal already executed");
        require(proposal.votesFor >= minVotesForProposal, "SnapshotProposal: Not enough votes to pass");
        require(proposal.votesFor > proposal.votesAgainst, "SnapshotProposal: Votes against are higher");

        proposal.executed = true; // Mark as executed

        // Mint the NFT (ERC-721-like internal function)
        _mint(msg.sender, _tokenIdCounter);
        _tokenURIs[_tokenIdCounter] = string(abi.encodePacked("ipfs://", Strings.toHexString(proposal.artStateHash))); // Example URI
        _nftTotalSupply++;
        uint256 newTokenId = _tokenIdCounter;
        _tokenIdCounter++;

        // Reset art influences after a snapshot, symbolizing a new 'canvas' or 'epoch'
        for (uint256 i = 0; i < artParameterIndices.length; i++) {
            artParameterInfluences[artParameterIndices[i]] = artParameters[artParameterIndices[i]].baseInfluence; // Reset to base influence
        }
        lastEvolutionCycleTime = block.timestamp; // Reset evolution timer

        emit SnapshotMinted(_proposalId, newTokenId, msg.sender, proposal.artStateHash);
        emit ProposalExecuted(_proposalId, ProposalType.SNAPSHOT_MINT, msg.sender);
    }

    /**
     * @dev Allows the owner of a minted NFT to break it down into a specified number of fungible "shares,"
     *      which can then be traded, enabling collective ownership.
     *      Transfers the NFT to the contract, and issues shares to the original owner.
     * @param _tokenId The ID of the NFT to fractionalize.
     * @param _shares The number of shares to create for this NFT.
     */
    function fractionalizeNFT(uint256 _tokenId, uint256 _shares) external whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Fractionalization: Caller is not NFT owner");
        require(!_nftShares[_tokenId].isFractionalized, "Fractionalization: NFT already fractionalized");
        require(_shares > 0, "Fractionalization: Must create at least one share");

        // Transfer NFT to this contract
        _transfer(msg.sender, address(this), _tokenId);

        // Initialize shares info
        _nftShares[_tokenId].isFractionalized = true;
        _nftShares[_tokenId].totalShares = _shares;
        _nftShares[_tokenId].balances[msg.sender] = _shares;

        emit NFTFractionalized(_tokenId, _shares);
        emit SharesTransfer(_tokenId, address(0), msg.sender, _shares); // Initial shares issuance
    }

    /**
     * @dev Retrieves information about a specific NFT's fractionalization status,
     *      including whether it's fractionalized, the total shares issued, and the number
     *      of shares currently held by the contract (if fractionalized).
     * @param _tokenId The ID of the NFT.
     * @return bool isFractionalized: True if the NFT is fractionalized.
     * @return uint256 totalShares: Total shares created for this NFT.
     * @return uint256 contractBalance: Number of shares held by this contract (should be 0 unless bought back).
     */
    function getNFTSharesInfo(uint256 _tokenId) external view returns (bool isFractionalized, uint256 totalShares, uint256 contractBalance) {
        SharesInfo storage info = _nftShares[_tokenId];
        isFractionalized = info.isFractionalized;
        totalShares = info.totalShares;
        contractBalance = info.balances[address(this)];
    }

    // --- III. Governance & Treasury ---

    /**
     * @dev Allows any user to submit a governance proposal to directly change a specific
     *      art parameter to a new target value, subject to community vote.
     * @param _paramIndex The index of the art parameter to propose changing.
     * @param _newValue The new target value for the parameter.
     */
    function submitParameterChangeProposal(uint256 _paramIndex, bytes32 _newValue) external whenNotPaused {
        require(_paramIndex < artParameterIndices.length, "AetherCanvas: Invalid parameter index");

        uint256 proposalId = _proposalIdCounter++;
        GeneralProposal storage proposal = generalProposals[proposalId];
        proposal.proposalType = ProposalType.PARAMETER_CHANGE;
        proposal.proposalTime = block.timestamp;
        proposal.paramIndex = _paramIndex;
        proposal.newParamValue = _newValue;
        proposal.executed = false;

        emit ParameterChangeProposed(proposalId, _paramIndex, _newValue, msg.sender);
    }

    /**
     * @dev Allows any user to propose upgrading the `artAlgorithmReference` contract,
     *      which defines how art parameters are interpreted and rendered.
     * @param _newAlgContract The address of the new art algorithm contract to propose.
     */
    function submitAlgorithmUpgradeProposal(address _newAlgContract) external whenNotPaused {
        require(_newAlgContract != address(0), "AetherCanvas: Algorithm contract cannot be zero address");

        uint256 proposalId = _proposalIdCounter++;
        GeneralProposal storage proposal = generalProposals[proposalId];
        proposal.proposalType = ProposalType.ALGORITHM_UPGRADE;
        proposal.proposalTime = block.timestamp;
        proposal.newAlgorithmContract = _newAlgContract;
        proposal.executed = false;

        emit AlgorithmUpgradeProposed(proposalId, _newAlgContract, msg.sender);
    }

    /**
     * @dev Allows users to cast their vote on general governance proposals (parameter changes, algorithm upgrades).
     * @param _proposalId The ID of the general proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnGeneralProposal(uint256 _proposalId, bool _support) external whenNotPaused isValidProposal(_proposalId, ProposalType.PARAMETER_CHANGE) isValidProposal(_proposalId, ProposalType.ALGORITHM_UPGRADE) {
        GeneralProposal storage proposal = generalProposals[_proposalId];
        require(block.timestamp < proposal.proposalTime + proposalVotingPeriod, "GeneralProposal: Voting period ended");
        require(!proposal.hasVoted[msg.sender], "GeneralProposal: Already voted");
        require(!proposal.executed, "GeneralProposal: Proposal already executed");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, proposal.proposalType, msg.sender, _support);
    }

    /**
     * @dev Executes a governance proposal if it has passed its voting period and met the necessary approval criteria.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        require(_proposalId < _proposalIdCounter, "Proposal: Invalid proposal ID"); // Check if it's a valid ID for either type

        bool isSnapshotProposal = false;
        if (_proposalId < _proposalIdCounter && snapshotProposals[_proposalId].proposalTime != 0) {
            isSnapshotProposal = true;
        }

        if (isSnapshotProposal) {
            // Re-use logic for snapshot minting
            mintSnapshotNFT(_proposalId);
        } else {
            // General proposal execution
            GeneralProposal storage proposal = generalProposals[_proposalId];
            require(block.timestamp >= proposal.proposalTime + proposalVotingPeriod, "GeneralProposal: Voting period not ended");
            require(!proposal.executed, "GeneralProposal: Proposal already executed");
            require(proposal.votesFor >= minVotesForProposal, "GeneralProposal: Not enough votes to pass");
            require(proposal.votesFor > proposal.votesAgainst, "GeneralProposal: Votes against are higher");

            proposal.executed = true; // Mark as executed

            if (proposal.proposalType == ProposalType.PARAMETER_CHANGE) {
                artParameters[proposal.paramIndex].value = proposal.newParamValue;
                emit ParameterInfluenced(proposal.paramIndex, address(this), 0); // Mark as algorithm change, not user influence
            } else if (proposal.proposalType == ProposalType.ALGORITHM_UPGRADE) {
                artAlgorithmReference = proposal.newAlgorithmContract;
                emit ArtAlgorithmReferenceSet(proposal.newAlgorithmContract);
            }

            emit ProposalExecuted(_proposalId, proposal.proposalType, msg.sender);
        }
    }

    /**
     * @dev Retrieves detailed information about a specific general governance proposal,
     *      including its state, votes, and target.
     * @param _proposalId The ID of the general proposal.
     * @return GeneralProposal calldata The struct containing proposal details.
     */
    function getProposalInfo(uint256 _proposalId) external view returns (GeneralProposal calldata) {
        require(_proposalId < _proposalIdCounter, "GeneralProposal: Invalid proposal ID");
        // This function would ideally return a deep copy or individual elements to avoid memory issues with mappings.
        // For simplicity, returning calldata struct directly, assuming it's consumed off-chain.
        // In practice, you'd iterate and return explicit values.
        // (This warning is due to returning a struct that contains a mapping).
        return generalProposals[_proposalId];
    }

    /**
     * @dev Allows the contract owner (or later, DAO) to withdraw accumulated funds from the contract's treasury,
     *      which are collected from `influenceParameter` calls.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of funds to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner whenNotPaused {
        require(_amount > 0, "Treasury: Amount must be greater than zero");
        require(treasury >= _amount, "Treasury: Insufficient funds");
        require(address(this).balance >= _amount, "Treasury: Contract balance too low");

        treasury -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Treasury: Failed to send Ether");

        emit TreasuryWithdrawal(_recipient, _amount);
    }

    // --- IV. Utility & ERC-721/ERC-20 Compliance (Manual Implementation) ---

    /**
     * @dev Puts the contract into a paused state, preventing most state-changing operations.
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Resumes contract operations from a paused state.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Transfers administrative ownership of the contract to a new address.
     * @param _newOwner The address of the new owner.
     */
    function transferContractOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    // --- ERC-721-like implementations ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _tokenOwners[tokenId] = to;
        delete _tokenApprovals[tokenId]; // Clear approval on transfer

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwners[tokenId] = to;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) { // Check if 'to' is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    /**
     * @dev Returns the number of NFTs owned by a given address.
     * @param _owner The address to query the balance of.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "ERC721: address zero is not a valid owner");
        uint256 count = 0;
        // This is inefficient for many NFTs. A real ERC721 would use a mapping.
        // For custom implementation without OpenZeppelin, we assume a small number of NFTs or accept inefficiency.
        for (uint256 i = 0; i < _tokenIdCounter; i++) {
            if (_exists(i) && _tokenOwners[i] == _owner) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Returns the address of the owner of a specific NFT.
     * @param _tokenId The ID of the NFT.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address ownerAddr = _tokenOwners[_tokenId];
        require(ownerAddr != address(0), "ERC721: owner query for nonexistent token");
        return ownerAddr;
    }

    /**
     * @dev Approves an address to transfer a specific NFT.
     * @param _to The address to approve.
     * @param _tokenId The ID of the NFT.
     */
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
        address ownerAddr = ownerOf(_tokenId);
        require(_to != ownerAddr, "ERC721: approval to current owner");
        require(msg.sender == ownerAddr || isApprovedForAll(ownerAddr, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _approve(_to, _tokenId);
    }

    /**
     * @dev Returns the approved address for a specific NFT.
     * @param _tokenId The ID of the NFT.
     */
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[_tokenId];
    }

    /**
     * @dev Grants or revokes approval for an operator to manage all of the caller's NFTs.
     * @param _operator The address to set as an operator.
     * @param _approved True to approve, false to revoke.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Checks if an operator is approved for all NFTs owned by an address.
     * @param _owner The address of the NFT owner.
     * @param _operator The address of the operator.
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    /**
     * @dev Transfers NFT ownership.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The ID of the NFT.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Safely transfers NFT ownership, checking if the recipient is a contract that can receive NFTs.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The ID of the NFT.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Overloaded safe transfer function with additional data.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The ID of the NFT.
     * @param _data Additional data to pass to the receiver.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address ownerAddr = ownerOf(tokenId);
        return (spender == ownerAddr || getApproved(tokenId) == spender || isApprovedForAll(ownerAddr, spender));
    }

    /**
     * @dev Returns the URI pointing to the metadata of a given NFT.
     * @param _tokenId The ID of the NFT.
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

    // --- Custom ERC-20-like implementations for fractional shares ---

    /**
     * @dev Returns the balance of fractional shares for a specific NFT held by an account.
     * @param _account The address of the account.
     * @param _nftTokenId The ID of the NFT for which shares are queried.
     */
    function sharesBalanceOf(address _account, uint256 _nftTokenId) external view returns (uint256) {
        require(_nftShares[_nftTokenId].isFractionalized, "Shares: NFT is not fractionalized");
        return _nftShares[_nftTokenId].balances[_account];
    }

    /**
     * @dev Transfers `_amount` of shares for a specific NFT from the caller to `_to`.
     * @param _to The recipient address.
     * @param _nftTokenId The ID of the NFT whose shares are being transferred.
     * @param _amount The amount of shares to transfer.
     */
    function transferShares(address _to, uint256 _nftTokenId, uint256 _amount) external whenNotPaused {
        require(_nftShares[_nftTokenId].isFractionalized, "Shares: NFT is not fractionalized");
        require(_to != address(0), "Shares: transfer to the zero address");
        require(_nftShares[_nftTokenId].balances[msg.sender] >= _amount, "Shares: Insufficient balance");

        _nftShares[_nftTokenId].balances[msg.sender] -= _amount;
        _nftShares[_nftTokenId].balances[_to] += _amount;
        emit SharesTransfer(_nftTokenId, msg.sender, _to, _amount);
    }

    /**
     * @dev Allows `_spender` to withdraw `_amount` of shares for a specific NFT from the caller's balance.
     * @param _spender The address to approve.
     * @param _nftTokenId The ID of the NFT whose shares are being approved.
     * @param _amount The amount of shares to approve.
     */
    function approveShares(address _spender, uint256 _nftTokenId, uint256 _amount) external whenNotPaused {
        require(_nftShares[_nftTokenId].isFractionalized, "Shares: NFT is not fractionalized");
        require(_spender != address(0), "Shares: approve to the zero address");

        _nftShares[_nftTokenId].allowances[msg.sender][_spender] = _amount;
        emit SharesApproval(_nftTokenId, msg.sender, _spender, _amount);
    }

    /**
     * @dev Returns the amount of shares that `_spender` is allowed to spend on behalf of `_owner` for a specific NFT.
     * @param _owner The owner of the shares.
     * @param _spender The address of the spender.
     * @param _nftTokenId The ID of the NFT whose shares are queried.
     */
    function sharesAllowance(address _owner, uint256 _spender, uint256 _nftTokenId) external view returns (uint256) {
        require(_nftShares[_nftTokenId].isFractionalized, "Shares: NFT is not fractionalized");
        return _nftShares[_nftTokenId].allowances[_owner][address(_spender)];
    }


    /**
     * @dev Transfers `_amount` of shares for a specific NFT from `_from` to `_to`, with approval from `_from`.
     * @param _from The sender address.
     * @param _to The recipient address.
     * @param _nftTokenId The ID of the NFT whose shares are being transferred.
     * @param _amount The amount of shares to transfer.
     */
    function transferSharesFrom(address _from, address _to, uint256 _nftTokenId, uint256 _amount) external whenNotPaused {
        require(_nftShares[_nftTokenId].isFractionalized, "Shares: NFT is not fractionalized");
        require(_to != address(0), "Shares: transfer to the zero address");
        require(_nftShares[_nftTokenId].balances[_from] >= _amount, "Shares: Insufficient balance");
        require(_nftShares[_nftTokenId].allowances[_from][msg.sender] >= _amount, "Shares: Insufficient allowance");

        _nftShares[_nftTokenId].balances[_from] -= _amount;
        _nftShares[_nftTokenId].balances[_to] += _amount;
        _nftShares[_nftTokenId].allowances[_from][msg.sender] -= _amount;
        emit SharesTransfer(_nftTokenId, _from, _to, _amount);
    }

    // --- Internal Helpers for string conversion (simplified version of OpenZeppelin's Strings) ---
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits--;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }

        function toHexString(bytes32 value) internal pure returns (string memory) {
            bytes memory alphabet = "0123456789abcdef";
            bytes memory str = new bytes(64);
            for (uint256 i = 0; i < 32; i++) {
                str[i * 2] = alphabet[uint8(value[i] >> 4)];
                str[i * 2 + 1] = alphabet[uint8(value[i] & 0x0F)];
            }
            return string(str);
        }
    }
}

// --- Minimal ERC721Receiver Interface for safeTransferFrom ---
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```