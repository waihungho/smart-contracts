The Evolving Algorithmic Canvas (EAC) is a novel smart contract designed to manage a decentralized, community-driven generative art project. It leverages advanced concepts such as dynamic NFTs (dNFTs), on-chain governance for "art evolution," and integrates with off-chain computational processes for rendering. The core idea is that the community collectively evolves a set of parameters (the "Algorithm State") that define the generative art. Users can propose "mutations" to this algorithm, vote on them, and mint unique art pieces that are tied to specific historical or current states of the evolving algorithm.

---

## The Evolving Algorithmic Canvas (EAC)

**Author:** AI-Generated (concept by user request)
**License:** MIT
**Solidity Version:** ^0.8.20

### Outline and Function Summary

This contract provides a robust framework for managing a perpetually evolving digital art project, where the art's generative rules are collectively governed and updated. It ensures the provenance and dynamic nature of minted art pieces.

**I. Core System & Evolution Management**
1.  **`initializeAlgorithm(bytes memory initialAlgorithmStateData)`**: Sets up the very first algorithm state for Epoch 1. This crucial initial parameter set defines the starting point of the art's evolution. Callable only once by the contract owner.
2.  **`advanceEpoch()`**: Transitions the project to a new evolutionary epoch. This action finalizes the current epoch's algorithm state and prepares for new mutations. It ensures a minimum delay between advances to allow for proper governance cycles.
3.  **`getCurrentEpoch()`**: A read-only function that returns the current active epoch number. This indicates the current phase of the algorithm's evolution.
4.  **`getAlgorithmState(uint256 epochId)`**: Retrieves the full `AlgorithmState` struct (including raw data, timestamp, and off-chain hash) for any specified historical or current epoch.
5.  **`getAlgorithmStateData(uint256 epochId)`**: Returns only the raw `bytes` data representing the algorithm parameters for a specific epoch, useful for off-chain rendering or analysis.

**II. Mutation Proposals & Governance**
6.  **`proposeMutation(string memory description, bytes memory proposedAlgorithmStateData)`**: Allows any user to propose a change (mutation) to the algorithm state. Requires a specified ETH stake to deter spam and ensure commitment. The proposal targets the *current* active epoch.
7.  **`voteOnMutation(uint256 proposalId, bool support)`**: Enables community members to vote `for` or `against` a proposed mutation. Each address can vote only once per proposal, ensuring fair participation.
8.  **`finalizeMutation(uint256 proposalId)`**: Concludes the voting period for a proposal. If the proposal passes (e.g., by simple majority), its `proposedAlgorithmStateData` becomes the definitive algorithm state for its target epoch. Staked ETH is returned to the proposer on success; otherwise, it's absorbed by the contract.
9.  **`getMutationProposal(uint256 proposalId)`**: Provides comprehensive details about a specific mutation proposal, including its status, votes, and proposed data.
10. **`cancelMutationProposal(uint256 proposalId)`**: Allows the original proposer to cancel their proposal and reclaim their stake, provided no votes have been cast on it yet.

**III. Dynamic NFT (dNFT) Minting & Management**
11. **`mintArtPiece(uint256 epochId)`**: Mints a new unique ERC721 token (dNFT). Each dNFT is permanently linked to the specific `epochId` from which its generative parameters were derived, ensuring traceability and uniqueness.
12. **`tokenURI(uint256 tokenId)`**: A standard ERC721 function that returns the metadata URI for a given NFT. This URI is designed to be dynamic, pointing to an off-chain service that interprets the NFT's linked `epochId` and potentially other factors to generate its metadata (e.g., image, properties).
13. **`updateOffchainMetadataURI(uint256 tokenId, string memory newURI)`**: Allows an authorized `offchainRendererAddress` to update the specific metadata URI for an individual NFT. This enables true dynamic behavior, where an NFT's visual representation or properties can evolve without re-minting, potentially based on external data or its "evolutionary branch."
14. **`getArtPieceEpochId(uint256 tokenId)`**: Returns the `epochId` that an NFT was minted from, serving as a direct link to its generative origin.

