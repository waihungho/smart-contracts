The `ChronoGenesisForge` smart contract represents a decentralized platform for the collaborative evolution of AI-generated digital entities (NFTs). Users can submit private data (verified by ZK-proofs off-chain), which an AI Oracle uses to generate a "Genesis Entity" NFT. These entities are dynamic, evolving through community-driven proposals and reputation-weighted voting. Successful proposals, processed by the Oracle, can update the entity's metadata, reflecting its new attributes or evolutionary stage. The contract integrates a non-transferable reputation system with delegation capabilities, rewarding active participation and successful contributions.

---

## Contract Outline

**Contract Name:** `ChronoGenesisForge`

**Core Concepts:**
1.  **Dynamic NFTs:** Entities whose metadata and state can change over time based on on-chain events.
2.  **ZK-Proof Integration:** Interface for users to submit proofs of private data, used for initial entity generation. (Actual ZK-proof verification is assumed to be handled by a dedicated external verifier contract).
3.  **AI Oracle Interaction:** A trusted off-chain AI service (represented by an `aiOracleAddress`) that processes data and updates entity states on-chain.
4.  **Community Governance (Evolution Proposals):** Users propose changes to entities, and the community votes using their reputation.
5.  **Reputation System (Soulbound with Delegation):** Non-transferable scores awarded for contributions, usable for voting power, with the ability to delegate voting power.
6.  **ERC721 Compatibility:** Implements a custom, minimal ERC721 standard for NFT ownership and transfer.

---

## Function Summary

**I. ERC721 Interface & Core Entity Management (Dynamic NFTs)**
1.  `balanceOf(address owner)`: Returns the number of NFTs owned by `owner`.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId` NFT.
3.  `approve(address to, uint256 tokenId)`: Grants approval to `to` to manage `tokenId`.
4.  `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId`.
5.  `setApprovalForAll(address operator, bool approved)`: Enables or disables `operator` to manage all of `msg.sender`'s NFTs.
6.  `isApprovedForAll(address owner, address operator)`: Checks if `operator` is approved for all of `owner`'s NFTs.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer ensuring `to` can receive ERC721s.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)`: Safe transfer with additional data.
10. `tokenURI(uint256 tokenId)`: Returns the current metadata URI for the `tokenId`.
11. `getEntityEvolutionStage(uint256 _tokenId)`: Retrieves the current evolutionary stage of an entity.
12. `toggleEvolutionLock(uint256 _tokenId)`: Allows the entity owner to lock/unlock its evolution, preventing/allowing new proposals.

**II. ZK-Proof & AI Oracle Integration**
13. `registerSeedDataProof(bytes32 _proofHash, bytes memory _zkProof, bytes32 _publicInputHash)`: Registers a ZK-proof hash for private seed data. Requires an external verifier.
14. `requestGenesisEntityGeneration(bytes32 _proofHash, string memory _metadataPlaceholderURI)`: Initiates the creation of a new Genesis Entity using a registered proof.
15. `mintGenesisEntityByOracle(address _recipient, string memory _initialMetadataURI, uint256 _seedHash)`: Callable *only by the AI Oracle* to mint a new entity after off-chain AI processing.
16. `updateEntityStateByOracle(uint256 _tokenId, string memory _newMetadataURI, uint256 _newEvolutionStage)`: Callable *only by the AI Oracle* to update an entity's state (metadata and stage).

**III. Evolution & Augmentation Proposals**
17. `proposeEvolutionChange(uint256 _tokenId, string memory _proposalTitle, string memory _newMetadataSegmentURI)`: Creates a proposal for a major evolutionary change to an entity.
18. `proposeAttributeAugmentation(uint256 _tokenId, string memory _proposalTitle, string memory _attributeKey, string memory _attributeValue)`: Creates a proposal to add or modify a specific attribute.
19. `voteOnProposal(uint256 _proposalId, bool _for)`: Casts a reputation-weighted vote on a proposal.
20. `finalizeProposal(uint256 _proposalId)`: Callable by anyone after the voting period ends; triggers execution of successful proposals via the Oracle.
21. `getProposalInfo(uint256 _proposalId)`: Retrieves detailed information about a proposal.
22. `getProposalVoteCounts(uint256 _proposalId)`: Returns the current reputation-weighted 'for' and 'against' votes for a proposal.

