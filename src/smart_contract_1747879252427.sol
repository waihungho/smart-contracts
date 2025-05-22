Okay, let's create a smart contract that embodies community-influenced generative NFT art with on-chain parameter management and a decentralized voting system. This combines NFTs, governance, and dynamic metadata concepts in a unique way.

We will call the contract `NFTArtChain`.

---

### NFTArtChain Smart Contract

**Concept:**
A platform for creating generative art NFTs where the parameters used for generation are decided by the community (specifically, the NFT holders) through an on-chain voting mechanism. Each minted NFT is associated with the set of parameters active at the time of its creation, effectively representing a specific "epoch" or "generation" of art.

**Advanced/Creative Concepts:**
1.  **On-Chain Parameter Governance:** The core generative art parameters are stored and managed directly on the blockchain.
2.  **Epoch-Based Generation:** NFTs are minted using parameters from a specific historical or current epoch.
3.  **NFT Holder Voting:** Voting power in the parameter proposals is tied to holding the contract's NFTs.
4.  **Dynamic Metadata (Conceptual):** The `tokenURI` needs to resolve parameters *from* the chain for a specific epoch/token, allowing external renderers to create dynamic metadata/art based on the *current* on-chain state or the historical state of the token's epoch.
5.  **Proposal System:** Structured process for suggesting and voting on new parameter sets.
6.  **Staked Voting Power (Optional but included):** Requiring a minimum *stake* of NFTs to propose or vote.

**Outline:**
1.  **Standard ERC721 & Enumerable:** Basic NFT functionality.
2.  **Ownership & Access Control:** Owner manages crucial setup, but key decisions (parameters) are decentralized.
3.  **Contract State & Lifecycle:** Manages different phases (Genesis, Proposal, Voting, Generation, Paused).
4.  **Generative Parameters:** Structs and storage for current and historical parameters.
5.  **Parameter Proposal System:** Structs, mappings, and functions for creating, viewing, and managing proposals.
6.  **Voting Mechanism:** Functions for casting votes and tallying results.
7.  **Epoch Management:** Associating minted tokens with specific parameter sets/epochs.
8.  **NFT Minting:** Public function to mint new NFTs based on the current epoch's parameters.
9.  **Metadata Handling:** Custom `tokenURI` implementation.
10. **Utility:** Fund withdrawal, burning, configuration.

**Function Summary (Minimum 20 Functions):**

