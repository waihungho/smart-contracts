Okay, let's design a smart contract that manages dynamic, evolving digital entities ("ChronoMorphs") where their traits can change over time or based on community-governed proposals. This incorporates ERC721 (NFTs), on-chain state evolution, and a form of time-weighted governance.

**Concept:** ChronoMorphs are NFTs with mutable traits. They can "mutate" or "evolve" based on time, owner interaction, or community-approved events/parameters. A decentralized governance system allows token holders to propose and vote on changes to the contract's parameters or trigger system-wide events, with voting power potentially weighted by how long they've held ChronoMorphs.

**Advanced/Trendy Concepts Used:**
1.  **Dynamic NFTs:** Traits stored on-chain that change.
2.  **On-Chain Generative Elements:** Traits can be generated/mutated based on current state and (pseudo)randomness.
3.  **Decentralized Governance:** A proposal and voting system for parameter changes or actions.
4.  **Time-Weighted Voting:** Voting power derived from holding duration.
5.  **Call Data Execution:** Governance can trigger specific function calls.
6.  **Simulated Evolution/Mutation:** A simple on-chain mechanism for state transitions.
7.  **Pausable/Emergency Stop:** Standard but necessary control.
8.  **Role-Based Access Control (Implicit/Via Ownership/Governance):** Certain actions require ownership, others require governance approval.
9.  **On-Chain State Management:** Managing complex data structures for traits and proposals.
10. **Potential for On-Chain Randomness Integration:** (Placeholder shown with blockhash, would use VRF in production).

---

**Outline and Function Summary:**

**Contract Name:** `ChronoMorphs`

**Inherits:** ERC721, Ownable, Pausable

**Core Data Structures:**
*   `ChronoMorphData`: Struct holding traits (generation, stats, name, last mutation timestamp).
*   `Proposal`: Struct holding proposal details (description, proposer, state, votes, period, target call data).

**Enums:**
*   `ProposalState`: `Pending`, `Active`, `Succeeded`, `Failed`, `Executed`, `Canceled`.

**Key State Variables:**
*   Mappings for ChronoMorph data, proposal data, voting status.
*   System parameters: `mutationRate`, `evolutionThreshold`, `votingPeriod`, `quorumPercentage`, `proposalFee`.
*   Counters for token IDs and proposal IDs.
*   Mapping `tokenId => acquiredTimestamp` for time-weighted voting.

**Functions (20+ Distinct Logic Functions):**

