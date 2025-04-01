```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (AI Assistant)
 * @notice This contract implements a dynamic NFT that evolves based on user interactions, random events, and community voting.
 * It features advanced concepts like dynamic metadata, on-chain randomness with Chainlink VRF (simulated for simplicity),
 * community governance through voting, and a staking mechanism for NFT holders.
 *
 * Function Summary:
 *
 * **Core NFT Functions:**
 * 1. mintNFT(string memory _baseURI) - Mints a new NFT with initial metadata and sets base URI. (Admin-only)
 * 2. tokenURI(uint256 tokenId) - Returns the dynamic metadata URI for a given tokenId, reflecting its current state.
 * 3. supportsInterface(bytes4 interfaceId) - Standard ERC721 interface support.
 * 4. withdrawFunds() - Allows the contract owner to withdraw contract balance. (Owner-only)
 * 5. setBaseURI(string memory _newBaseURI) - Updates the base URI for metadata. (Owner-only)
 *
 * **Dynamic Evolution & Interaction Functions:**
 * 6. interactWithNFT(uint256 tokenId, InteractionType _interactionType) - Allows users to interact with their NFTs, triggering potential evolution.
 * 7. getNFTState(uint256 tokenId) - Returns the current state of an NFT (stage, attributes, etc.).
 * 8. checkEvolution(uint256 tokenId) - Checks if an NFT is eligible to evolve based on interaction points and random events. (Internal)
 * 9. evolveNFT(uint256 tokenId) - Triggers the evolution of an NFT, updating its state and metadata. (Internal)
 * 10. triggerRandomEvent(uint256 tokenId) - Simulates a random event affecting an NFT, potentially altering its state. (Internal - Simulated VRF)
 * 11. setInteractionPoints(uint256 tokenId, InteractionType _interactionType) - Sets interaction points for specific interaction types, influencing evolution. (Owner-only)
 * 12. getInteractionPoints(InteractionType _interactionType) - Retrieves the interaction points for a specific interaction type. (Public)
 *
 * **Community & Governance Functions:**
 * 13. proposeCommunityVote(string memory _proposalDescription, bytes memory _calldata) - Allows NFT holders to propose community votes on contract parameters.
 * 14. castVote(uint256 _proposalId, bool _vote) - Allows NFT holders to vote on active community proposals.
 * 15. getProposalDetails(uint256 _proposalId) - Retrieves details of a community vote proposal.
 * 16. executeProposal(uint256 _proposalId) - Executes a successful community vote proposal (Owner-only after quorum & passing).
 * 17. getActiveProposals() - Returns a list of active community vote proposal IDs.
 * 18. getVotingPower(address _voter) - Returns the voting power of an address based on their NFT holdings.
 *
 * **Staking & Utility Functions:**
 * 19. stakeNFT(uint256 tokenId) - Allows NFT holders to stake their NFTs for potential benefits (e.g., access to future features, governance power).
 * 20. unstakeNFT(uint256 tokenId) - Allows NFT holders to unstake their NFTs.
 * 21. getStakedNFTs(address _owner) - Returns a list of token IDs staked by a specific owner.
 * 22. isNFTStaked(uint256 tokenId) - Checks if an NFT is currently staked.
 *
 * **Merkle Whitelist Function:**
 * 23. mintWhitelistNFT(bytes32[] calldata _merkleProof) - Mints an NFT to whitelisted addresses using a Merkle proof.
 * 24. setMerkleRoot(bytes32 _merkleRoot) - Sets the Merkle root for the whitelist. (Owner-only)
 */
contract DynamicNFTEvolution is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    // --- NFT State and Evolution ---
    enum EvolutionStage { Egg, Hatchling, Juvenile, Adult, Evolved }
    enum InteractionType { Feed, Train, Play, Explore, Rest }

    struct NFTState {
        EvolutionStage stage;
        uint256 interactionPoints;
        uint256 lastInteractionTime;
        // Add more attributes as needed (e.g., happiness, energy, traits)
    }

    mapping(uint256 => NFTState) public nftStates;
    mapping(InteractionType => uint256) public interactionPointsByType; // Points gained per interaction type

    uint256 public evolutionThreshold = 100; // Points needed to potentially evolve
    uint256 public evolutionCooldown = 1 days; // Cooldown period between evolutions

    // --- Community Voting and Governance ---
    struct Proposal {
        string description;
        bytes calldata; // Function call data to execute if proposal passes
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public votingDuration = 7 days;
    uint256 public quorumPercentage = 51; // Percentage of total voting power needed for quorum

    // --- Staking ---
    mapping(uint256 => bool) public isStaked;
    mapping(address => uint256[]) public stakedNFTsByOwner;

    // --- Randomness (Simulated VRF for Simplicity) ---
    uint256 public randomnessFactor = 100; // Adjust to control randomness influence

    // --- Merkle Whitelist ---
    bytes32 public merkleRoot;

    event NFTMinted(uint256 tokenId, address to);
    event NFTInteracted(uint256 tokenId, InteractionType interactionType, address user);
    event NFTEvolved(uint256 tokenId, EvolutionStage newStage);
    event RandomEventTriggered(uint256 tokenId, string eventDescription);
    event CommunityProposalCreated(uint256 proposalId, string description);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) Ownable() {
        baseURI = _baseURI;
        // Initialize interaction points (can be configured by owner later)
        interactionPointsByType[InteractionType.Feed] = 10;
        interactionPointsByType[InteractionType.Train] = 15;
        interactionPointsByType[InteractionType.Play] = 20;
        interactionPointsByType[InteractionType.Explore] = 5;
        interactionPointsByType[InteractionType.Rest] = 2;
    }

    // --- Core NFT Functions ---

    /**
     * @dev Mints a new NFT with initial metadata and sets base URI. Only callable by contract owner.
     * @param _baseURI The base URI for the NFT metadata.
     */
    function mintNFT(string memory _baseURI) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);

        // Initialize NFT state
        nftStates[tokenId] = NFTState({
            stage: EvolutionStage.Egg,
            interactionPoints: 0,
            lastInteractionTime: block.timestamp
        });

        baseURI = _baseURI; // Set base URI upon first mint. Can be updated later.

        emit NFTMinted(tokenId, msg.sender);
    }

    /**
     * @dev Returns the dynamic metadata URI for a given tokenId, reflecting its current state.
     * @param tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token URI query for nonexistent token");

        NFTState memory state = nftStates[tokenId];
        string memory stageStr;

        if (state.stage == EvolutionStage.Egg) {
            stageStr = "Egg";
        } else if (state.stage == EvolutionStage.Hatchling) {
            stageStr = "Hatchling";
        } else if (state.stage == EvolutionStage.Juvenile) {
            stageStr = "Juvenile";
        } else if (state.stage == EvolutionStage.Adult) {
            stageStr = "Adult";
        } else if (state.stage == EvolutionStage.Evolved) {
            stageStr = "Evolved";
        } else {
            stageStr = "Unknown"; // Should not happen, but for safety
        }

        // Construct dynamic metadata URI based on state
        string memory metadataURI = string(abi.encodePacked(
            baseURI,
            tokenId.toString(),
            "-Stage-",
            stageStr,
            ".json" // Example: baseURI/1-Stage-Egg.json
        ));

        return metadataURI;
    }

    /**
     * @dev Withdraws contract balance to the owner.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Updates the base URI for metadata. Only callable by contract owner.
     * @param _newBaseURI The new base URI to set.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // --- Dynamic Evolution & Interaction Functions ---

    /**
     * @dev Allows users to interact with their NFTs, triggering potential evolution.
     * @param tokenId The ID of the NFT to interact with.
     * @param _interactionType The type of interaction performed.
     */
    function interactWithNFT(uint256 tokenId, InteractionType _interactionType) public {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(!isStaked[tokenId], "NFT is staked and cannot be interacted with");

        NFTState storage state = nftStates[tokenId];

        // Apply interaction points
        state.interactionPoints += interactionPointsByType[_interactionType];
        state.lastInteractionTime = block.timestamp;

        emit NFTInteracted(tokenId, _interactionType, msg.sender);

        // Check for evolution possibility after interaction
        checkEvolution(tokenId);
    }

    /**
     * @dev Returns the current state of an NFT.
     * @param tokenId The ID of the NFT.
     * @return NFTState struct containing the NFT's current state.
     */
    function getNFTState(uint256 tokenId) public view returns (NFTState memory) {
        require(_exists(tokenId), "NFT does not exist");
        return nftStates[tokenId];
    }

    /**
     * @dev Checks if an NFT is eligible to evolve based on interaction points and random events.
     * @param tokenId The ID of the NFT to check.
     * @dev Internal function called after interactions.
     */
    function checkEvolution(uint256 tokenId) internal {
        NFTState storage state = nftStates[tokenId];

        if (state.stage < EvolutionStage.Evolved && state.interactionPoints >= evolutionThreshold && block.timestamp >= state.lastInteractionTime + evolutionCooldown) {
            // Simulate random event before evolution attempt
            triggerRandomEvent(tokenId);

            // Simple evolution logic: 50% chance to evolve to next stage (can be made more complex)
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, state.interactionPoints))) % randomnessFactor;

            if (randomNumber < randomnessFactor / 2) { // 50% chance
                evolveNFT(tokenId);
            } else {
                emit RandomEventTriggered(tokenId, "Evolution attempt failed. Try again later.");
            }
        }
    }

    /**
     * @dev Triggers the evolution of an NFT, updating its state and metadata.
     * @param tokenId The ID of the NFT to evolve.
     * @dev Internal function called when evolution conditions are met.
     */
    function evolveNFT(uint256 tokenId) internal {
        NFTState storage state = nftStates[tokenId];

        if (state.stage < EvolutionStage.Evolved) {
            state.stage = EvolutionStage(uint256(state.stage) + 1); // Increment stage
            state.interactionPoints = 0; // Reset interaction points after evolution
            state.lastInteractionTime = block.timestamp; // Reset last interaction time

            emit NFTEvolved(tokenId, state.stage);
        }
    }

    /**
     * @dev Simulates a random event affecting an NFT, potentially altering its state.
     * @param tokenId The ID of the NFT to affect.
     * @dev Internal function using a simple pseudo-random number generator for demonstration.
     *      In a real-world scenario, use Chainlink VRF for secure on-chain randomness.
     */
    function triggerRandomEvent(uint256 tokenId) internal {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId))) % randomnessFactor;

        if (randomNumber < randomnessFactor / 10) { // 10% chance of a positive event
            nftStates[tokenId].interactionPoints += 20; // Bonus interaction points
            emit RandomEventTriggered(tokenId, "Positive Event: Bonus Interaction Points!");
        } else if (randomNumber > randomnessFactor * 9 / 10) { // 10% chance of a negative event
            if (nftStates[tokenId].interactionPoints > 10) {
                nftStates[tokenId].interactionPoints -= 10; // Reduce interaction points
            }
            emit RandomEventTriggered(tokenId, "Negative Event: Interaction Points Reduced!");
        } else {
            emit RandomEventTriggered(tokenId, "No significant event occurred.");
        }
    }

    /**
     * @dev Sets interaction points for specific interaction types. Only callable by contract owner.
     * @param _interactionType The interaction type to set points for.
     * @param _points The number of points to assign to the interaction type.
     */
    function setInteractionPoints(InteractionType _interactionType, uint256 _points) public onlyOwner {
        interactionPointsByType[_interactionType] = _points;
    }

    /**
     * @dev Retrieves the interaction points for a specific interaction type.
     * @param _interactionType The interaction type to query.
     * @return The number of points for the given interaction type.
     */
    function getInteractionPoints(InteractionType _interactionType) public view returns (uint256) {
        return interactionPointsByType[_interactionType];
    }

    // --- Community & Governance Functions ---

    /**
     * @dev Allows NFT holders to propose community votes on contract parameters.
     * @param _proposalDescription A description of the proposal.
     * @param _calldata The calldata to execute if the proposal passes. This should target this contract.
     */
    function proposeCommunityVote(string memory _proposalDescription, bytes memory _calldata) public {
        require(balanceOf(msg.sender) > 0, "Must hold at least one NFT to propose a vote");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            description: _proposalDescription,
            calldata: _calldata,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit CommunityProposalCreated(proposalId, _proposalDescription);
    }

    /**
     * @dev Allows NFT holders to vote on active community proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function castVote(uint256 _proposalId, bool _vote) public {
        require(balanceOf(msg.sender) > 0, "Must hold at least one NFT to vote");
        require(proposals[_proposalId].startTime != 0, "Proposal does not exist"); // Check if proposal exists
        require(block.timestamp >= proposals[_proposalId].startTime && block.timestamp <= proposals[_proposalId].endTime, "Voting period is over");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        uint256 votingPower = getVotingPower(msg.sender);

        if (_vote) {
            proposals[_proposalId].yesVotes += votingPower;
        } else {
            proposals[_proposalId].noVotes += votingPower;
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Retrieves details of a community vote proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        require(proposals[_proposalId].startTime != 0, "Proposal does not exist");
        return proposals[_proposalId];
    }

    /**
     * @dev Executes a successful community vote proposal. Only callable by contract owner after quorum & passing.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner {
        require(proposals[_proposalId].startTime != 0, "Proposal does not exist");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not over");

        uint256 totalVotingPower = totalSupply(); // In this simple example, total supply is total voting power
        uint256 quorum = (totalVotingPower * quorumPercentage) / 100;

        require(proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes >= quorum, "Quorum not reached");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "Proposal did not pass");

        (bool success, ) = address(this).call(proposals[_proposalId].calldata); // Execute the proposed function call
        require(success, "Proposal execution failed");

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Returns a list of active community vote proposal IDs.
     * @return An array of proposal IDs.
     */
    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposals = new uint256[](_proposalIdCounter.current());
        uint256 count = 0;
        for (uint256 i = 1; i <= _proposalIdCounter.current(); i++) {
            if (proposals[i].startTime != 0 && !proposals[i].executed && block.timestamp <= proposals[i].endTime) {
                activeProposals[count] = i;
                count++;
            }
        }

        // Resize the array to remove unused slots if any
        assembly {
            mstore(activeProposals, count) // Set the length of the array to 'count'
        }

        return activeProposals;
    }

    /**
     * @dev Returns the voting power of an address based on their NFT holdings.
     * @param _voter The address to check voting power for.
     * @return The voting power of the address (number of NFTs held).
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        return balanceOf(_voter); // Simple example: 1 NFT = 1 vote. Could be weighted.
    }

    // --- Staking & Utility Functions ---

    /**
     * @dev Allows NFT holders to stake their NFTs.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 tokenId) public {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(!isStaked[tokenId], "NFT already staked");
        require(!getApproved(tokenId).isZero() || isApprovedForAll(ownerOf(tokenId), address(this)), "Contract not approved to transfer NFT"); // Ensure contract can transfer

        isStaked[tokenId] = true;
        stakedNFTsByOwner[msg.sender].push(tokenId);

        // Transfer NFT to contract (escrow) - Needs approval to work
        safeTransferFrom(msg.sender, address(this), tokenId);

        emit NFTStaked(tokenId, msg.sender);
    }

    /**
     * @dev Allows NFT holders to unstake their NFTs.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 tokenId) public {
        require(_exists(tokenId), "NFT does not exist");
        require(isStaked[tokenId], "NFT not staked");
        require(ownerOf(tokenId) == address(this), "Contract is not owner of staked NFT (internal error)"); // Sanity check

        isStaked[tokenId] = false;

        // Remove tokenId from stakedNFTsByOwner array (inefficient for large arrays in practice, but fine for example)
        uint256[] storage stakedTokens = stakedNFTsByOwner[msg.sender];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == tokenId) {
                stakedTokens[i] = stakedTokens[stakedTokens.length - 1]; // Replace with last element
                stakedTokens.pop(); // Remove last element (duplicate if tokenId was last)
                break;
            }
        }

        // Transfer NFT back to owner
        safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTUnstaked(tokenId, msg.sender);
    }

    /**
     * @dev Returns a list of token IDs staked by a specific owner.
     * @param _owner The address of the owner.
     * @return An array of token IDs staked by the owner.
     */
    function getStakedNFTs(address _owner) public view returns (uint256[] memory) {
        return stakedNFTsByOwner[_owner];
    }

    /**
     * @dev Checks if an NFT is currently staked.
     * @param tokenId The ID of the NFT to check.
     * @return True if staked, false otherwise.
     */
    function isNFTStaked(uint256 tokenId) public view returns (bool) {
        return isStaked[tokenId];
    }

    // --- Merkle Whitelist Function ---

    /**
     * @dev Mints an NFT to whitelisted addresses using a Merkle proof.
     * @param _merkleProof The Merkle proof for the claiming address.
     */
    function mintWhitelistNFT(bytes32[] calldata _merkleProof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle proof");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);

        // Initialize NFT state for whitelist mints (can be different initial state if needed)
        nftStates[tokenId] = NFTState({
            stage: EvolutionStage.Egg,
            interactionPoints: 0,
            lastInteractionTime: block.timestamp
        });

        emit NFTMinted(tokenId, msg.sender);
    }

    /**
     * @dev Sets the Merkle root for the whitelist. Only callable by contract owner.
     * @param _merkleRoot The new Merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // --- ERC721 Interface Support ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```