**ERC721 & Enumerable (Standard - 9 functions):**
*   `balanceOf(address owner)`: Returns number of NFTs owned by an address.
*   `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT.
*   `approve(address to, uint256 tokenId)`: Approves another address to transfer a specific NFT.
*   `getApproved(uint256 tokenId)`: Returns the approved address for an NFT.
*   `setApprovalForAll(address operator, bool approved)`: Approves or disapproves an operator for all user's NFTs.
*   `isApprovedForAll(address owner, address operator)`: Checks if an address is an authorized operator.
*   `totalSupply()`: Returns total number of NFTs minted. (From ERC721Enumerable)
*   `tokenByIndex(uint256 index)`: Returns the token ID at a specific index. (From ERC721Enumerable)
*   `tokenOfOwnerByIndex(address owner, uint256 index)`: Returns the token ID at an index for a specific owner. (From ERC721Enumerable)

**Core Contract Logic (Custom - 20+ functions):**
10. `constructor(...)`: Initializes the contract, sets base URI, max supply, fee, and initial phase.
11. `setInitialParameters(GenerativeParams calldata _initialParams)`: Owner sets the very first parameters for the genesis epoch.
12. `proposeParameters(GenerativeParams calldata _newParams, string calldata _description, uint256 _duration)`: Allows eligible holders to propose a new set of parameters for voting. Requires NFT stake.
13. `getProposalDetails(uint256 _proposalId)`: View details of a specific parameter proposal.
14. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible holders to vote on an active proposal (yes/no). Requires NFT stake.
15. `getVotingPower(address _voter)`: Calculates the voting power for an address (based on their NFT holdings).
16. `executeProposalOutcome(uint256 _proposalId)`: Public function to tally votes for a proposal after its deadline and potentially apply the new parameters (creating a new epoch) if passed. Reverts staked NFTs.
17. `getCurrentParameters()`: View the parameters currently active for new mints.
18. `getEpochParameters(uint256 _epochId)`: View the parameters associated with a specific historical epoch.
19. `getCurrentEpochId()`: View the ID of the epoch currently used for minting.
20. `mintNFT()`: Mints a new NFT using the parameters of the *current* epoch. Requires payment.
21. `tokenURI(uint256 tokenId)`: Returns the URI pointing to the metadata for a token. This URI should contain information allowing a renderer to fetch parameters for the token's associated epoch.
22. `setBaseURI(string calldata _newBaseURI)`: Owner updates the base URI for metadata.
23. `withdrawFunds()`: Owner withdraws collected minting fees.
24. `burnNFT(uint256 _tokenId)`: Allows an NFT owner to burn their token (e.g., to recover stake or for future mechanics).
25. `transitionToNextPhase()`: Owner transitions the contract to the next logical phase (e.g., from Proposal to Voting, or Voting to Generation). Needs careful implementation logic.
26. `getCurrentPhase()`: View the current operational phase of the contract.
27. `setMinVotingNFTStake(uint256 _stakeAmount)`: Owner sets the minimum number of NFTs required to cast a vote.
28. `setMinProposalNFTStake(uint256 _stakeAmount)`: Owner sets the minimum number of NFTs required to submit a proposal.
29. `getMinVotingNFTStake()`: View the minimum stake required to vote.
30. `getMinProposalNFTStake()`: View the minimum stake required to propose.
31. `getProposalVoteResult(uint256 _proposalId)`: View the current vote counts for a proposal before execution.
32. `isProposalActive(uint256 _proposalId)`: Checks if a proposal is currently in its voting period.
33. `getProposalProposer(uint256 _proposalId)`: View the address that proposed a specific proposal.

*(Total Functions: 9 standard + 24 custom = 33 functions. This meets the requirement of at least 20 custom/interesting functions beyond the basic ERC721 interface).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- NFTArtChain Smart Contract ---
// Concept:
// A platform for creating generative art NFTs where the parameters used for generation are decided by the community
// (specifically, the NFT holders) through an on-chain voting mechanism. Each minted NFT is associated with the set of
// parameters active at the time of its creation, effectively representing a specific "epoch" or "generation" of art.
//
// Advanced/Creative Concepts:
// 1. On-Chain Parameter Governance: Generative art parameters stored and managed on-chain.
// 2. Epoch-Based Generation: NFTs linked to specific historical parameter sets (epochs).
// 3. NFT Holder Voting: Voting power tied to NFT ownership.
// 4. Dynamic Metadata (Conceptual): tokenURI resolves parameters from the chain for external rendering.
// 5. Proposal System: Structured process for new parameter sets.
// 6. Staked Voting Power: Minimum NFT stake required for proposing/voting.
//
// Outline:
// 1. Standard ERC721 & Enumerable Base
// 2. Ownership & Access Control
// 3. Contract State & Lifecycle (Phases)
// 4. Generative Parameters & Proposals
// 5. Voting System
// 6. NFT Minting
// 7. Metadata Handling
// 8. Utility & Configuration
// 9. Epoch Management

// Function Summary:
// ERC721 & Enumerable (Standard):
// - balanceOf(address owner): Number of NFTs owned.
// - ownerOf(uint256 tokenId): Owner of an NFT.
// - approve(address to, uint256 tokenId): Approve transfer.
// - getApproved(uint256 tokenId): Approved address for NFT.
// - setApprovalForAll(address operator, bool approved): Operator approval for all NFTs.
// - isApprovedForAll(address owner, address operator): Check operator approval.
// - totalSupply(): Total minted NFTs.
// - tokenByIndex(uint256 index): Token ID by index.
// - tokenOfOwnerByIndex(address owner, uint256 index): Token ID by index for owner.
//
// Core Contract Logic (Custom):
// 1. constructor(...): Initializes contract.
// 2. setInitialParameters(GenerativeParams calldata _initialParams): Owner sets genesis parameters.
// 3. proposeParameters(GenerativeParams calldata _newParams, string calldata _description, uint256 _duration): Holder proposes new parameters.
// 4. getProposalDetails(uint256 _proposalId): View proposal info.
// 5. voteOnProposal(uint256 _proposalId, bool _support): Holder votes on proposal.
// 6. getVotingPower(address _voter): Calculate voting power (NFT count).
// 7. executeProposalOutcome(uint256 _proposalId): Tally votes and apply parameters if passed.
// 8. getCurrentParameters(): View current active parameters.
// 9. getEpochParameters(uint256 _epochId): View historical epoch parameters.
// 10. getCurrentEpochId(): View current epoch ID.
// 11. mintNFT(): Mints NFT based on current epoch parameters.
// 12. tokenURI(uint256 tokenId): Custom metadata URI resolving epoch parameters.
// 13. setBaseURI(string calldata _newBaseURI): Owner updates metadata base URI.
// 14. withdrawFunds(): Owner withdraws minting fees.
// 15. burnNFT(uint256 _tokenId): Allows owner to burn an NFT.
// 16. transitionToNextPhase(): Owner advances contract phase.
// 17. getCurrentPhase(): View current contract phase.
// 18. setMinVotingNFTStake(uint256 _stakeAmount): Owner sets min NFTs for voting.
// 19. setMinProposalNFTStake(uint256 _stakeAmount): Owner sets min NFTs for proposing.
// 20. getMinVotingNFTStake(): View min NFTs for voting.
// 21. getMinProposalNFTStake(): View min NFTs for proposing.
// 22. getProposalVoteResult(uint256 _proposalId): View current vote counts.
// 23. isProposalActive(uint256 _proposalId): Check if proposal is active.
// 24. getProposalProposer(uint256 _proposalId): View proposal creator.

contract NFTArtChain is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _epochIdCounter;

    // --- State Management ---
    enum ContractPhase { Genesis, ParameterProposal, Voting, Generation, Paused }
    ContractPhase public currentPhase;

    // --- Generative Parameters ---
    // Example parameter struct - customize heavily for your art generation logic
    struct GenerativeParams {
        uint8 shapeComplexity; // e.g., 1-10
        string primaryColorHex; // e.g., "#FF0000"
        string secondaryColorHex;
        uint16 seedOffset; // Used to influence randomness in off-chain generation
        // Add more parameters as needed...
    }

    GenerativeParams private _currentParameters;

    // Mapping from epoch ID to the parameters used in that epoch
    mapping(uint256 => GenerativeParams) private _epochParameters;

    // Mapping from token ID to the epoch ID it belongs to
    mapping(uint256 => uint256) private _tokenEpoch;

    // --- Parameter Proposal System ---
    struct ParameterProposal {
        address proposer;
        GenerativeParams newParams;
        string description;
        uint256 creationBlock;
        uint256 votingDeadlineBlock; // Block number deadline
        uint256 yesVotes;
        uint256 noVotes;
        bool executed; // True if outcome has been processed
    }

    mapping(uint256 => ParameterProposal) private _proposals;

    // Mapping to track which addresses have voted on which proposal
    mapping(uint256 => mapping(address => bool)) private _hasVoted;

    // Minimum NFT holdings required to propose or vote
    uint256 public minVotingNFTStake = 1; // Default 1 NFT
    uint256 public minProposalNFTStake = 2; // Default 2 NFTs

    // --- Minting Configuration ---
    uint256 public mintingFee = 0.05 ether; // Example fee
    uint256 public maxSupply = 1000; // Example max supply

    // --- Metadata Configuration ---
    string private _baseTokenURI;

    // --- Events ---
    event PhaseTransitioned(ContractPhase indexed oldPhase, ContractPhase indexed newPhase);
    event InitialParametersSet(GenerativeParams params);
    event ParameterProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 deadlineBlock);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed, uint256 newEpochId);
    event NFTMinted(uint256 indexed tokenId, address indexed minter, uint256 indexed epochId);
    event BaseURISet(string newBaseURI);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event NFTBurned(uint256 indexed tokenId, address indexed owner);
    event MinVotingStakeSet(uint256 newStake);
    event MinProposalStakeSet(uint256 newStake);

    // --- Modifiers ---
    modifier whenPhaseIs(ContractPhase _phase) {
        require(currentPhase == _phase, "NFTAC: Not in the correct phase");
        _;
    }

    modifier whenPhaseIsNot(ContractPhase _phase) {
        require(currentPhase != _phase, "NFTAC: Cannot perform action in this phase");
        _;
    }

    modifier onlyNFTHolders() {
         require(balanceOf(msg.sender) > 0, "NFTAC: Must hold an NFT");
         _;
    }

     modifier hasMinVotingStake(address _voter) {
        require(balanceOf(_voter) >= minVotingNFTStake, "NFTAC: Not enough NFT stake to vote");
        _;
    }

     modifier hasMinProposalStake(address _proposer) {
        require(balanceOf(_proposer) >= minProposalNFTStake, "NFTAC: Not enough NFT stake to propose");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory initialBaseURI) ERC721(name, symbol) Ownable(msg.sender) {
        _baseTokenURI = initialBaseURI;
        currentPhase = ContractPhase.Genesis; // Start in Genesis phase
        _epochIdCounter.increment(); // Start epoch IDs from 1
    }

    // --- Access Control & Utility ---
    /// @notice Allows the owner to set the initial generative parameters for the genesis epoch.
    /// @param _initialParams The initial set of parameters.
    function setInitialParameters(GenerativeParams calldata _initialParams) external onlyOwner whenPhaseIs(ContractPhase.Genesis) {
        _currentParameters = _initialParams;
        // Store genesis parameters as epoch 1
        _epochParameters[1] = _initialParams;
        emit InitialParametersSet(_initialParams);
        // Optionally transition phase here, or use transitionToNextPhase
    }

    /// @notice Allows the owner to set the minimum NFT stake required to vote on proposals.
    /// @param _stakeAmount The minimum number of NFTs.
    function setMinVotingNFTStake(uint256 _stakeAmount) external onlyOwner {
        minVotingNFTStake = _stakeAmount;
        emit MinVotingStakeSet(_stakeAmount);
    }

    /// @notice Allows the owner to set the minimum NFT stake required to submit a proposal.
    /// @param _stakeAmount The minimum number of NFTs.
    function setMinProposalNFTStake(uint256 _stakeAmount) external onlyOwner {
        minProposalNFTStake = _stakeAmount;
        emit MinProposalStakeSet(_stakeAmount);
    }

    /// @notice View the minimum NFT stake required to cast a vote.
    /// @return The minimum number of NFTs.
    function getMinVotingNFTStake() external view returns (uint256) {
        return minVotingNFTStake;
    }

    /// @notice View the minimum NFT stake required to submit a proposal.
    /// @return The minimum number of NFTs.
    function getMinProposalNFTStake() external view returns (uint256) {
        return minProposalNFTStake;
    }


    /// @notice Allows the owner to advance the contract to the next logical phase.
    function transitionToNextPhase() external onlyOwner {
        if (currentPhase == ContractPhase.Genesis) {
            // After genesis params are set, move to proposal phase
            currentPhase = ContractPhase.ParameterProposal;
        } else if (currentPhase == ContractPhase.ParameterProposal) {
            // After proposal period (externally managed), move to voting
            currentPhase = ContractPhase.Voting;
        } else if (currentPhase == ContractPhase.Voting) {
             // After voting period (externally managed), move to generation
            currentPhase = ContractPhase.Generation;
        } else if (currentPhase == ContractPhase.Generation) {
             // After a generation period, loop back to parameter proposal
            currentPhase = ContractPhase.ParameterProposal;
        } else if (currentPhase == ContractPhase.Paused) {
            // Paused can potentially go back to any phase, owner decides
            // For simplicity, require owner to specify target phase from Paused
            revert("NFTAC: Specify target phase from Paused");
        }
        // Paused state transition handled separately or by another function
        emit PhaseTransitioned(currentPhase, currentPhase); // Note: oldPhase is currentPhase before update
    }

     /// @notice Allows the owner to pause the contract.
    function pauseContract() external onlyOwner whenPhaseIsNot(ContractPhase.Paused) {
        ContractPhase oldPhase = currentPhase;
        currentPhase = ContractPhase.Paused;
        emit PhaseTransitioned(oldPhase, ContractPhase.Paused);
    }

    /// @notice Allows the owner to unpause the contract and set the target phase.
    /// @param _targetPhase The phase to transition to after unpausing.
    function unpauseContract(ContractPhase _targetPhase) external onlyOwner whenPhaseIs(ContractPhase.Paused) {
         require(_targetPhase != ContractPhase.Paused, "NFTAC: Cannot unpause to Paused phase");
         currentPhase = _targetPhase;
         emit PhaseTransitioned(ContractPhase.Paused, currentPhase);
    }


    /// @notice View the current operational phase of the contract.
    /// @return The current phase enum.
    function getCurrentPhase() external view returns (ContractPhase) {
        return currentPhase;
    }

    /// @notice Allows the owner to withdraw collected minting fees.
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "NFTAC: No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "NFTAC: Fund withdrawal failed");
        emit FundsWithdrawn(owner(), balance);
    }

    /// @notice Allows an NFT owner to burn their token.
    /// @param _tokenId The ID of the token to burn.
    function burnNFT(uint256 _tokenId) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "NFTAC: Not approved or owner");
        address owner_ = ownerOf(_tokenId); // Get owner before burning
        _burn(_tokenId);
        emit NFTBurned(_tokenId, owner_);
    }

    // --- Parameter Proposals ---
    /// @notice Allows eligible NFT holders to propose a new set of generative parameters.
    /// @param _newParams The proposed new parameters.
    /// @param _description A description of the proposal.
    /// @param _duration The duration of the voting period in blocks.
    function proposeParameters(GenerativeParams calldata _newParams, string calldata _description, uint256 _duration)
        external
        whenPhaseIs(ContractPhase.ParameterProposal)
        hasMinProposalStake(msg.sender)
    {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        require(_duration > 0, "NFTAC: Voting duration must be > 0");

        _proposals[proposalId] = ParameterProposal({
            proposer: msg.sender,
            newParams: _newParams,
            description: _description,
            creationBlock: block.number,
            votingDeadlineBlock: block.number + _duration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ParameterProposalCreated(proposalId, msg.sender, block.number + _duration);
        // Note: Proposer could automatically vote YES here if desired
    }

    /// @notice View the details of a specific parameter proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return proposal details.
    function getProposalDetails(uint256 _proposalId) external view returns (ParameterProposal memory) {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "NFTAC: Invalid proposal ID");
        return _proposals[_proposalId];
    }

    /// @notice View the address that created a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The proposer's address.
    function getProposalProposer(uint256 _proposalId) external view returns (address) {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "NFTAC: Invalid proposal ID");
        return _proposals[_proposalId].proposer;
    }


    /// @notice Check if a proposal is currently in its active voting period.
    /// @param _proposalId The ID of the proposal.
    /// @return True if active, false otherwise.
    function isProposalActive(uint256 _proposalId) public view returns (bool) {
         require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "NFTAC: Invalid proposal ID");
         ParameterProposal storage proposal = _proposals[_proposalId];
         return !proposal.executed && block.number <= proposal.votingDeadlineBlock;
    }

    /// @notice View the current vote counts for a proposal before execution.
    /// @param _proposalId The ID of the proposal.
    /// @return yesVotes The number of 'yes' votes.
    /// @return noVotes The number of 'no' votes.
    function getProposalVoteResult(uint256 _proposalId) external view returns (uint256 yesVotes, uint256 noVotes) {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "NFTAC: Invalid proposal ID");
        ParameterProposal storage proposal = _proposals[_proposalId];
        return (proposal.yesVotes, proposal.noVotes);
    }


    // --- Voting Mechanism ---
    /// @notice Allows eligible NFT holders to vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        whenPhaseIs(ContractPhase.Voting)
        hasMinVotingStake(msg.sender)
    {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "NFTAC: Invalid proposal ID");
        ParameterProposal storage proposal = _proposals[_proposalId];
        require(!proposal.executed, "NFTAC: Proposal already executed");
        require(block.number <= proposal.votingDeadlineBlock, "NFTAC: Voting period has ended");
        require(!_hasVoted[_proposalId][msg.sender], "NFTAC: Already voted on this proposal");

        _hasVoted[_proposalId][msg.sender] = true;

        // Calculate voting power (simply number of NFTs held)
        uint256 power = balanceOf(msg.sender);
        require(power >= minVotingNFTStake, "NFTAC: Not enough NFT stake to cast vote"); // Double check stake

        if (_support) {
            proposal.yesVotes += power;
        } else {
            proposal.noVotes += power;
        }

        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    /// @notice Calculates the voting power for an address based on their current NFT holdings.
    /// @param _voter The address to check.
    /// @return The number of NFTs held by the address.
    function getVotingPower(address _voter) external view returns (uint256) {
        return balanceOf(_voter);
    }

    /// @notice Public function to execute the outcome of a proposal after its deadline.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposalOutcome(uint256 _proposalId) external whenPhaseIsNot(ContractPhase.Paused) {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "NFTAC: Invalid proposal ID");
        ParameterProposal storage proposal = _proposals[_proposalId];
        require(!proposal.executed, "NFTAC: Proposal already executed");
        require(block.number > proposal.votingDeadlineBlock, "NFTAC: Voting period not ended yet");

        proposal.executed = true;

        // Define success threshold - e.g., simple majority of votes cast
        // A more complex system could require minimum turnout, supermajority, etc.
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        bool passed = false;
        uint256 newEpochId = 0; // Default 0 if proposal fails

        if (totalVotes > 0 && proposal.yesVotes > proposal.noVotes) {
            passed = true;
            // Apply the new parameters and create a new epoch
            _currentParameters = proposal.newParams;
            _epochIdCounter.increment();
            newEpochId = _epochIdCounter.current();
            _epochParameters[newEpochId] = _currentParameters;
        }

        // Note: In a real system, unstaking logic would go here if NFTs were staked
        // instead of just checking balance.

        emit ProposalExecuted(_proposalId, passed, newEpochId);
    }

    // --- Epoch Management ---
     /// @notice View the ID of the epoch currently used for minting.
     /// @return The current epoch ID.
    function getCurrentEpochId() public view returns (uint256) {
        return _epochIdCounter.current();
    }

    /// @notice View the parameters associated with a specific historical epoch.
    /// @param _epochId The ID of the epoch.
    /// @return The parameters for the specified epoch.
    function getEpochParameters(uint256 _epochId) public view returns (GenerativeParams memory) {
        require(_epochId > 0 && _epochId <= _epochIdCounter.current(), "NFTAC: Invalid epoch ID");
        return _epochParameters[_epochId];
    }

    // --- NFT Minting ---
    /// @notice Mints a new NFT using the parameters of the *current* epoch.
    function mintNFT() external payable whenPhaseIs(ContractPhase.Generation) {
        require(currentPhase == ContractPhase.Generation, "NFTAC: Minting is not in the Generation phase");
        require(msg.value >= mintingFee, "NFTAC: Insufficient ETH");
        require(_tokenIdCounter.current() < maxSupply, "NFTAC: Max supply reached");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Associate the new token with the current epoch's parameters
        _tokenEpoch[newItemId] = _epochIdCounter.current();

        _safeMint(msg.sender, newItemId);

        emit NFTMinted(newItemId, msg.sender, _epochIdCounter.current());
    }

     /// @notice Allows the owner to set the minting fee.
     /// @param _fee The new minting fee in wei.
    function setMintingFee(uint256 _fee) external onlyOwner {
        mintingFee = _fee;
    }

    /// @notice Allows the owner to set the maximum supply of NFTs.
    /// @param _maxSupply The new maximum supply.
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= _tokenIdCounter.current(), "NFTAC: Max supply cannot be less than current supply");
        maxSupply = _maxSupply;
    }

    // --- Metadata Handling ---
    /// @notice Sets the base URI for token metadata.
    /// @param _newBaseURI The new base URI.
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
        emit BaseURISet(_newBaseURI);
    }

    /// @inheritdoc ERC721
    /// @dev Custom implementation to include epoch ID in the URI for dynamic metadata.
    /// The off-chain service at the base URI needs to handle URIs like `baseURI/token/tokenId/epoch/epochId`
    /// or just `baseURI/token/tokenId` and internally look up the epoch using token id.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 epochId = _tokenEpoch[tokenId];
        // Construct URI: baseURI/token/tokenId/epoch/epochId
        // Requires string concatenation, which can be complex/gas-heavy.
        // A simpler approach for the contract is just baseURI, and the off-chain service
        // queries the contract for tokenEpoch(tokenId).
        // Let's stick to a simpler URI and let the off-chain service do the lookup.
        // However, to demonstrate including on-chain data in the URI hint:
        // We can pass token ID and epoch ID.

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
             return ""; // Return empty string if base URI is not set
        }

        // Minimal string concatenation needed on-chain: baseURI + tokenId
        // The external service will need to call tokenEpoch(tokenId) itself.
        // Or, a more complex URI that hints at epoch: baseURI/tokenId?epoch=epochId
        // Let's use the simpler structure and assume the external service is smart.

        return string(abi.encodePacked(base, "/", toString(tokenId)));
        // Alternative hinting epoch: return string(abi.encodePacked(base, "/", toString(tokenId), "?epoch=", toString(epochId)));
        // This requires SafeCast or similar if using older Solidity, but 0.8+ has toString.
    }

    // Helper function for tokenURI string conversion
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }


    // --- View Functions ---
     /// @notice View the current active generative parameters.
     /// @return The current parameters.
    function getCurrentParameters() external view returns (GenerativeParams memory) {
        return _currentParameters;
    }

    // --- Internal/Override functions ---
     // The following ERC721 standard functions are inherited and public via ERC721Enumerable:
     // balanceOf(address owner)
     // ownerOf(uint256 tokenId)
     // approve(address to, uint256 tokenId)
     // getApproved(uint256 tokenId)
     // setApprovalForAll(address operator, bool approved)
     // isApprovedForAll(address owner, address operator)
     // totalSupply()
     // tokenByIndex(uint256 index)
     // tokenOfOwnerByIndex(address owner, uint256 index)
     // transferFrom(address from, address to, uint256 tokenId) - Internal, but used by safeTransferFrom etc.
     // safeTransferFrom(address from, address to, uint256 tokenId) - Internal, but used by safeTransferFrom etc.
     // safeTransferFrom(address from, address to, uint256 tokenId, bytes data) - Internal

     // _burn and _safeMint are also inherited internal functions.

     // total function count including inherited public ones that are commonly considered part of the interface:
     // 9 (standard ERC721Enumerable) + 24 (custom listed above) = 33 functions.

}
```