**IV. Treasury & Configuration**
15. **`contributeToTreasury()`**: Allows any user to send Ether to the contract, contributing to the collective's treasury, which can be used for funding off-chain rendering, development, or community initiatives.
16. **`proposeTreasuryWithdrawal(address recipient, uint256 amount, string memory reason)`**: Initiates a proposal for withdrawing funds from the treasury. In this simplified example, this is owner-controlled, but in a full DAO, it would trigger a community vote.
17. **`executeTreasuryWithdrawal(uint256 withdrawalProposalId)`**: Executes an approved treasury withdrawal proposal, sending funds to the specified recipient.
18. **`setMutationStakeAmount(uint256 newAmount)`**: Owner/DAO function to adjust the required ETH stake for new mutation proposals, allowing the community to control the barrier to entry for proposing changes.
19. **`setVotingPeriodDuration(uint256 newDuration)`**: Owner/DAO function to set the duration (in seconds) that mutation proposals are open for voting.
20. **`setEpochAdvanceDelay(uint256 newDelay)`**: Owner/DAO function to set the minimum time (in seconds) that must pass between successive `advanceEpoch` calls, controlling the pace of evolution.

**V. Advanced / Utility**
21. **`setOffchainRendererAddress(address _rendererAddress)`**: Sets an authorized address for an off-chain renderer. This entity is entrusted with calling `updateOffchainMetadataURI` and `registerOffchainDataHash`, acting as a bridge for complex off-chain computation and data.
22. **`revokeOffchainRendererAddress()`**: Revokes the authorization of the currently set off-chain renderer, setting its address to zero.
23. **`registerOffchainDataHash(uint256 epochId, bytes32 dataHash)`**: Allows the authorized off-chain renderer to register a cryptographic hash of the actual generated art data (e.g., image file, video, interactive data) for a specific epoch. This provides on-chain verification of the off-chain output's integrity and provenance.
24. **`getRegisteredOffchainDataHash(uint256 epochId)`**: Retrieves the stored `bytes32` hash of the off-chain generated art data for a given epoch.
25. **`emergencyWithdrawStakes(uint256 proposalId)`**: An emergency owner-only function to force the withdrawal of a proposer's stake in case `finalizeMutation` fails or a proposal gets stuck, ensuring funds are not permanently locked.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title The Evolving Algorithmic Canvas (EAC)
 * @author AI-Generated (concept by user request)
 * @notice A decentralized platform for community-driven generative art evolution and dynamic NFT minting.
 *         The contract manages a series of "Algorithm States" which are parameters for off-chain art generation.
 *         Users propose mutations to these states, vote on their adoption, and mint dynamic NFTs that are tied
 *         to specific historical or current algorithm states, reflecting the collective's creative journey.
 *
 * Outline and Function Summary:
 *
 * I. Core System & Evolution Management
 *    - initializeAlgorithm(bytes memory initialAlgorithmStateData): Sets up the first epoch's algorithm state.
 *    - advanceEpoch(): Moves the project to the next evolutionary epoch, finalizing the previous state.
 *    - getCurrentEpoch(): Returns the current epoch number.
 *    - getAlgorithmState(uint256 epochId): Retrieves the full AlgorithmState struct for a specific epoch.
 *    - getAlgorithmStateData(uint256 epochId): Returns only the raw bytes data of an algorithm state.
 *
 * II. Mutation Proposals & Governance
 *    - proposeMutation(string memory description, bytes memory proposedAlgorithmStateData): Proposes a new algorithm state for voting.
 *    - voteOnMutation(uint256 proposalId, bool support): Casts a vote on a mutation proposal.
 *    - finalizeMutation(uint256 proposalId): Concludes voting, applies successful mutation, and manages stakes.
 *    - getMutationProposal(uint256 proposalId): Retrieves details of a specific proposal.
 *    - cancelMutationProposal(uint256 proposalId): Allows a proposer to cancel their unvoted proposal.
 *
 * III. Dynamic NFT (dNFT) Minting & Management
 *    - mintArtPiece(uint256 epochId): Mints a new dNFT based on the algorithm state of a specified epoch.
 *    - tokenURI(uint256 tokenId): Standard ERC721 function; dynamically generates URI based on the token's epoch and off-chain metadata.
 *    - updateOffchainMetadataURI(uint256 tokenId, string memory newURI): Allows an authorized off-chain renderer to update an individual NFT's metadata URI.
 *    - getArtPieceEpochId(uint256 tokenId): Returns the epoch ID from which an NFT was minted.
 *
 * IV. Treasury & Configuration
 *    - contributeToTreasury(): Allows anyone to contribute Ether to the contract's treasury.
 *    - proposeTreasuryWithdrawal(address recipient, uint256 amount, string memory reason): Initiates a proposal for treasury withdrawal.
 *    - executeTreasuryWithdrawal(uint256 withdrawalProposalId): Executes an approved treasury withdrawal.
 *    - setMutationStakeAmount(uint256 newAmount): Sets the required ETH stake for proposing a mutation.
 *    - setVotingPeriodDuration(uint256 newDuration): Sets the duration (in seconds) for mutation proposal voting.
 *    - setEpochAdvanceDelay(uint256 newDelay): Sets the minimum time (in seconds) that must pass between epoch advances.
 *
 * V. Advanced / Utility
 *    - setOffchainRendererAddress(address _rendererAddress): Sets the authorized address for off-chain metadata updates.
 *    - revokeOffchainRendererAddress(): Revokes the current off-chain renderer's authorization.
 *    - registerOffchainDataHash(uint256 epochId, bytes32 dataHash): Allows off-chain service to register a hash of generated art data for an epoch.
 *    - getRegisteredOffchainDataHash(uint256 epochId): Retrieves the registered off-chain data hash for an epoch.
 *    - emergencyWithdrawStakes(uint256 proposalId): Owner function to force stake withdrawal in case of `finalizeMutation` failure.
 */