**IV. Reputation System (Soulbound with Delegation)**
23. `getReputationScore(address _user)`: Returns the current reputation score of a user.
24. `delegateReputationForVoting(address _delegatee)`: Allows a user to delegate their voting power to another address.
25. `undelegateReputationForVoting()`: Revokes any active reputation delegation.
26. `claimReputationReward(uint256 _rewardType, uint256 _param)`: A generalized function to claim various reputation rewards (e.g., for successful proposals, active voting, proof submission).

**V. Administrative & System Governance**
27. `setAIOracleAddress(address _newOracle)`: Sets the address of the trusted AI Oracle. (Owner-only)
28. `setProofVerifierContract(address _verifier)`: Sets the address of the external ZK-Proof Verifier contract. (Owner-only)
29. `setVotingPeriodDuration(uint256 _durationBlocks)`: Sets the duration (in blocks) for which proposals are open for voting. (Owner-only)
30. `setMinReputationToPropose(uint256 _minRep)`: Sets the minimum reputation required to submit a proposal. (Owner-only)
31. `grantReputation(address _user, uint256 _amount)`: Manually grants reputation to a user. (Owner-only, for emergency or special grants)
32. `revokeReputation(address _user, uint256 _amount)`: Manually revokes reputation from a user. (Owner-only, for emergency or penalty)
33. `emergencyPause()`: Pauses critical contract functions. (Owner-only)
34. `emergencyUnpause()`: Unpauses critical contract functions. (Owner-only)

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title ChronoGenesisForge
 * @dev A decentralized platform for the collaborative evolution of AI-generated digital entities (NFTs).
 *      Users submit private data (verified by ZK-proofs) which an AI Oracle uses to generate dynamic NFTs.
 *      The community proposes and votes on evolutionary changes, influencing the entities' development
 *      through a reputation-weighted system.
 */