1.  `constructor(string name, string symbol, uint256 initialSupply)`: Initializes contract, mints genesis tokens.
2.  `mintGenesisMorph(address recipient)`: Mints a new ChronoMorph with initial random traits (owner/admin only).
3.  `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Internal hook to update acquisition time on transfer.
4.  `getMorphData(uint256 tokenId)`: Reads ChronoMorph traits. (View)
5.  `getMorphAcquisitionTime(uint256 tokenId)`: Reads when a token was acquired. (View)
6.  `getVotingPower(address voter)`: Calculates time-weighted voting power for an address. (View)
7.  `canMutate(uint256 tokenId)`: Checks if a morph is ready to mutate based on time and rate. (View)
8.  `mutateMorph(uint256 tokenId)`: Triggers a random trait change for a ChronoMorph if conditions met (owner/approved only).
9.  `canEvolve(uint256 tokenId)`: Checks if a morph is ready for evolution based on generation and threshold. (View)
10. `evolveMorph(uint256 tokenId)`: Triggers a significant trait change for a ChronoMorph if conditions met (owner/approved only).
11. `breedMorphs(uint256 parent1TokenId, uint256 parent2TokenId)`: Creates a new morph by combining parent traits (owners only, burns parents or requires fee?). Let's add a fee and *not* burn.
12. `proposeChange(string description, bytes callData)`: Allows a user with voting power to propose a contract parameter change or action. Requires fee.
13. `getProposal(uint256 proposalId)`: Reads proposal details. (View)
14. `voteOnProposal(uint256 proposalId, bool support)`: Casts a vote on an active proposal based on voting power.
15. `getVoterStatus(uint256 proposalId, address voter)`: Checks if a user has voted on a proposal. (View)
16. `executeProposal(uint256 proposalId)`: Executes the target function call if the proposal succeeded.
17. `cancelProposal(uint256 proposalId)`: Allows proposer or owner to cancel a pending/active proposal.
18. `getProposalState(uint256 proposalId)`: Gets the current calculated state of a proposal. (View)
19. `setMutationRate(uint256 rate)`: Admin function to change the mutation rate.
20. `setEvolutionThreshold(uint256 threshold)`: Admin function to change the evolution threshold.
21. `setVotingPeriod(uint256 duration)`: Admin function to change the voting period.
22. `setQuorumPercentage(uint256 percentage)`: Admin function to change the quorum.
23. `setProposalFee(uint256 fee)`: Admin function to change the proposal fee.
24. `withdrawFees()`: Admin function to withdraw accumulated proposal fees.
25. `setPaused(bool state)`: Pauses/unpauses the contract (owner only, provided by Pausable).
26. `tokenURI(uint256 tokenId)`: Returns metadata URI (standard ERC721, but can be dynamic based on traits). (View)
27. `updateMorphName(uint256 tokenId, string newName)`: Allows owner to change the name trait.
28. `getTotalVotingPower()`: Calculates the total potential voting power in the system. (View)
29. `getRandomNumber(uint256 seed)`: Internal helper for generating pseudo-random numbers using block hash (not secure for critical outcomes!).
30. `getTokenIdsOwnedBy(address owner)`: Helper function to list token IDs owned by an address (can be gas-intensive). (View)

*(Note: Functions like `balanceOf`, `ownerOf`, `transferFrom`, etc., are standard ERC721 and are implicitly included via inheritance but not counted in the 20+ *distinct conceptual* functions list above.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Not strictly needed for this example, but good practice
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary ---
// Contract Name: ChronoMorphs
// Inherits: ERC721, Ownable, Pausable
// Core Data Structures:
//   - ChronoMorphData: Struct holding traits (generation, stats, name, last mutation timestamp).
//   - Proposal: Struct holding proposal details (description, proposer, state, votes, period, target call data).
// Enums:
//   - ProposalState: Pending, Active, Succeeded, Failed, Executed, Canceled.
// Key State Variables:
//   - Mappings for ChronoMorph data, proposal data, voting status.
//   - System parameters: mutationRate, evolutionThreshold, votingPeriod, quorumPercentage, proposalFee.
//   - Counters for token IDs and proposal IDs.
//   - Mapping tokenId => acquiredTimestamp for time-weighted voting.
// Functions (20+ Distinct Logic Functions):
//  1. constructor(string name, string symbol, uint256 initialSupply): Initializes contract, mints genesis tokens.
//  2. mintGenesisMorph(address recipient): Mints a new ChronoMorph with initial random traits (owner/admin only).
//  3. _beforeTokenTransfer(address from, address to, uint256 tokenId): Internal hook to update acquisition time on transfer.
//  4. getMorphData(uint256 tokenId): Reads ChronoMorph traits. (View)
//  5. getMorphAcquisitionTime(uint256 tokenId): Reads when a token was acquired. (View)
//  6. getVotingPower(address voter): Calculates time-weighted voting power for an address. (View)
//  7. canMutate(uint256 tokenId): Checks if a morph is ready to mutate based on time and rate. (View)
//  8. mutateMorph(uint256 tokenId): Triggers a random trait change for a ChronoMorph if conditions met (owner/approved only).
//  9. canEvolve(uint256 tokenId): Checks if a morph is ready for evolution based on generation and threshold. (View)
// 10. evolveMorph(uint256 tokenId): Triggers a significant trait change for a ChronoMorph if conditions met (owner/approved only).
// 11. breedMorphs(uint256 parent1TokenId, uint256 parent2TokenId): Creates a new morph by combining parent traits (owners only, requires fee).
// 12. proposeChange(string description, bytes callData): Allows a user with voting power to propose a contract parameter change or action. Requires fee.
// 13. getProposal(uint256 proposalId): Reads proposal details. (View)
// 14. voteOnProposal(uint256 proposalId, bool support): Casts a vote on an active proposal based on voting power.
// 15. getVoterStatus(uint256 proposalId, address voter): Checks if a user has voted on a proposal. (View)
// 16. executeProposal(uint256 proposalId): Executes the target function call if the proposal succeeded.
// 17. cancelProposal(uint256 proposalId): Allows proposer or owner to cancel a pending/active proposal.
// 18. getProposalState(uint256 proposalId): Gets the current calculated state of a proposal. (View)
// 19. setMutationRate(uint256 rate): Admin function to change the mutation rate.
// 20. setEvolutionThreshold(uint256 threshold): Admin function to change the evolution threshold.
// 21. setVotingPeriod(uint256 duration): Admin function to change the voting period.
// 22. setQuorumPercentage(uint256 percentage): Admin function to change the quorum.
// 23. setProposalFee(uint256 fee): Admin function to change the proposal fee.
// 24. withdrawFees(): Admin function to withdraw accumulated proposal fees.
// 25. setPaused(bool state): Pauses/unpauses the contract (owner only, provided by Pausable).
// 26. tokenURI(uint256 tokenId): Returns metadata URI (standard ERC721, but dynamic). (View)
// 27. updateMorphName(uint256 tokenId, string newName): Allows owner to change the name trait.
// 28. getTotalVotingPower(): Calculates the total potential voting power in the system. (View)
// 29. getRandomNumber(uint256 seed): Internal helper for generating pseudo-random numbers using block hash (NOT SECURE).
// 30. getTokenIdsOwnedBy(address owner): Helper function to list token IDs owned by an address (gas-intensive). (View)
// --- End Outline ---

contract ChronoMorphs is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    struct ChronoMorphData {
        uint256 generation;
        uint256 strength;
        uint256 agility;
        uint256 wisdom;
        string name;
        uint256 lastMutatedTimestamp;
    }

    mapping(uint256 => ChronoMorphData) private _morphData;
    mapping(uint256 => uint256) private _acquiredTimestamp; // Timestamp when token was acquired by current owner
    mapping(address => uint256[]) private _heldTokenIds; // Basic tracking, inefficient for many tokens/owners

    Counters.Counter private _tokenIdCounter;

    // Governance
    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed,
        Canceled
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes targetFunctionCallData; // The call data to execute if proposal passes
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        bool executed;
        bool canceled;
    }

    mapping(uint256 => Proposal) private _proposals;
    mapping(address => mapping(uint256 => bool)) private _hasVoted; // voterAddress => proposalId => voted
    Counters.Counter private _proposalIdCounter;

    // System Parameters (Can be changed by governance)
    uint256 public mutationRate = 1 days; // How often a morph can mutate (in seconds)
    uint256 public evolutionThreshold = 5; // Generation required for evolution
    uint256 public votingPeriod = 3 days; // Duration of a proposal's voting period (in seconds)
    uint256 public quorumPercentage = 4; // Percentage of total voting power required for a proposal to pass (e.g., 4% = 400)
    uint256 public proposalFee = 0.01 ether; // Fee to submit a proposal

    // Events
    event ChronoMorphMinted(uint256 indexed tokenId, address indexed owner, uint256 generation);
    event ChronoMorphMutated(uint256 indexed tokenId, uint256 indexed newGeneration, uint256 strength, uint256 agility, uint256 wisdom);
    event ChronoMorphEvolved(uint256 indexed tokenId, uint256 indexed newGeneration, uint256 strength, uint256 agility, uint256 wisdom);
    event ChronoMorphBred(uint256 indexed newChildTokenId, uint256 indexed parent1, uint256 indexed parent2, address indexed owner);
    event ChronoMorphNameUpdated(uint256 indexed tokenId, string newName);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    // Errors
    error InvalidTokenId();
    error NotTokenOwnerOrApproved();
    error CannotMutateYet();
    error CannotEvolveYet();
    error InvalidParents();
    error ProposalFeeNotMet();
    error NoVotingPower();
    error ProposalNotFound();
    error ProposalNotActive();
    error AlreadyVoted();
    error ProposalPeriodNotEnded();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecutedOrCanceled();
    error QuorumNotReached();
    error ProposalFailed();
    error CallFailed(bytes data);
    error ArrayOutOfBounds(); // For getTokenIdsOwnedBy helper


    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC721(name, symbol) Ownable(msg.sender) {
        // Mint initial genesis morphs
        for (uint i = 0; i < initialSupply; i++) {
            _mintGenesisMorph(msg.sender); // Mint to deployer initially
        }
    }

    // --- Internal Hooks ---

    // Override ERC721 hook to track acquisition time
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // If transferring from 0x0 (minting), record acquisition time
        // If transferring to non-0x0, record acquisition time for the new owner
        if (to != address(0)) {
            _acquiredTimestamp[tokenId] = block.timestamp;
            _addTokenToOwnerList(to, tokenId);
        }

        // If transferring from a non-0x0 address (burn or transfer), remove from old owner's list
        if (from != address(0)) {
             _removeTokenFromOwnerList(from, tokenId);
        }
    }

    // Helper to track tokens per owner (basic, potentially gas-intensive for many tokens)
    function _addTokenToOwnerList(address to, uint256 tokenId) private {
         _heldTokenIds[to].push(tokenId);
    }

     function _removeTokenFromOwnerList(address from, uint256 tokenId) private {
        uint256[] storage tokenList = _heldTokenIds[from];
        for (uint i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == tokenId) {
                // Swap last element with current and pop
                if (i < tokenList.length - 1) {
                    tokenList[i] = tokenList[tokenList.length - 1];
                }
                tokenList.pop();
                return;
            }
        }
         // Should not happen if called correctly in _beforeTokenTransfer
    }


    // --- ChronoMorph Core Logic ---

    /**
     * @dev Mints a new ChronoMorph with initial random traits.
     * @param recipient The address to mint the token to.
     */
    function mintGenesisMorph(address recipient) public onlyOwner whenNotPaused {
        _mintGenesisMorph(recipient);
    }

    // Internal minting logic
    function _mintGenesisMorph(address recipient) internal {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Basic pseudo-random trait generation (NOT SECURE FOR CRITICAL USE)
        // In a real dApp, use Chainlink VRF or similar
        uint256 seed = newTokenId + block.timestamp + uint256(keccak256(abi.encodePacked(msg.sender)));
        uint256 random1 = getRandomNumber(seed);
        uint256 random2 = getRandomNumber(random1);
        uint256 random3 = getRandomNumber(random2);

        _morphData[newTokenId] = ChronoMorphData({
            generation: 1,
            strength: 10 + (random1 % 10), // Base 10-19
            agility: 10 + (random2 % 10),  // Base 10-19
            wisdom: 10 + (random3 % 10),   // Base 10-19
            name: string(abi.encodePacked("Morph #", newTokenId.toString())),
            lastMutatedTimestamp: block.timestamp
        });

        _safeMint(recipient, newTokenId);
        emit ChronoMorphMinted(newTokenId, recipient, 1);
    }


    /**
     * @dev Gets the data for a specific ChronoMorph.
     * @param tokenId The ID of the token.
     * @return The ChronoMorphData struct.
     */
    function getMorphData(uint256 tokenId) public view returns (ChronoMorphData memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _morphData[tokenId];
    }

     /**
     * @dev Gets the timestamp when a morph was acquired by the current owner.
     * @param tokenId The ID of the token.
     * @return The timestamp.
     */
    function getMorphAcquisitionTime(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         return _acquiredTimestamp[tokenId];
     }

    /**
     * @dev Calculates the time-weighted voting power for an address.
     * Voting power is the sum of days each held ChronoMorph has been held.
     * @param voter The address to calculate voting power for.
     * @return The voting power.
     */
    function getVotingPower(address voter) public view returns (uint256) {
        uint256 totalPower = 0;
        uint256[] memory ownedTokens = _heldTokenIds[voter]; // Copy array from storage
        for (uint i = 0; i < ownedTokens.length; i++) {
            uint256 tokenId = ownedTokens[i];
             if (_exists(tokenId)) { // Extra check in case list is stale
                 uint256 holdDuration = block.timestamp - _acquiredTimestamp[tokenId];
                totalPower += holdDuration / 1 days; // Power is roughly days held
            }
        }
        return totalPower;
    }

     /**
     * @dev Calculates the total possible voting power across all tokens.
     */
     function getTotalVotingPower() public view returns (uint256) {
         uint256 totalPower = 0;
         // Iterating all token IDs is necessary as we don't have a list of *all* owners easily
         // This could be VERY gas-intensive for many tokens.
         // A better approach might involve tracking total hold time / tokens minted via events off-chain.
         // For this example, we'll just iterate up to the current counter.
         uint256 totalTokens = _tokenIdCounter.current();
         for(uint256 i = 0; i < totalTokens; i++) {
              // ERC721 doesn't guarantee contiguous token IDs if burning occurs.
              // A robust implementation would need to track active token IDs.
              // For simplicity here, we assume no burning for getTotalVotingPower.
             totalPower += (block.timestamp - _acquiredTimestamp[i]) / 1 days;
         }
         return totalPower; // This is approximate due to array copy/iteration limitations and potential burning
     }


    /**
     * @dev Checks if a morph is ready to mutate based on elapsed time since last mutation.
     * @param tokenId The ID of the token.
     * @return True if the morph can mutate.
     */
    function canMutate(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) return false;
        return block.timestamp >= _morphData[tokenId].lastMutatedTimestamp + mutationRate;
    }

    /**
     * @dev Triggers a random trait change for a ChronoMorph if conditions met.
     * Requires token ownership or approval.
     * @param tokenId The ID of the token to mutate.
     */
    function mutateMorph(uint256 tokenId) public payable whenNotPaused {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (_ownerOf(tokenId) != msg.sender && !isApprovedForAll(_ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotTokenOwnerOrApproved();
        }
        if (!canMutate(tokenId)) revert CannotMutateYet();

        ChronoMorphData storage morph = _morphData[tokenId];

        // Apply random change (again, NOT SECURE randomness)
        uint256 seed = tokenId + block.timestamp + uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty)));
        uint256 randomValue = getRandomNumber(seed);

        morph.generation++;
        morph.strength = morph.strength + (randomValue % 5) - 2; // Change by -2 to +2
        randomValue = getRandomNumber(randomValue);
        morph.agility = morph.agility + (randomValue % 5) - 2;
        randomValue = getRandomNumber(randomValue);
        morph.wisdom = morph.wisdom + (randomValue % 5) - 2;

        // Ensure stats don't go below a minimum (e.g., 1)
        if (morph.strength == 0) morph.strength = 1;
        if (morph.agility == 0) morph.agility = 1;
        if (morph.wisdom == 0) morph.wisdom = 1;

        morph.lastMutatedTimestamp = block.timestamp;

        emit ChronoMorphMutated(tokenId, morph.generation, morph.strength, morph.agility, morph.wisdom);
    }

    /**
     * @dev Checks if a morph is ready for evolution based on generation threshold.
     * @param tokenId The ID of the token.
     * @return True if the morph can evolve.
     */
     function canEvolve(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) return false;
         return _morphData[tokenId].generation >= evolutionThreshold;
     }


    /**
     * @dev Triggers a significant trait change (evolution) for a ChronoMorph.
     * Requires token ownership or approval and meeting evolution threshold.
     * @param tokenId The ID of the token to evolve.
     */
    function evolveMorph(uint256 tokenId) public payable whenNotPaused {
         if (!_exists(tokenId)) revert InvalidTokenId();
        if (_ownerOf(tokenId) != msg.sender && !isApprovedForAll(_ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotTokenOwnerOrApproved();
        }
        if (!canEvolve(tokenId)) revert CannotEvolveYet();

        ChronoMorphData storage morph = _morphData[tokenId];

        // More significant changes during evolution (again, NOT SECURE randomness)
        uint256 seed = tokenId + block.timestamp + uint256(keccak256(abi.encodePacked(msg.sender, block.prevrandao))); // Using prevrandao if applicable
        uint256 randomValue = getRandomNumber(seed);

        morph.generation += 10; // Jump generations
        morph.strength = morph.strength + (randomValue % 10) + 1; // Change by +1 to +10
        randomValue = getRandomNumber(randomValue);
        morph.agility = morph.agility + (randomValue % 10) + 1;
        randomValue = getRandomNumber(randomValue);
        morph.wisdom = morph.wisdom + (randomValue % 10) + 1;

        morph.lastMutatedTimestamp = block.timestamp; // Reset mutation timer too

        emit ChronoMorphEvolved(tokenId, morph.generation, morph.strength, morph.agility, morph.wisdom);
    }

    /**
     * @dev Creates a new ChronoMorph by combining traits from two parents.
     * Requires ownership of both parent tokens. A fee is required.
     * @param parent1TokenId The ID of the first parent token.
     * @param parent2TokenId The ID of the second parent token.
     */
     function breedMorphs(uint256 parent1TokenId, uint256 parent2TokenId) public payable whenNotPaused {
         if (!_exists(parent1TokenId) || !_exists(parent2TokenId)) revert InvalidTokenId();
         if (_ownerOf(parent1TokenId) != msg.sender || _ownerOf(parent2TokenId) != msg.sender) revert InvalidParents();
         if (parent1TokenId == parent2TokenId) revert InvalidParents(); // Cannot breed with self
         if (msg.value < proposalFee) revert ProposalFeeNotMet(); // Using proposalFee as breeding fee for simplicity

         uint256 newTokenId = _tokenIdCounter.current();
         _tokenIdCounter.increment();

         ChronoMorphData storage parent1Data = _morphData[parent1TokenId];
         ChronoMorphData storage parent2Data = _morphData[parent2TokenId];

         // Inherit traits with some variation (randomness applied)
         uint256 seed = parent1TokenId + parent2TokenId + block.timestamp + uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty)));
         uint256 randomValue = getRandomNumber(seed);

         uint256 childStrength = (parent1Data.strength + parent2Data.strength) / 2 + (randomValue % 5) - 2; // Average with +/- 2 var
         randomValue = getRandomNumber(randomValue);
         uint256 childAgility = (parent1Data.agility + parent2Data.agility) / 2 + (randomValue % 5) - 2;
         randomValue = getRandomNumber(randomValue);
         uint256 childWisdom = (parent1Data.wisdom + parent2Data.wisdom) / 2 + (randomValue % 5) - 2;

         // Ensure stats don't go below a minimum (e.g., 1)
         if (childStrength == 0) childStrength = 1;
         if (childAgility == 0) childAgility = 1;
         if (childWisdom == 0) childWisdom = 1;

         _morphData[newTokenId] = ChronoMorphData({
             generation: max(parent1Data.generation, parent2Data.generation) + 1, // Child is next generation
             strength: childStrength,
             agility: childAgility,
             wisdom: childWisdom,
             name: string(abi.encodePacked("Child Morph #", newTokenId.toString())),
             lastMutatedTimestamp: block.timestamp // Start mutation timer
         });

         _safeMint(msg.sender, newTokenId);

         emit ChronoMorphBred(newTokenId, parent1TokenId, parent2TokenId, msg.sender);
     }

     // Helper for max (needed in breedMorphs)
     function max(uint256 a, uint256 b) private pure returns (uint256) {
         return a >= b ? a : b;
     }

     /**
      * @dev Allows the owner of a ChronoMorph to update its name.
      * @param tokenId The ID of the token.
      * @param newName The new name for the morph.
      */
     function updateMorphName(uint256 tokenId, string memory newName) public whenNotPaused {
         if (!_exists(tokenId)) revert InvalidTokenId();
         if (_ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved(); // Only owner can name

         _morphData[tokenId].name = newName;

         emit ChronoMorphNameUpdated(tokenId, newName);
     }


    // --- Governance Logic ---

    /**
     * @dev Allows a user with voting power to propose a change or action.
     * Requires sending the proposal fee.
     * @param description A description of the proposal.
     * @param callData The encoded function call data to execute if the proposal passes.
     */
    function proposeChange(string memory description, bytes memory callData) public payable whenNotPaused {
        if (msg.value < proposalFee) revert ProposalFeeNotMet();
        if (getVotingPower(msg.sender) == 0) revert NoVotingPower(); // Must hold at least one token for 1 day

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            targetFunctionCallData: callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            executed: false,
            canceled: false
        });

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /**
     * @dev Gets details for a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return The Proposal struct.
     */
    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
        if (_proposals[proposalId].id != proposalId && proposalId != 0) revert ProposalNotFound(); // Check if ID exists (handles default 0)
        return _proposals[proposalId];
    }

     /**
     * @dev Checks if a specific voter has already voted on a proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address of the voter.
     * @return True if the voter has voted, false otherwise.
     */
     function getVoterStatus(uint256 proposalId, address voter) public view returns (bool) {
         if (_proposals[proposalId].id != proposalId && proposalId != 0) revert ProposalNotFound();
         return _hasVoted[voter][proposalId];
     }

    /**
     * @dev Casts a vote on an active proposal.
     * Voting power is calculated based on the voter's ChronoMorph holdings *at the time of voting*.
     * @param proposalId The ID of the proposal.
     * @param support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id != proposalId && proposalId != 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.timestamp > proposal.voteEndTime) revert ProposalPeriodNotEnded();
        if (_hasVoted[msg.sender][proposalId]) revert AlreadyVoted();

        uint256 votingPower = getVotingPower(msg.sender);
        if (votingPower == 0) revert NoVotingPower();

        _hasVoted[msg.sender][proposalId] = true;

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit Voted(proposalId, msg.sender, support, votingPower);
    }

     /**
      * @dev Gets the current state of a proposal based on time and vote counts.
      * @param proposalId The ID of the proposal.
      * @return The current state of the proposal.
      */
     function getProposalState(uint256 proposalId) public view returns (ProposalState) {
         Proposal memory proposal = _proposals[proposalId]; // Use memory copy to avoid storage reads in checks
         if (proposal.id != proposalId && proposalId != 0) revert ProposalNotFound();

         if (proposal.state == ProposalState.Executed) return ProposalState.Executed;
         if (proposal.state == ProposalState.Canceled) return ProposalState.Canceled;

         if (proposal.state == ProposalState.Pending && block.timestamp >= proposal.voteStartTime) return ProposalState.Active;
         if (proposal.state == ProposalState.Active && block.timestamp < proposal.voteEndTime) return ProposalState.Active;


         // If voting period is over (or if state was pending/active and time passed)
         if (block.timestamp >= proposal.voteEndTime || proposal.state == ProposalState.Active) {
             uint256 totalActiveVotingPowerAtPeriodEnd; // Needs off-chain calculation or snapshotting for accuracy!
             // For this example, we'll use the current total power, which is inaccurate
             // A real DAO would need to track total voting power at a specific block/timestamp.
             totalActiveVotingPowerAtPeriodEnd = getTotalVotingPower(); // Inaccurate approximation

             // Calculate quorum threshold (e.g., 4% of total active power)
             uint256 quorumThreshold = (totalActiveVotingPowerAtPeriodEnd * quorumPercentage) / 10000; // quorumPercentage is 0-10000 (for 0-100%)

             if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= quorumThreshold) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Failed;
             }
         }

         return proposal.state; // Return original state if conditions not met
     }


    /**
     * @dev Executes the function call data of a proposal if it has succeeded.
     * Any address can trigger execution once the voting period is over.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id != proposalId && proposalId != 0) revert ProposalNotFound();
        if (proposal.executed || proposal.canceled) revert ProposalAlreadyExecutedOrCanceled();
        if (block.timestamp < proposal.voteEndTime) revert ProposalPeriodNotEnded(); // Must wait for voting to end

        // Re-evaluate the state based on final votes and time
        ProposalState finalState = getProposalState(proposalId);

        if (finalState != ProposalState.Succeeded) {
             proposal.state = finalState; // Update state in storage
             revert ProposalNotSucceeded();
        }

        // Set state to Executed before the call in case of reentrancy (though call is likely external)
        proposal.state = ProposalState.Executed;
        proposal.executed = true;

        // **SECURITY WARNING:** Calling arbitrary user-supplied bytes (`callData`) is risky!
        // Ensure target functions are safe and authorization within the target function
        // (e.g., onlyOwner checks if calling an admin function) is correctly implemented.
        // Or use a more restricted execution system (e.g., a timelock).
        (bool success, bytes memory result) = address(this).call(proposal.targetFunctionCallData);

        if (!success) {
            // Execution failed. The proposal succeeded but the action failed.
            // Decide how to handle this: mark as Failed? Log error? Revert?
            // Reverting is safer in most cases unless planned otherwise.
            // This will also revert the state change to Executed.
            revert CallFailed(result);
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Allows the proposer or contract owner to cancel a proposal that is not yet active or has not ended.
     * @param proposalId The ID of the proposal to cancel.
     */
     function cancelProposal(uint256 proposalId) public whenNotPaused {
         Proposal storage proposal = _proposals[proposalId];
         if (proposal.id != proposalId && proposalId != 0) revert ProposalNotFound();
         if (proposal.executed || proposal.canceled) revert ProposalAlreadyExecutedOrCanceled();
         // Allow cancel if pending, or if proposer/owner before voting ends
         if (proposal.proposer != msg.sender && owner() != msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Use standard Ownable error
         if (block.timestamp >= proposal.voteEndTime && proposal.state == ProposalState.Active) revert ProposalPeriodNotEnded(); // Cannot cancel after voting ends if it was active

         proposal.state = ProposalState.Canceled;
         proposal.canceled = true;

         emit ProposalCanceled(proposalId);
     }


    // --- Admin Functions (via Ownership, can be targeted by Governance proposals) ---

    /**
     * @dev Sets the mutation rate (time between mutations).
     * Can be called by owner or via governance.
     * @param rate The new mutation rate in seconds.
     */
    function setMutationRate(uint256 rate) public onlyOwner whenNotPaused {
        mutationRate = rate;
    }

    /**
     * @dev Sets the generation threshold for evolution.
     * Can be called by owner or via governance.
     * @param threshold The new evolution threshold.
     */
    function setEvolutionThreshold(uint256 threshold) public onlyOwner whenNotPaused {
        evolutionThreshold = threshold;
    }

    /**
     * @dev Sets the duration of the voting period for proposals.
     * Can be called by owner or via governance.
     * @param duration The new voting period in seconds.
     */
    function setVotingPeriod(uint256 duration) public onlyOwner whenNotPaused {
        votingPeriod = duration;
    }

    /**
     * @dev Sets the percentage of total voting power required for a proposal quorum.
     * Value is multiplied by 100 (e.g., 400 for 4%). Max 10000.
     * Can be called by owner or via governance.
     * @param percentage The new quorum percentage (0-10000).
     */
    function setQuorumPercentage(uint256 percentage) public onlyOwner whenNotPaused {
        require(percentage <= 10000, "Percentage out of range (0-10000)");
        quorumPercentage = percentage;
    }

    /**
     * @dev Sets the fee required to submit a proposal or breed morphs.
     * Can be called by owner or via governance.
     * @param fee The new proposal fee in wei.
     */
    function setProposalFee(uint256 fee) public onlyOwner whenNotPaused {
        proposalFee = fee;
    }

    /**
     * @dev Allows the owner to withdraw accumulated proposal/breeding fees.
     */
    function withdrawFees() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     * @param state True to pause, false to unpause.
     */
    function setPaused(bool state) public onlyOwner {
        if (state) {
            _pause();
        } else {
            _unpause();
        }
    }


    // --- Utility and View Functions ---

    /**
     * @dev Basic pseudo-random number generator using block hash (NOT SECURE).
     * Use Chainlink VRF or similar for production randomness.
     * @param seed A seed for the randomness.
     * @return A pseudo-random uint256.
     */
    function getRandomNumber(uint256 seed) internal view returns (uint256) {
        // Blockhash is deprecated and unreliable after EIP-4399 (Merge)
        // prevrandao should be used now, but still predictable.
        // This is ONLY for demonstration of how randomness could integrate.
        // In production, integrate Chainlink VRF or similar secure oracle.
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed, block.number));
        return uint256(hash);
    }

    /**
     * @dev Returns the URI for a given token, potentially including dynamic traits.
     * Needs an off-chain service (API) to generate the actual JSON metadata and image.
     * The URI should ideally include the tokenId and potentially contract address
     * for the API to fetch the current on-chain traits via `getMorphData`.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        // Base URI + Token ID, API service needs to handle fetching data for this ID
        // e.g., "https://your-api.com/morphs/metadata/123"
        // The API would call getMorphData(123) on this contract to build the JSON.
         return string(abi.encodePacked("https://your-api.com/morphs/metadata/", tokenId.toString()));
    }

    /**
     * @dev Helper function to get the list of token IDs owned by an address.
     * NOTE: This is highly gas-intensive for owners with many tokens.
     * Rely on off-chain indexing for production applications.
     * @param owner The address to query.
     * @return An array of token IDs.
     */
    function getTokenIdsOwnedBy(address owner) public view returns (uint256[] memory) {
        // Make a copy of the storage array to return
        uint256[] storage ownedList = _heldTokenIds[owner];
        uint256 count = ownedList.length;
        uint256[] memory result = new uint256[count];
        for (uint i = 0; i < count; i++) {
             result[i] = ownedList[i]; // This read is cheap
        }
        return result;
    }


    // --- Overrides for Pausable and ERC721 ---
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {} // For UUPS proxies if applicable

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _mint(address to, uint256 tokenId) internal virtual override(ERC721) {
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721) {
         // If burning, need to remove from the held token list before calling super
         address ownerOfToken = ownerOf(tokenId); // Use ownerOf from ERC721
         _removeTokenFromOwnerList(ownerOfToken, tokenId);
        super._burn(tokenId);
    }


    // Standard ERC721 functions with Pausable modifier
    function approve(address to, uint256 tokenId) public override payable whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override payable whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override payable whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override payable whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
    }

     // ERC165 support - includes ERC721 and Ownable implicitly from inherited contracts
     // and Pausable doesn't have a dedicated interface ID usually.
     // If adding custom interfaces, register them here.
     function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
         // Example of checking a custom interface if you had one:
         // if (interfaceId == type(ICustomInterface).interfaceId) { return true; }
         return super.supportsInterface(interfaceId);
     }

    // --- External View Functions (from ERC721) ---
    // balanceOf, ownerOf, getApproved, isApprovedForAll are standard views
    // and are available via inheritance.
}
```