contract EvolvingAlgorithmicCanvas is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Structs ---

    struct AlgorithmState {
        uint256 epochId;
        bytes data; // Raw bytes representing algorithm parameters (e.g., JSON, protobuf, custom binary format)
        uint256 timestamp;
        bytes32 offchainDataHash; // Hash of the actual generated art data, registered off-chain
    }

    struct MutationProposal {
        uint256 id;
        uint256 epochId; // The epoch this proposal targets
        address proposer;
        string description;
        bytes proposedAlgorithmStateData;
        uint256 stakeAmount;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool finalized;
        bool approved; // True if passed, False if rejected
        bool stakeWithdrawn;
        mapping(address => bool) hasVoted; // Tracks unique voters for this proposal
    }

    struct TreasuryWithdrawalProposal {
        uint256 id;
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        uint256 proposeTime;
        bool approved; // Simplified for this example (owner approval), could be multi-sig or voting
        bool executed;
    }

    // --- State Variables ---

    Counters.Counter private _epochIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _withdrawalProposalIds;

    uint256 public currentEpoch;
    uint256 public lastEpochAdvanceTime;

    mapping(uint256 => AlgorithmState) public algorithmStates;
    mapping(uint256 => MutationProposal) public mutationProposals;
    mapping(uint256 => uint256) private _artPieceEpochId; // tokenId => epochId it was minted from
    mapping(uint256 => TreasuryWithdrawalProposal) public treasuryWithdrawalProposals;
    // Mapping to store explicit dynamic URIs for tokens, overriding the base URI logic
    mapping(uint256 => string) private _dynamicTokenURIs;

    // Configuration parameters
    uint256 public mutationStakeAmount; // ETH required to propose a mutation
    uint256 public votingPeriodDuration; // Duration in seconds for mutation voting
    uint256 public epochAdvanceDelay; // Minimum delay in seconds between epoch advances

    // Base URI for NFT metadata
    string public baseTokenURI;

    // Authorized address for off-chain renderer to update NFT metadata
    address public offchainRendererAddress;

    // --- Events ---

    event AlgorithmInitialized(uint256 indexed epochId, bytes initialData);
    event EpochAdvanced(uint256 indexed newEpochId, uint256 indexed oldEpochId, uint256 newAlgorithmStateSlotId);
    event MutationProposed(uint256 indexed proposalId, uint256 indexed epochId, address indexed proposer, uint256 stakeAmount);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event MutationFinalized(uint256 indexed proposalId, bool approved, uint256 targetEpochId);
    event MutationCanceled(uint256 indexed proposalId);
    event ArtPieceMinted(uint256 indexed tokenId, address indexed minter, uint256 indexed epochId);
    event OffchainMetadataURIUpdated(uint256 indexed tokenId, string newURI);
    event FundsContributed(address indexed contributor, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount);
    event TreasuryWithdrawalExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event MutationStakeAmountSet(uint256 newAmount);
    event VotingPeriodDurationSet(uint256 newDuration);
    event EpochAdvanceDelaySet(uint256 newDelay);
    event OffchainRendererAddressSet(address indexed rendererAddress);
    event OffchainRendererAddressRevoked(address indexed oldRendererAddress);
    event OffchainDataHashRegistered(uint256 indexed epochId, bytes32 dataHash);

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        baseTokenURI = _baseTokenURI;
        mutationStakeAmount = 0.05 ether; // Default stake for proposals
        votingPeriodDuration = 3 days;    // Default voting period
        epochAdvanceDelay = 1 days;       // Default delay between epochs
        _epochIds.increment(); // Initialize epoch 1
        currentEpoch = _epochIds.current();
    }

    // --- Modifiers ---

    modifier onlyOffchainRenderer() {
        require(msg.sender == offchainRendererAddress, "EAC: Not the authorized renderer");
        _;
    }

    // --- I. Core System & Evolution Management ---

    /**
     * @notice Initializes the very first algorithm state for the canvas.
     * @dev Can only be called once by the contract owner for the initial epoch.
     *      Requires the current epoch's algorithm state to be empty.
     * @param initialAlgorithmStateData The initial parameters for the generative art algorithm.
     */
    function initializeAlgorithm(bytes memory initialAlgorithmStateData) public onlyOwner {
        require(algorithmStates[currentEpoch].data.length == 0, "EAC: Algorithm already initialized for this epoch.");
        
        algorithmStates[currentEpoch] = AlgorithmState({
            epochId: currentEpoch,
            data: initialAlgorithmStateData,
            timestamp: block.timestamp,
            offchainDataHash: 0x0 // No off-chain hash registered yet
        });
        lastEpochAdvanceTime = block.timestamp;
        emit AlgorithmInitialized(currentEpoch, initialAlgorithmStateData);
    }

    /**
     * @notice Advances the project to the next evolutionary epoch.
     * @dev This action finalizes the current algorithm state, making it immutable for future mutations.
     *      It creates a new, initially empty, algorithm state slot for the new epoch to be filled by mutations.
     *      Requires a minimum delay since the last epoch advance.
     */
    function advanceEpoch() public whenNotPaused {
        require(block.timestamp >= lastEpochAdvanceTime + epochAdvanceDelay, "EAC: Not enough time passed since last epoch advance.");
        
        uint256 oldEpoch = currentEpoch;
        _epochIds.increment(); // Increment for the new epoch
        currentEpoch = _epochIds.current();
        
        // Create an empty placeholder for the new epoch's algorithm state.
        // It will be filled by the first winning mutation proposal for this new epoch.
        algorithmStates[currentEpoch] = AlgorithmState({
            epochId: currentEpoch,
            data: "", // Initially empty, to be filled by winning mutation
            timestamp: block.timestamp,
            offchainDataHash: 0x0
        });
        
        lastEpochAdvanceTime = block.timestamp;
        emit EpochAdvanced(currentEpoch, oldEpoch, currentEpoch);
    }

    /**
     * @notice Returns the current active epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Retrieves the full AlgorithmState struct for a specific epoch.
     * @param epochId The ID of the epoch to query.
     */
    function getAlgorithmState(uint256 epochId) public view returns (AlgorithmState memory) {
        require(epochId > 0 && epochId <= currentEpoch, "EAC: Invalid epoch ID.");
        return algorithmStates[epochId];
    }

    /**
     * @notice Returns only the raw bytes data of an algorithm state for a specific epoch.
     * @param epochId The ID of the epoch to query.
     */
    function getAlgorithmStateData(uint256 epochId) public view returns (bytes memory) {
        require(epochId > 0 && epochId <= currentEpoch, "EAC: Invalid epoch ID.");
        return algorithmStates[epochId].data;
    }

    // --- II. Mutation Proposals & Governance ---

    /**
     * @notice Allows users to propose a new algorithm state.
     * @dev Requires a stake in ETH. The proposed state targets the *current* epoch.
     * @param description A short description of the proposed mutation.
     * @param proposedAlgorithmStateData The raw bytes data for the new algorithm state.
     */
    function proposeMutation(string memory description, bytes memory proposedAlgorithmStateData) public payable whenNotPaused {
        require(msg.value >= mutationStakeAmount, "EAC: Insufficient stake amount.");
        require(proposedAlgorithmStateData.length > 0, "EAC: Proposed data cannot be empty.");
        require(algorithmStates[currentEpoch].data.length != 0, "EAC: Current epoch's algorithm not initialized."); // Ensure there's a base to mutate from

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        mutationProposals[newProposalId] = MutationProposal({
            id: newProposalId,
            epochId: currentEpoch, // Proposal targets the current epoch
            proposer: msg.sender,
            description: description,
            proposedAlgorithmStateData: proposedAlgorithmStateData,
            stakeAmount: msg.value,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            finalized: false,
            approved: false,
            stakeWithdrawn: false
        });

        emit MutationProposed(newProposalId, currentEpoch, msg.sender, msg.value);
    }

    /**
     * @notice Casts a vote for or against a mutation proposal.
     * @dev Each address can vote only once per proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes' (for), false for 'no' (against).
     */
    function voteOnMutation(uint256 proposalId, bool support) public whenNotPaused {
        MutationProposal storage proposal = mutationProposals[proposalId];
        require(proposal.id != 0, "EAC: Proposal does not exist.");
        require(block.timestamp < proposal.voteEndTime, "EAC: Voting period has ended.");
        require(!proposal.finalized, "EAC: Proposal already finalized.");
        require(!proposal.hasVoted[msg.sender], "EAC: Already voted on this proposal.");
        require(proposal.epochId == currentEpoch, "EAC: Can only vote on proposals for the current epoch.");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @notice Concludes voting for a proposal, applies the new state if approved, and manages stakes.
     * @dev Can be called by anyone after the voting period ends.
     *      If approved, the new algorithm state data is applied to the current epoch.
     *      If rejected, the proposer's stake is retained by the contract.
     *      This function ensures only one proposal can win for a given epoch, as a new proposal
     *      winning would overwrite previous ones for the same epoch.
     */
    function finalizeMutation(uint256 proposalId) public whenNotPaused {
        MutationProposal storage proposal = mutationProposals[proposalId];
        require(proposal.id != 0, "EAC: Proposal does not exist.");
        require(block.timestamp >= proposal.voteEndTime, "EAC: Voting period has not ended yet.");
        require(!proposal.finalized, "EAC: Proposal already finalized.");
        require(proposal.epochId == currentEpoch, "EAC: Can only finalize proposals for the current epoch.");

        proposal.finalized = true;
        // Simple majority vote: if votesFor > votesAgainst AND there's at least one vote.
        if (proposal.votesFor > proposal.votesAgainst && (proposal.votesFor + proposal.votesAgainst > 0)) {
            proposal.approved = true;
            
            // Apply the new algorithm state to the current epoch.
            // This design allows later successful proposals in the same epoch to overwrite earlier ones.
            // The final state of an epoch is defined by the LAST successful proposal finalized for it.
            algorithmStates[proposal.epochId].data = proposal.proposedAlgorithmStateData;
            algorithmStates[proposal.epochId].timestamp = block.timestamp;
            
            // Return stake to proposer if approved
            (bool success, ) = payable(proposal.proposer).call{value: proposal.stakeAmount}("");
            require(success, "EAC: Failed to return stake to proposer.");
            proposal.stakeWithdrawn = true;
        } else {
            // Proposal rejected or no valid votes; stake is not returned and stays in the contract.
            proposal.approved = false;
        }

        emit MutationFinalized(proposalId, proposal.approved, proposal.epochId);
    }
    
    /**
     * @notice Allows a proposer to cancel their mutation proposal if it hasn't been voted on or finalized.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelMutationProposal(uint256 proposalId) public {
        MutationProposal storage proposal = mutationProposals[proposalId];
        require(proposal.id != 0, "EAC: Proposal does not exist.");
        require(msg.sender == proposal.proposer, "EAC: Only proposer can cancel.");
        require(!proposal.finalized, "EAC: Proposal already finalized.");
        require(proposal.votesFor == 0 && proposal.votesAgainst == 0, "EAC: Cannot cancel, votes have been cast.");

        // Return the staked amount
        (bool success, ) = payable(proposal.proposer).call{value: proposal.stakeAmount}("");
        require(success, "EAC: Failed to return stake.");

        // Mark as canceled and clean up
        proposal.finalized = true; // Prevents further interaction
        proposal.stakeWithdrawn = true;

        emit MutationCanceled(proposalId);
    }


    /**
     * @notice Retrieves details about a specific mutation proposal.
     * @param proposalId The ID of the proposal to query.
     */
    function getMutationProposal(uint256 proposalId) public view returns (
        uint256 id,
        uint256 epochId,
        address proposer,
        string memory description,
        bytes memory proposedAlgorithmStateData,
        uint256 stakeAmount,
        uint256 voteStartTime,
        uint256 voteEndTime,
        uint256 votesFor,
        uint256 votesAgainst,
        bool finalized,
        bool approved,
        bool stakeWithdrawn
    ) {
        MutationProposal storage proposal = mutationProposals[proposalId];
        require(proposal.id != 0, "EAC: Proposal does not exist.");

        return (
            proposal.id,
            proposal.epochId,
            proposal.proposer,
            proposal.description,
            proposal.proposedAlgorithmStateData,
            proposal.stakeAmount,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.finalized,
            proposal.approved,
            proposal.stakeWithdrawn
        );
    }

    // --- III. Dynamic NFT (dNFT) Minting & Management ---

    /**
     * @notice Mints a new dynamic NFT based on the algorithm state of a specified epoch.
     * @dev The NFT's metadata will link to the algorithm state used for its generation.
     * @param epochId The ID of the epoch whose algorithm state should be used for this NFT.
     */
    function mintArtPiece(uint256 epochId) public whenNotPaused returns (uint256) {
        require(epochId > 0 && epochId <= currentEpoch, "EAC: Cannot mint from a future or invalid epoch.");
        require(algorithmStates[epochId].data.length > 0, "EAC: Algorithm state not set for this epoch.");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(msg.sender, newItemId);
        _artPieceEpochId[newItemId] = epochId; // Record which epoch this NFT originated from

        emit ArtPieceMinted(newItemId, msg.sender, epochId);
        return newItemId;
    }

    /**
     * @notice Standard ERC721 function to return the metadata URI for a given token ID.
     * @dev This URI is dynamic. It first checks for an explicitly set dynamic URI for the token.
     *      If none, it constructs a default URI using the `baseTokenURI` combined with `tokenId`
     *      and `epochId`, indicating to an off-chain server how to generate metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory explicitURI = _dynamicTokenURIs[tokenId];
        if (bytes(explicitURI).length > 0) {
            return explicitURI;
        } else {
            // Default behavior: append tokenId and epochId to base URI for off-chain dynamic generation.
            uint256 epochId = _artPieceEpochId[tokenId];
            return string(abi.encodePacked(baseTokenURI, tokenId.toString(), "_epoch_", epochId.toString(), ".json"));
        }
    }

    /**
     * @notice Allows an authorized off-chain renderer to update the base metadata URI for a specific NFT.
     * @dev This enables "dynamic" updates to an NFT's appearance or properties based on external factors
     *      or subsequent off-chain rendering processes without re-minting.
     *      The `newURI` should ideally contain a hash or identifier unique to the updated metadata.
     *      This explicitly sets the URI that `tokenURI` will return for this specific `tokenId`.
     * @param tokenId The ID of the NFT to update.
     * @param newURI The new URI pointing to the updated metadata.
     */
    function updateOffchainMetadataURI(uint256 tokenId, string memory newURI) public onlyOffchainRenderer whenNotPaused {
        require(_exists(tokenId), "EAC: Token does not exist."); // Ensure the token exists
        _dynamicTokenURIs[tokenId] = newURI; // Stores an explicit URI override for this token

        emit OffchainMetadataURIUpdated(tokenId, newURI);
    }
    
    /**
     * @notice Returns the epoch ID from which an NFT was minted.
     * @param tokenId The ID of the NFT.
     */
    function getArtPieceEpochId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "EAC: Token does not exist.");
        return _artPieceEpochId[tokenId];
    }

    // --- IV. Treasury & Configuration ---

    /**
     * @notice Allows anyone to contribute Ether to the contract's treasury.
     */
    function contributeToTreasury() public payable {
        require(msg.value > 0, "EAC: Contribution must be greater than zero.");
        emit FundsContributed(msg.sender, msg.value);
    }

    /**
     * @notice Proposes a withdrawal from the contract's treasury.
     * @dev In this example, this function is owner-controlled, simplifying the DAO complexity.
     *      In a full DAO, this would trigger a community governance vote.
     * @param recipient The address to send funds to.
     * @param amount The amount of ETH to withdraw.
     * @param reason A description for the withdrawal.
     */
    function proposeTreasuryWithdrawal(address recipient, uint256 amount, string memory reason) public onlyOwner {
        require(amount > 0, "EAC: Amount must be greater than zero.");
        require(address(this).balance >= amount, "EAC: Insufficient treasury balance for proposed amount.");

        _withdrawalProposalIds.increment();
        uint256 newProposalId = _withdrawalProposalIds.current();

        treasuryWithdrawalProposals[newProposalId] = TreasuryWithdrawalProposal({
            id: newProposalId,
            proposer: msg.sender,
            recipient: recipient,
            amount: amount,
            reason: reason,
            proposeTime: block.timestamp,
            approved: true, // Auto-approved for owner, simplifying DAO complexity for this exercise
            executed: false
        });

        emit TreasuryWithdrawalProposed(newProposalId, msg.sender, recipient, amount);
    }

    /**
     * @notice Executes an approved treasury withdrawal proposal.
     * @dev This simple version assumes proposals are auto-approved by owner.
     * @param withdrawalProposalId The ID of the withdrawal proposal to execute.
     */
    function executeTreasuryWithdrawal(uint256 withdrawalProposalId) public onlyOwner {
        TreasuryWithdrawalProposal storage proposal = treasuryWithdrawalProposals[withdrawalProposalId];
        require(proposal.id != 0, "EAC: Withdrawal proposal does not exist.");
        require(proposal.approved, "EAC: Withdrawal proposal not approved.");
        require(!proposal.executed, "EAC: Withdrawal proposal already executed.");
        require(address(this).balance >= proposal.amount, "EAC: Insufficient treasury balance for execution.");

        proposal.executed = true;

        (bool success, ) = payable(proposal.recipient).call{value: proposal.amount}("");
        require(success, "EAC: Failed to withdraw funds.");

        emit TreasuryWithdrawalExecuted(withdrawalProposalId, proposal.recipient, proposal.amount);
    }

    /**
     * @notice Owner/DAO sets the required ETH stake for proposing a mutation.
     * @param newAmount The new minimum stake amount in wei.
     */
    function setMutationStakeAmount(uint256 newAmount) public onlyOwner {
        mutationStakeAmount = newAmount;
        emit MutationStakeAmountSet(newAmount);
    }

    /**
     * @notice Owner/DAO sets the duration (in seconds) for mutation proposal voting.
     * @param newDuration The new voting period duration in seconds.
     */
    function setVotingPeriodDuration(uint256 newDuration) public onlyOwner {
        require(newDuration > 0, "EAC: Voting period must be greater than zero.");
        votingPeriodDuration = newDuration;
        emit VotingPeriodDurationSet(newDuration);
    }

    /**
     * @notice Owner/DAO sets the minimum time (in seconds) that must pass between epoch advances.
     * @param newDelay The new epoch advance delay in seconds.
     */
    function setEpochAdvanceDelay(uint256 newDelay) public onlyOwner {
        epochAdvanceDelay = newDelay;
        emit EpochAdvanceDelaySet(newDelay);
    }

    // --- V. Advanced / Utility ---

    /**
     * @notice Sets the authorized address for the off-chain renderer.
     * @dev This address is allowed to call `updateOffchainMetadataURI` and `registerOffchainDataHash`.
     * @param _rendererAddress The address of the off-chain renderer.
     */
    function setOffchainRendererAddress(address _rendererAddress) public onlyOwner {
        require(_rendererAddress != address(0), "EAC: Renderer address cannot be zero.");
        offchainRendererAddress = _rendererAddress;
        emit OffchainRendererAddressSet(_rendererAddress);
    }

    /**
     * @notice Revokes the current off-chain renderer's authorization.
     * @dev Sets the renderer address to zero.
     */
    function revokeOffchainRendererAddress() public onlyOwner {
        address oldRenderer = offchainRendererAddress;
        offchainRendererAddress = address(0);
        emit OffchainRendererAddressRevoked(oldRenderer);
    }

    /**
     * @notice Allows an authorized off-chain service to register a hash of the generated art data
     *         for a specific epoch, ensuring data integrity or providing verifiable art output.
     * @param epochId The ID of the epoch the data hash corresponds to.
     * @param dataHash The keccak256 hash of the off-chain generated art data.
     */
    function registerOffchainDataHash(uint256 epochId, bytes32 dataHash) public onlyOffchainRenderer whenNotPaused {
        require(epochId > 0 && epochId <= currentEpoch, "EAC: Cannot register hash for future or invalid epoch.");
        require(algorithmStates[epochId].data.length > 0, "EAC: No algorithm state for this epoch to register a hash for.");
        
        algorithmStates[epochId].offchainDataHash = dataHash;
        emit OffchainDataHashRegistered(epochId, dataHash);
    }

    /**
     * @notice Retrieves the registered off-chain data hash for an epoch.
     * @param epochId The ID of the epoch to query.
     */
    function getRegisteredOffchainDataHash(uint256 epochId) public view returns (bytes32) {
        require(epochId > 0 && epochId <= currentEpoch, "EAC: Invalid epoch ID.");
        return algorithmStates[epochId].offchainDataHash;
    }

    /**
     * @notice Owner function to force a stake withdrawal in case of an issue with `finalizeMutation`.
     * @dev This is an emergency function to recover locked funds due to unforeseen issues.
     *      It bypasses normal finalization logic and only focuses on stake recovery.
     * @param proposalId The ID of the proposal whose stake needs to be withdrawn.
     */
    function emergencyWithdrawStakes(uint256 proposalId) public onlyOwner {
        MutationProposal storage proposal = mutationProposals[proposalId];
        require(proposal.id != 0, "EAC: Proposal does not exist.");
        require(!proposal.stakeWithdrawn, "EAC: Stake already withdrawn.");

        (bool success, ) = payable(proposal.proposer).call{value: proposal.stakeAmount}("");
        require(success, "EAC: Failed to return stake.");
        proposal.stakeWithdrawn = true;
    }

    // --- Pausable override functions ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

```