contract ChronoGenesisForge is Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    // ERC721 core
    string public constant name = "ChronoGenesisEntity";
    string public constant symbol = "CGE";
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Genesis Entity specific data
    struct GenesisEntity {
        address owner;
        uint256 evolutionStage; // E.g., 0: Seed, 1: Larval, 2: Adolescent, 3: Mature
        string metadataURI; // Base URI, augmented by proposals
        bool evolutionLocked; // If true, no new proposals can affect this entity
        bytes32 seedProofHash; // Reference to the original ZK proof hash
    }
    mapping(uint256 => GenesisEntity) public genesisEntities;
    mapping(bytes32 => bool) public registeredProofHashes; // Tracks valid ZK proof hashes

    // Oracle & Verifier addresses
    address public aiOracleAddress;
    address public zkProofVerifierContract; // An external contract that verifies ZK proofs

    // Proposal system
    enum ProposalType { EvolutionChange, AttributeAugmentation }
    struct Proposal {
        uint256 tokenId;
        address proposer;
        ProposalType pType;
        string title;
        string valueString1; // newMetadataSegmentURI or attributeKey
        string valueString2; // attributeValue (only for AttributeAugmentation)
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes; // Reputation-weighted votes
        uint256 againstVotes; // Reputation-weighted votes
        bool executed;
        bool cancelled;
    }
    Counters.Counter public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // User vote tracking
    uint256 public votingPeriodDurationBlocks; // Duration in blocks for proposals
    uint256 public minReputationToPropose; // Minimum reputation required to submit a proposal

    // Reputation System (Soulbound with Delegation)
    mapping(address => uint256) public reputationScores;
    mapping(address => address) public delegatedReputation; // Address `A` delegates its voting power to `delegatedReputation[A]`

    // Reward Types for claimReputationReward
    enum RewardType {
        ProofSubmission,
        SuccessfulProposal,
        ActiveVoting
    }
    mapping(address => mapping(bytes32 => bool)) public claimedProofSubmissionReward;
    mapping(address => mapping(uint256 => bool)) public claimedSuccessfulProposalReward;
    mapping(address => uint256) public lastActiveVoterRewardClaimBlock; // To prevent spamming active voter reward

    // --- Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event ProofRegistered(address indexed user, bytes32 indexed proofHash, bytes32 publicInputHash);
    event EntityGenerationRequested(address indexed requester, bytes32 indexed proofHash, string metadataPlaceholderURI);
    event GenesisEntityMinted(address indexed owner, uint256 indexed tokenId, string initialMetadataURI, uint256 seedHash);
    event EntityStateUpdated(uint256 indexed tokenId, string newMetadataURI, uint256 newEvolutionStage);
    event EvolutionLockToggled(uint256 indexed tokenId, bool locked);

    event ProposalCreated(uint256 indexed proposalId, uint256 indexed tokenId, address indexed proposer, ProposalType pType, string title);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool _for, uint256 voteWeight);
    event ProposalFinalized(uint256 indexed proposalId, bool executed, bool successful);
    event ProposalCancelled(uint256 indexed proposalId);

    event ReputationUpdated(address indexed user, uint256 newScore);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator);
    event ReputationRewardClaimed(address indexed user, RewardType rewardType, uint256 amount);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == aiOracleAddress, "ChronoGenesisForge: Caller is not the AI oracle");
        _;
    }

    modifier onlyVerifier() {
        require(msg.sender == zkProofVerifierContract, "ChronoGenesisForge: Caller is not the ZK Proof Verifier");
        _;
    }

    // --- Constructor ---

    constructor(address _aiOracleAddress, address _zkProofVerifierContract) Ownable(msg.sender) {
        require(_aiOracleAddress != address(0), "ChronoGenesisForge: AI Oracle address cannot be zero");
        require(_zkProofVerifierContract != address(0), "ChronoGenesisForge: ZK Proof Verifier address cannot be zero");
        aiOracleAddress = _aiOracleAddress;
        zkProofVerifierContract = _zkProofVerifierContract;
        votingPeriodDurationBlocks = 1000; // Approx 4-5 hours @ ~12s/block
        minReputationToPropose = 100; // Initial threshold
    }

    // --- I. ERC721 Interface & Core Entity Management ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public whenNotPaused {
        address owner = ChronoGenesisForge.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        //soliditylint-disable-next-line reentrancy
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public whenNotPaused {
        //soliditylint-disable-next-line reentrancy
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Returns the current metadata URI for a given token ID.
     *      This URI is dynamic and reflects the entity's current state based on executed proposals.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return genesisEntities[tokenId].metadataURI;
    }

    /**
     * @dev Returns the current evolutionary stage of an entity.
     */
    function getEntityEvolutionStage(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ChronoGenesisForge: Entity does not exist");
        return genesisEntities[_tokenId].evolutionStage;
    }

    /**
     * @dev Allows the entity owner to lock or unlock its evolution.
     *      When locked, no new proposals can be submitted for this entity.
     */
    function toggleEvolutionLock(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ChronoGenesisForge: Entity does not exist");
        require(msg.sender == _owners[_tokenId], "ChronoGenesisForge: Caller is not the entity owner");

        genesisEntities[_tokenId].evolutionLocked = !genesisEntities[_tokenId].evolutionLocked;
        emit EvolutionLockToggled(_tokenId, genesisEntities[_tokenId].evolutionLocked);
    }

    // Internal ERC721 helper functions

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ChronoGenesisForge.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ChronoGenesisForge.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId); // Clear approvals
        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) { // If it's a contract
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
        return true; // EOA receives tokens without issue
    }

    function _mint(address to, uint256 tokenId, string memory initialMetadataURI, uint256 seedHash) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;
        genesisEntities[tokenId] = GenesisEntity(to, 0, initialMetadataURI, false, bytes32(seedHash));

        emit Transfer(address(0), to, tokenId);
        emit GenesisEntityMinted(to, tokenId, initialMetadataURI, seedHash);
        _updateReputation(to, 50); // Reward for contributing a seed
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ChronoGenesisForge.ownerOf(tokenId), to, tokenId);
    }

    // --- II. ZK-Proof & AI Oracle Integration ---

    /**
     * @dev Registers a ZK-proof hash for private seed data.
     *      The actual ZK-proof is verified by an external `zkProofVerifierContract`.
     *      This function only marks the hash as registered pending verification.
     *      A separate call to `requestGenesisEntityGeneration` will then use this proof.
     * @param _proofHash A hash representing the unique ZK proof.
     * @param _zkProof The raw ZK proof bytes (to be sent to the verifier contract).
     * @param _publicInputHash A hash of the public inputs used in the ZK proof.
     */
    function registerSeedDataProof(bytes32 _proofHash, bytes memory _zkProof, bytes32 _publicInputHash) public whenNotPaused {
        require(!registeredProofHashes[_proofHash], "ChronoGenesisForge: Proof hash already registered.");
        
        // In a real scenario, this would involve calling the `zkProofVerifierContract`
        // e.g., require(IZKVerifier(zkProofVerifierContract).verifyProof(_zkProof, _publicInputHash), "ChronoGenesisForge: ZK proof verification failed.");
        // For simplicity, we assume the proof is verified by an off-chain process
        // that then calls this contract via a trusted channel if needed, or we mock the verification here.
        // For this example, we'll simply register the hash.
        // A more robust system would have the verifier contract call back to ChronoGenesisForge
        // to confirm `_proofHash` validity.
        
        // For demonstration, we simply record the hash.
        // A true implementation would have the _zkProof verified against _publicInputHash
        // by the external verifier, which would then trigger a state change here.
        registeredProofHashes[_proofHash] = true; // Placeholder for actual verification success
        
        emit ProofRegistered(msg.sender, _proofHash, _publicInputHash);
    }

    /**
     * @dev Requests the AI Oracle to generate a new Genesis Entity using a registered proof.
     *      The AI Oracle will then call `mintGenesisEntityByOracle` after off-chain processing.
     * @param _proofHash The hash of the previously registered and verified ZK-proof.
     * @param _metadataPlaceholderURI A temporary URI for the entity while AI processes.
     */
    function requestGenesisEntityGeneration(bytes32 _proofHash, string memory _metadataPlaceholderURI) public whenNotPaused {
        require(registeredProofHashes[_proofHash], "ChronoGenesisForge: Proof hash not registered or invalid.");
        
        // The AI Oracle would pick this up, process off-chain, and then call `mintGenesisEntityByOracle`
        // The _proofHash could also serve as part of the seed for AI generation.
        
        emit EntityGenerationRequested(msg.sender, _proofHash, _metadataPlaceholderURI);
    }

    /**
     * @dev Callable ONLY by the AI Oracle to mint a new Genesis Entity.
     *      This is called after the AI Oracle has processed the seed data.
     * @param _recipient The address to receive the new Genesis Entity.
     * @param _initialMetadataURI The URI pointing to the initial metadata generated by the AI.
     * @param _seedHash The original seed hash from the ZK proof.
     */
    function mintGenesisEntityByOracle(address _recipient, string memory _initialMetadataURI, uint256 _seedHash) public onlyOracle whenNotPaused {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(_recipient, newTokenId, _initialMetadataURI, _seedHash);
        // Mark the proof as used or consume it
        // registeredProofHashes[bytes32(_seedHash)] = false; // Optional: consume proof after use
        _updateReputation(_recipient, 100); // Reward for successful entity creation
        emit GenesisEntityMinted(_recipient, newTokenId, _initialMetadataURI, _seedHash);
    }

    /**
     * @dev Callable ONLY by the AI Oracle to update an existing entity's state (metadata and stage).
     *      This is typically triggered by a successful proposal or a background AI evolution.
     * @param _tokenId The ID of the entity to update.
     * @param _newMetadataURI The new URI pointing to the updated metadata.
     * @param _newEvolutionStage The new evolutionary stage of the entity.
     */
    function updateEntityStateByOracle(uint256 _tokenId, string memory _newMetadataURI, uint256 _newEvolutionStage) public onlyOracle whenNotPaused {
        require(_exists(_tokenId), "ChronoGenesisForge: Entity does not exist.");
        
        genesisEntities[_tokenId].metadataURI = _newMetadataURI;
        genesisEntities[_tokenId].evolutionStage = _newEvolutionStage;
        
        emit EntityStateUpdated(_tokenId, _newMetadataURI, _newEvolutionStage);
    }

    // --- III. Evolution & Augmentation Proposals ---

    /**
     * @dev Creates a proposal for a major evolutionary change to an entity.
     *      Requires a minimum reputation score from the proposer.
     * @param _tokenId The ID of the entity to propose changes for.
     * @param _proposalTitle The title of the proposal.
     * @param _newMetadataSegmentURI The URI pointing to a metadata segment for the proposed change.
     */
    function proposeEvolutionChange(uint256 _tokenId, string memory _proposalTitle, string memory _newMetadataSegmentURI) public whenNotPaused {
        require(_exists(_tokenId), "ChronoGenesisForge: Entity does not exist.");
        require(!genesisEntities[_tokenId].evolutionLocked, "ChronoGenesisForge: Entity evolution is locked.");
        require(reputationScores[_getVotingPowerSource(msg.sender)] >= minReputationToPropose, "ChronoGenesisForge: Insufficient reputation to propose.");

        nextProposalId.increment();
        uint256 proposalId = nextProposalId.current();
        
        proposals[proposalId] = Proposal({
            tokenId: _tokenId,
            proposer: msg.sender,
            pType: ProposalType.EvolutionChange,
            title: _proposalTitle,
            valueString1: _newMetadataSegmentURI,
            valueString2: "", // Not used for EvolutionChange
            startBlock: block.number,
            endBlock: block.number.add(votingPeriodDurationBlocks),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            cancelled: false
        });

        emit ProposalCreated(proposalId, _tokenId, msg.sender, ProposalType.EvolutionChange, _proposalTitle);
    }

    /**
     * @dev Creates a proposal to add or modify a specific attribute of an entity.
     *      Requires a minimum reputation score from the proposer.
     * @param _tokenId The ID of the entity.
     * @param _proposalTitle The title of the proposal.
     * @param _attributeKey The key of the attribute to add/modify (e.g., "color", "ability").
     * @param _attributeValue The new value for the attribute.
     */
    function proposeAttributeAugmentation(uint256 _tokenId, string memory _proposalTitle, string memory _attributeKey, string memory _attributeValue) public whenNotPaused {
        require(_exists(_tokenId), "ChronoGenesisForge: Entity does not exist.");
        require(!genesisEntities[_tokenId].evolutionLocked, "ChronoGenesisForge: Entity evolution is locked.");
        require(reputationScores[_getVotingPowerSource(msg.sender)] >= minReputationToPropose, "ChronoGenesisForge: Insufficient reputation to propose.");

        nextProposalId.increment();
        uint256 proposalId = nextProposalId.current();
        
        proposals[proposalId] = Proposal({
            tokenId: _tokenId,
            proposer: msg.sender,
            pType: ProposalType.AttributeAugmentation,
            title: _proposalTitle,
            valueString1: _attributeKey,
            valueString2: _attributeValue,
            startBlock: block.number,
            endBlock: block.number.add(votingPeriodDurationBlocks),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            cancelled: false
        });

        emit ProposalCreated(proposalId, _tokenId, msg.sender, ProposalType.AttributeAugmentation, _proposalTitle);
    }

    /**
     * @dev Casts a reputation-weighted vote on a proposal.
     *      Users vote with their own or delegated reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "ChronoGenesisForge: Proposal does not exist.");
        require(!proposal.executed, "ChronoGenesisForge: Proposal already executed.");
        require(!proposal.cancelled, "ChronoGenesisForge: Proposal has been cancelled.");
        require(block.number >= proposal.startBlock, "ChronoGenesisForge: Voting has not started yet.");
        require(block.number <= proposal.endBlock, "ChronoGenesisForge: Voting period has ended.");

        address voterAddress = _getVotingPowerSource(msg.sender);
        require(!hasVotedOnProposal[_proposalId][voterAddress], "ChronoGenesisForge: Already voted on this proposal.");

        uint256 voteWeight = reputationScores[voterAddress];
        require(voteWeight > 0, "ChronoGenesisForge: No reputation to cast a vote.");

        if (_for) {
            proposal.forVotes = proposal.forVotes.add(voteWeight);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voteWeight);
        }
        hasVotedOnProposal[_proposalId][voterAddress] = true;
        
        // Internal reputation update for active voting, can be claimed later
        _updateReputation(voterAddress, 1); // Small immediate boost or track for later claim
        
        emit VoteCast(_proposalId, voterAddress, _for, voteWeight);
    }

    /**
     * @dev Callable by anyone after the voting period ends.
     *      If the proposal is successful, it triggers the AI Oracle to update the entity.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "ChronoGenesisForge: Proposal does not exist.");
        require(!proposal.executed, "ChronoGenesisForge: Proposal already executed.");
        require(!proposal.cancelled, "ChronoGenesisForge: Proposal has been cancelled.");
        require(block.number > proposal.endBlock, "ChronoGenesisForge: Voting period has not ended yet.");

        proposal.executed = true;
        bool successful = proposal.forVotes > proposal.againstVotes;

        if (successful) {
            // Logic for execution: The AI Oracle will perform the actual metadata update
            // We notify the oracle about the successful proposal.
            // In a real system, the oracle would have a listening mechanism or an API to query proposals.
            // For on-chain execution, we call a dedicated oracle function.
            
            string memory newMetadataURI = genesisEntities[proposal.tokenId].metadataURI; // Base URI
            uint256 newEvolutionStage = genesisEntities[proposal.tokenId].evolutionStage;

            if (proposal.pType == ProposalType.EvolutionChange) {
                // For EvolutionChange, the oracle would typically generate a new base URI
                // incorporating the proposed metadata segment.
                // We'll increment stage and concatenate URI for example.
                newEvolutionStage = newEvolutionStage.add(1);
                // Realistically, the AI Oracle would combine the base URI with valueString1
                // to produce a new, coherent metadata URI. For this contract, we'll
                // assume `valueString1` is a segment that needs to be integrated.
                // Or simply let the Oracle decide the full new URI based on current state + proposal.
                // Let's assume the Oracle takes proposal details and crafts the full URI.
                // So, we just tell the oracle to update the entity.
                // The oracle will take current URI, proposal.valueString1 and create final URI.
                // We pass the proposed change to the oracle. The oracle will fetch current metadata.
                
                // Example of a simple concatenation approach for demonstration:
                // newMetadataURI = string(abi.encodePacked(genesisEntities[proposal.tokenId].metadataURI, "/", proposal.valueString1));
                // However, directly concatenating might break JSON structure.
                // Better to let oracle entirely determine the new URI.
                
                // Call to oracle to update the entity, passing the proposal details
                // The oracle will decide the new URI and stage based on the proposal.
                // For now, we will simply increment the stage and let the oracle handle the URI
                // based on the successful proposal details.
                
                // Let's make it explicit that the oracle is fully responsible for new URI.
                // We'll pass the whole proposal details to the oracle.
                _executeProposalThroughOracle(
                    _proposalId,
                    proposal.tokenId,
                    proposal.pType,
                    proposal.valueString1,
                    proposal.valueString2,
                    newEvolutionStage // Oracle can override this, but we suggest a new stage.
                );

            } else if (proposal.pType == ProposalType.AttributeAugmentation) {
                // For AttributeAugmentation, the oracle would integrate proposal.valueString1 (key)
                // and proposal.valueString2 (value) into the existing metadata.
                // Same logic: tell oracle, it will craft new URI.
                _executeProposalThroughOracle(
                    _proposalId,
                    proposal.tokenId,
                    proposal.pType,
                    proposal.valueString1, // attributeKey
                    proposal.valueString2, // attributeValue
                    newEvolutionStage // No stage change expected for attribute aug, but included for uniformity
                );
            }
            _updateReputation(proposal.proposer, 200); // Reward for successful proposal
            claimedSuccessfulProposalReward[proposal.proposer][_proposalId] = true;
        }

        emit ProposalFinalized(_proposalId, true, successful);
    }
    
    // Internal function to delegate execution to the oracle.
    // The oracle will read the proposal state and call updateEntityStateByOracle.
    function _executeProposalThroughOracle(
        uint256 _proposalId,
        uint256 _tokenId,
        ProposalType _pType,
        string memory _val1,
        string memory _val2,
        uint256 _suggestedNewEvolutionStage
    ) internal {
        // Here, the contract signals to the oracle (or calls a specific oracle contract)
        // to perform the off-chain processing and then call `updateEntityStateByOracle`.
        // For a direct call, if the oracle is a contract with a public interface:
        // IAIOracle(aiOracleAddress).processProposalAndExecute(_proposalId, _tokenId, _pType, _val1, _val2, _suggestedNewEvolutionStage);
        // For this example, we assume the oracle is listening off-chain or will be called later.
        // The `updateEntityStateByOracle` function is the actual on-chain update point.
        // The current design implies the oracle reads the proposal state directly and acts.
        // So this function can be a no-op or simply emit an event for the oracle to pick up.
        // Let's emit an event for the oracle to pick up for off-chain processing.
        emit Log("Oracle will process proposal", Strings.toString(_proposalId));
    }


    /**
     * @dev Retrieves detailed information about a proposal.
     */
    function getProposalInfo(uint256 _proposalId) public view returns (
        uint256 tokenId,
        address proposer,
        ProposalType pType,
        string memory title,
        string memory valueString1,
        string memory valueString2,
        uint256 startBlock,
        uint256 endBlock,
        bool executed,
        bool cancelled
    ) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "ChronoGenesisForge: Proposal does not exist.");

        return (
            proposal.tokenId,
            proposal.proposer,
            proposal.pType,
            proposal.title,
            proposal.valueString1,
            proposal.valueString2,
            proposal.startBlock,
            proposal.endBlock,
            proposal.executed,
            proposal.cancelled
        );
    }

    /**
     * @dev Returns the current reputation-weighted 'for' and 'against' votes for a proposal.
     */
    function getProposalVoteCounts(uint256 _proposalId) public view returns (uint256 forVotes, uint256 againstVotes) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "ChronoGenesisForge: Proposal does not exist.");
        return (proposal.forVotes, proposal.againstVotes);
    }

    // --- IV. Reputation System (Soulbound with Delegation) ---

    /**
     * @dev Returns the current reputation score of a user.
     * @param _user The address to query reputation for.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev Allows a user to delegate their voting power to another address.
     *      The delegatee will cast votes on behalf of the delegator using the delegator's reputation.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateReputationForVoting(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "ChronoGenesisForge: Delegatee cannot be zero address.");
        require(_delegatee != msg.sender, "ChronoGenesisForge: Cannot delegate to self.");
        delegatedReputation[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any active reputation delegation, reverting voting power to the delegator.
     */
    function undelegateReputationForVoting() public whenNotPaused {
        require(delegatedReputation[msg.sender] != address(0), "ChronoGenesisForge: No active delegation to revoke.");
        delete delegatedReputation[msg.sender];
        emit ReputationUndelegated(msg.sender);
    }

    /**
     * @dev Internal helper to determine the effective address for voting power.
     */
    function _getVotingPowerSource(address _voter) internal view returns (address) {
        address delegatee = delegatedReputation[_voter];
        return delegatee != address(0) ? delegatee : _voter;
    }

    /**
     * @dev Internal function to update a user's reputation score.
     */
    function _updateReputation(address _user, int256 _amount) internal {
        if (_amount > 0) {
            reputationScores[_user] = reputationScores[_user].add(uint256(_amount));
        } else {
            uint256 absAmount = uint256(-_amount);
            reputationScores[_user] = reputationScores[_user].sub(absAmount);
        }
        emit ReputationUpdated(_user, reputationScores[_user]);
    }

    /**
     * @dev A generalized function to claim various reputation rewards.
     *      This prevents a flood of individual reward functions and centralizes reward logic.
     * @param _rewardType The type of reward being claimed (e.g., ProofSubmission, SuccessfulProposal).
     * @param _param A parameter specific to the reward type (e.g., proofHash, proposalId).
     */
    function claimReputationReward(RewardType _rewardType, uint256 _param) public whenNotPaused {
        uint256 rewardAmount = 0;
        address claimer = msg.sender;

        if (_rewardType == RewardType.ProofSubmission) {
            bytes32 proofHash = bytes32(_param);
            require(registeredProofHashes[proofHash], "ChronoGenesisForge: Proof not registered for reward.");
            require(!claimedProofSubmissionReward[claimer][proofHash], "ChronoGenesisForge: Reward for this proof already claimed.");
            // We'd need to track original submitter of proof here. For now, assume msg.sender.
            // A mapping `proofSubmitters[bytes32 => address]` would be needed if submitter != claimer.
            rewardAmount = 50; 
            _updateReputation(claimer, int256(rewardAmount));
            claimedProofSubmissionReward[claimer][proofHash] = true;
        } else if (_rewardType == RewardType.SuccessfulProposal) {
            uint256 proposalId = _param;
            Proposal storage proposal = proposals[proposalId];
            require(proposal.proposer == claimer, "ChronoGenesisForge: Not the proposer of this proposal.");
            require(proposal.executed && proposal.forVotes > proposal.againstVotes, "ChronoGenesisForge: Proposal not successful or executed.");
            require(!claimedSuccessfulProposalReward[claimer][proposalId], "ChronoGenesisForge: Reward for this proposal already claimed.");
            rewardAmount = 200;
            _updateReputation(claimer, int256(rewardAmount));
            claimedSuccessfulProposalReward[claimer][proposalId] = true;
        } else if (_rewardType == RewardType.ActiveVoting) {
            require(block.number >= lastActiveVoterRewardClaimBlock[claimer].add(100), "ChronoGenesisForge: Can only claim active voter reward every 100 blocks."); // Cooldown
            require(reputationScores[claimer] > 0, "ChronoGenesisForge: No reputation to claim active voter reward."); // Must have some rep
            rewardAmount = 5; // Small reward for active engagement
            _updateReputation(claimer, int256(rewardAmount));
            lastActiveVoterRewardClaimBlock[claimer] = block.number;
        } else {
            revert("ChronoGenesisForge: Invalid reward type.");
        }

        emit ReputationRewardClaimed(claimer, _rewardType, rewardAmount);
    }

    // --- V. Administrative & System Governance ---

    /**
     * @dev Sets the address of the trusted AI Oracle. Only callable by the contract owner.
     * @param _newOracle The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "ChronoGenesisForge: AI Oracle address cannot be zero.");
        aiOracleAddress = _newOracle;
    }

    /**
     * @dev Sets the address of the external ZK-Proof Verifier contract. Only callable by the contract owner.
     * @param _verifier The new address for the ZK-Proof Verifier contract.
     */
    function setProofVerifierContract(address _verifier) public onlyOwner {
        require(_verifier != address(0), "ChronoGenesisForge: ZK Proof Verifier address cannot be zero.");
        zkProofVerifierContract = _verifier;
    }

    /**
     * @dev Sets the duration (in blocks) for which proposals are open for voting. Only callable by the contract owner.
     * @param _durationBlocks The new duration in blocks.
     */
    function setVotingPeriodDuration(uint256 _durationBlocks) public onlyOwner {
        require(_durationBlocks > 0, "ChronoGenesisForge: Voting duration must be greater than zero.");
        votingPeriodDurationBlocks = _durationBlocks;
    }

    /**
     * @dev Sets the minimum reputation required to submit a proposal. Only callable by the contract owner.
     * @param _minRep The new minimum reputation threshold.
     */
    function setMinReputationToPropose(uint256 _minRep) public onlyOwner {
        minReputationToPropose = _minRep;
    }

    /**
     * @dev Manually grants reputation to a user. Callable by the contract owner for specific cases (e.g., initial seeding, error correction).
     * @param _user The recipient of the reputation.
     * @param _amount The amount of reputation to grant.
     */
    function grantReputation(address _user, uint256 _amount) public onlyOwner {
        _updateReputation(_user, int256(_amount));
    }

    /**
     * @dev Manually revokes reputation from a user. Callable by the contract owner for specific cases (e.g., penalties).
     * @param _user The user whose reputation is to be revoked.
     * @param _amount The amount of reputation to revoke.
     */
    function revokeReputation(address _user, uint256 _amount) public onlyOwner {
        _updateReputation(_user, -int256(_amount));
    }

    /**
     * @dev See {Pausable-pause}.
     *      Pauses critical functions of the contract in an emergency. Only callable by the contract owner.
     */
    function emergencyPause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}.
     *      Unpauses critical functions of the contract. Only callable by the contract owner.
     */
    function emergencyUnpause() public onlyOwner whenPaused {
        _unpause();
    }

    // Fallback and Receive functions to make the contract able to receive Ether
    receive() external payable {
        // Optionally, handle incoming Ether, e.g., for funding rewards.
    }

    fallback() external payable {
        // Optionally, handle incoming Ether or unexpected calls.
    }

    // Custom event for oracle logging/debugging
    event Log(string message, string data);
}

// Minimal IERC721Receiver for safeTransferFrom
interface IERC721Receiver {
    /**
     * @dev Whenever an ERC721 token is transferred to a contract via `safeTransferFrom`
     *  from ERC721, this function is called.
     *  It must return its Solidity selector to confirm the token transfer.
     *  If any other value is returned or the interface is not implemented by the recipient,
     *  the transfer will be reverted.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```