The `AuraForge` protocol introduces a novel concept of **Dynamic, AI-Curated, and Reputation-Based Digital Identity NFTs**. These "Aura" NFTs are not static; their visual and functional traits can evolve based on owner interaction, a user's on-chain reputation, and even AI-generated interpretations of user prompts. This creates a deeply personal and evolving digital asset that reflects a user's journey and contributions within the web3 ecosystem.

---

## AuraForge Protocol: Outline & Function Summary

**Concept:** AuraForge issues unique "Aura" NFTs (ERC-721) that represent an evolving digital identity or artistic expression. These NFTs dynamically change their traits and metadata based on:
1.  **User-provided prompts:** Owners can request AI-driven evolutions by submitting new prompts. An off-chain AI oracle processes these, generating new trait data.
2.  **On-chain reputation:** A built-in reputation system tracks user engagement. Reaching certain reputation thresholds can automatically unlock or modify Aura traits.
3.  **Community Governance:** Token holders or qualified participants can propose and vote on new "trait themes" or "AI models" that guide the evolution process, adding a layer of decentralized curation.

**Core Pillars:**
*   **Dynamic NFTs:** Traits and metadata are mutable and change over time.
*   **AI Oracle Integration:** Leverages an off-chain AI for creative content generation and trait modification, with on-chain verification.
*   **Reputation System:** Rewards positive engagement and integrates it into NFT evolution.
*   **Decentralized Curation:** Community involvement in defining the artistic and thematic direction.

---

### Function Summary:

**I. NFT Core & Base Functionality (Inherits ERC721)**
1.  `constructor(address _aiOracleAddress, string memory _baseURI)`: Initializes the contract with the trusted AI oracle address and base URI for metadata.
2.  `mintInitialAura(string calldata initialPrompt)`: Mints a new Aura NFT for the caller. An initial AI-driven evolution based on the `initialPrompt` is immediately requested.
3.  `tokenURI(uint256 tokenId)`: Returns the current dynamic metadata URI for a given Aura NFT.
4.  `getAuraTraits(uint256 tokenId)`: Retrieves all current, active traits associated with an Aura.
5.  `ownerOf(uint256 tokenId)`: Standard ERC-721 function to get the owner of a token.
6.  `balanceOf(address owner)`: Standard ERC-721 function to get the number of tokens owned by an address.
7.  `approve(address to, uint256 tokenId)`: Standard ERC-721 function to approve an address to spend a token.
8.  `setApprovalForAll(address operator, bool approved)`: Standard ERC-721 function to approve/revoke an operator for all tokens.
9.  `getApproved(uint256 tokenId)`: Standard ERC-721 function to get the approved address for a token.
10. `isApprovedForAll(address owner, address operator)`: Standard ERC-721 function to check operator approval.
11. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC-721 transfer function.
12. `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC-721 safe transfer function.
13. `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Overloaded ERC-721 safe transfer function.

**II. Dynamic Evolution & AI Interaction**
14. `requestAuraEvolution(uint256 tokenId, string calldata evolutionPrompt)`: Allows an Aura owner to request an AI-driven modification for their NFT based on a new prompt. Requires an evolution fee.
15. `fulfillAuraEvolution(uint256 tokenId, bytes32 newTraitsHash, string calldata newMetadataURI, bytes calldata oracleProof)`: **Oracle-only** function. Updates an Aura's traits and metadata after AI processing, verifying a proof from the trusted AI oracle.
16. `applyReputationBoost(uint256 tokenId)`: Triggers an internal trait modification or unlock for an Aura based on its owner's accumulated reputation score reaching a predefined threshold.
17. `addTraitCategory(string calldata categoryName, string[] calldata initialKeywords)`: **Governance/Admin** function. Defines new categories of traits that the AI can generate (e.g., "Emotion", "Background", "Accessory").
18. `getAuraEvolutionHistory(uint256 tokenId)`: Returns a log of past evolution requests and their fulfillment status for a specific Aura.

**III. Reputation System**
19. `increaseReputation(address user, uint256 amount)`: **Privileged** function (e.g., by another protocol module or admin). Awards reputation points to a user for engaging in desired on-chain activities.
20. `getReputationScore(address user)`: Retrieves the current reputation score of a specified user.
21. `setReputationThresholdForTrait(string calldata traitName, uint256 threshold, bytes32 traitHash)`: **Governance/Admin** function. Links a reputation score threshold to the unlock of a specific trait for an Aura.

**IV. Governance & Protocol Parameters**
22. `proposeNewTraitTheme(string calldata themeName, string calldata themeDescription, string[] calldata samplePrompts)`: Allows users to propose new thematic directions or styles for AI-generated traits.
23. `voteOnTraitThemeProposal(uint256 proposalId, bool support)`: Allows eligible participants to vote on open trait theme proposals.
24. `executeTraitThemeProposal(uint256 proposalId)`: **Governance/Admin** function. Finalizes and integrates a successfully voted-on trait theme, making it available for AI generation.
25. `setAIOracleAddress(address newOracle)`: **Admin** function. Updates the address of the trusted AI oracle contract.
26. `setEvolutionFee(uint256 fee)`: **Admin** function. Adjusts the fee required for requesting an Aura evolution.
27. `withdrawProtocolFees(address recipient)`: **Admin** function. Allows the contract owner to withdraw accumulated fees to a specified recipient.
28. `getTotalAurasMinted()`: Returns the total number of Aura NFTs that have been minted.
29. `getPendingEvolutionRequests(uint256 tokenId)`: Returns any outstanding evolution requests for a specific token that are awaiting oracle fulfillment.
30. `getProposalDetails(uint256 proposalId)`: Provides comprehensive details about a specific governance proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title IAIOracle
 * @dev Interface for the trusted AI Oracle contract.
 * The oracle is responsible for processing off-chain AI requests and returning
 * verifiable results (new traits hash, metadata URI, and a proof).
 */
interface IAIOracle {
    // This function would typically verify the oracleProof and emit an event
    // for the AuraForge contract to listen to, or it might be a multi-signature
    // system where a valid proof is a set of signatures.
    // For simplicity, AuraForge will directly verify a 'proof' (e.g., a hash or signature)
    // from the set AIOracleAddress.
    // However, an actual Oracle contract might have functions like:
    // function fulfillRequest(uint256 requestId, bytes32 newTraitsHash, string calldata newMetadataURI, bytes calldata proof) external;
    // For this example, the AuraForge contract directly calls a function that only the registered
    // AIOracleAddress can call, implicitly trusting its input if the address matches and proof is valid.
}

/**
 * @title AuraForge
 * @dev A protocol for Dynamic, AI-Curated, Reputation-Based Digital Identity NFTs.
 * Aura NFTs evolve based on user prompts, AI processing, and owner's on-chain reputation.
 * Features a light governance module for community curation of AI-generatable traits.
 */
contract AuraForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter; // Counter for unique Aura NFT IDs
    Counters.Counter private _proposalIdCounter; // Counter for governance proposals

    // Struct to define an Aura NFT's current traits
    struct Aura {
        bytes32 currentTraitsHash; // A hash representing the current set of traits
        string currentMetadataURI; // The dynamic URI for the NFT's metadata
        address owner; // The current owner of the Aura
        uint256 lastEvolutionTimestamp; // Timestamp of the last successful evolution
    }

    // Struct for an AI evolution request
    struct EvolutionRequest {
        uint256 tokenId;
        address requester;
        string prompt;
        uint256 requestTimestamp;
        bool fulfilled;
        bytes32 fulfilledTraitsHash;
        string fulfilledMetadataURI;
    }

    // Struct for a trait category managed by governance
    struct TraitCategory {
        string name;
        string[] keywords; // Keywords associated with this category for AI guidance
        uint256 creationTimestamp;
        bool isActive;
    }

    // Struct for a governance proposal
    struct Proposal {
        uint256 id;
        string name;
        string description;
        string[] samplePrompts; // Example prompts for a new trait theme
        address proposer;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yeas;
        uint256 nays;
        bool executed;
        bool active;
        mapping(address => bool) hasVoted; // Tracks who has voted
    }

    address public aiOracleAddress; // The trusted AI oracle contract address
    uint256 public evolutionFee; // Fee (in wei) required to request an Aura evolution
    uint256 public constant VOTING_PERIOD = 3 days; // Duration for governance proposals
    uint256 public constant MIN_REPUTATION_FOR_VOTE = 100; // Minimum reputation to vote on proposals

    // Mappings
    mapping(uint256 => Aura) public auras; // Aura NFT data by tokenId
    mapping(uint256 => EvolutionRequest[]) public auraEvolutionHistory; // History of evolutions for an Aura
    mapping(uint256 => EvolutionRequest) public pendingEvolutionRequests; // Store last pending request by tokenId
    mapping(address => uint256) public reputationScores; // User reputation scores
    mapping(string => uint256) public reputationThresholdsForTraits; // Reputation thresholds for specific trait unlocks (traitName => threshold)
    mapping(uint256 => TraitCategory) public traitCategories; // Registered trait categories by ID
    Counters.Counter private _traitCategoryIdCounter; // Counter for trait categories
    mapping(uint256 => Proposal) public proposals; // Governance proposals by ID

    // --- Events ---
    event AuraMinted(uint256 indexed tokenId, address indexed owner, string initialPrompt, bytes32 initialTraitsHash);
    event EvolutionRequested(uint256 indexed tokenId, address indexed requester, string prompt, uint256 requestTimestamp);
    event EvolutionFulfilled(uint256 indexed tokenId, bytes32 newTraitsHash, string newMetadataURI, uint256 fulfillmentTimestamp);
    event ReputationIncreased(address indexed user, uint256 newScore);
    event ReputationBoostApplied(uint256 indexed tokenId, address indexed owner, uint256 reputationScore);
    event TraitCategoryAdded(uint256 indexed categoryId, string name);
    event NewTraitThemeProposed(uint256 indexed proposalId, string themeName, address proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event EvolutionFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---
    constructor(address _aiOracleAddress, string memory _baseURI) ERC721("AuraForge Aura", "AURA") Ownable(msg.sender) {
        require(_aiOracleAddress != address(0), "AI Oracle cannot be zero address");
        aiOracleAddress = _aiOracleAddress;
        evolutionFee = 0.01 ether; // Default evolution fee
        _setBaseURI(_baseURI);
    }

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Caller is not the AI Oracle");
        _;
    }

    modifier onlyReputationEligible(address _voter) {
        require(reputationScores[_voter] >= MIN_REPUTATION_FOR_VOTE, "Not enough reputation to vote");
        _;
    }

    // --- I. NFT Core & Base Functionality ---

    /**
     * @dev Mints a new Aura NFT for the caller.
     * Initiates an AI-driven evolution based on the `initialPrompt`.
     * @param initialPrompt The initial prompt for AI to generate the Aura's first traits.
     */
    function mintInitialAura(string calldata initialPrompt) external payable {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Ensure initial creation has a fee or specific condition, if needed.
        // For simplicity, minting itself is free, but subsequent evolutions cost.

        _safeMint(msg.sender, newTokenId);

        // Store basic Aura data. Traits and URI will be set by the oracle.
        auras[newTokenId] = Aura({
            currentTraitsHash: bytes32(0), // Placeholder
            currentMetadataURI: "", // Placeholder
            owner: msg.sender,
            lastEvolutionTimestamp: block.timestamp
        });

        // Immediately create a pending evolution request for the initial mint
        // This signifies that the Aura is waiting for its first AI-generated traits
        pendingEvolutionRequests[newTokenId] = EvolutionRequest({
            tokenId: newTokenId,
            requester: msg.sender,
            prompt: initialPrompt,
            requestTimestamp: block.timestamp,
            fulfilled: false,
            fulfilledTraitsHash: bytes32(0),
            fulfilledMetadataURI: ""
        });

        // Emit an event for the off-chain AI oracle to pick up and process
        emit EvolutionRequested(newTokenId, msg.sender, initialPrompt, block.timestamp);
        emit AuraMinted(newTokenId, msg.sender, initialPrompt, bytes32(0)); // Hash will be updated by oracle
    }

    /**
     * @dev Returns the current dynamic metadata URI for a given Aura NFT.
     * @param tokenId The ID of the Aura NFT.
     * @return The URI pointing to the NFT's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return auras[tokenId].currentMetadataURI;
    }

    /**
     * @dev Retrieves all current, active traits associated with an Aura.
     * Note: In a real system, traits might be stored as an array of strings/structs
     * on-chain, or derived from `currentTraitsHash` which points to off-chain data.
     * For this example, we return the hash, assuming off-chain interpretation.
     * @param tokenId The ID of the Aura NFT.
     * @return A hash representing the Aura's current traits.
     */
    function getAuraTraits(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "AuraForge: Token does not exist");
        return auras[tokenId].currentTraitsHash;
    }

    // Inherited ERC721 functions are implicitly available: ownerOf, balanceOf, approve,
    // setApprovalForAll, getApproved, isApprovedForAll, transferFrom, safeTransferFrom.
    // We override internal _update and _approve functions to update owner in our Aura struct.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = super._update(to, tokenId, auth);
        auras[tokenId].owner = to; // Update the owner in our custom struct
        return from;
    }


    // --- II. Dynamic Evolution & AI Interaction ---

    /**
     * @dev Allows an Aura owner to request an AI-driven modification for their NFT.
     * @param tokenId The ID of the Aura NFT to evolve.
     * @param evolutionPrompt The new prompt for AI to generate updated traits.
     */
    function requestAuraEvolution(uint256 tokenId, string calldata evolutionPrompt) external payable {
        require(_exists(tokenId), "AuraForge: Token does not exist");
        require(msg.sender == ownerOf(tokenId), "AuraForge: Only owner can request evolution");
        require(msg.value >= evolutionFee, "AuraForge: Insufficient evolution fee");

        // Refund any excess payment
        if (msg.value > evolutionFee) {
            payable(msg.sender).transfer(msg.value - evolutionFee);
        }

        // Store the request. The AI oracle will pick this up.
        // Overwrite any previous pending request.
        pendingEvolutionRequests[tokenId] = EvolutionRequest({
            tokenId: tokenId,
            requester: msg.sender,
            prompt: evolutionPrompt,
            requestTimestamp: block.timestamp,
            fulfilled: false,
            fulfilledTraitsHash: bytes32(0),
            fulfilledMetadataURI: ""
        });

        emit EvolutionRequested(tokenId, msg.sender, evolutionPrompt, block.timestamp);
    }

    /**
     * @dev Fulfills an AI evolution request. Callable only by the trusted AI oracle.
     * Updates an Aura's traits and metadata after AI processing and proof verification.
     * The `oracleProof` is a placeholder for a more robust verification mechanism
     * (e.g., signature verification, ZKP, multi-sig oracle confirmation).
     * @param tokenId The ID of the Aura NFT to update.
     * @param newTraitsHash A hash representing the new set of traits generated by AI.
     * @param newMetadataURI The updated metadata URI generated by AI.
     * @param oracleProof A proof from the oracle verifying the AI's work.
     */
    function fulfillAuraEvolution(
        uint256 tokenId,
        bytes32 newTraitsHash,
        string calldata newMetadataURI,
        bytes calldata oracleProof // Placeholder for a real verification mechanism
    ) external onlyAIOracle {
        require(_exists(tokenId), "AuraForge: Token does not exist");
        require(pendingEvolutionRequests[tokenId].tokenId == tokenId && !pendingEvolutionRequests[tokenId].fulfilled, "AuraForge: No pending or fulfilled request for this token");

        // In a real system, `oracleProof` would be rigorously verified here.
        // e.g., using `ecrecover` with a signature from the oracle, or verifying a ZK proof.
        // For this example, `onlyAIOracle` implies trust in the sender.
        // The `oracleProof` could still be a hash of the input/output to prevent replay/tampering.
        bytes32 expectedProofHash = keccak256(abi.encodePacked(
            tokenId,
            newTraitsHash,
            newMetadataURI,
            pendingEvolutionRequests[tokenId].prompt,
            pendingEvolutionRequests[tokenId].requestTimestamp
        ));
        require(keccak256(oracleProof) == expectedProofHash, "AuraForge: Invalid oracle proof (conceptual)");


        Aura storage aura = auras[tokenId];
        aura.currentTraitsHash = newTraitsHash;
        aura.currentMetadataURI = newMetadataURI;
        aura.lastEvolutionTimestamp = block.timestamp;

        // Mark pending request as fulfilled and store results
        EvolutionRequest storage fulfilledReq = pendingEvolutionRequests[tokenId];
        fulfilledReq.fulfilled = true;
        fulfilledReq.fulfilledTraitsHash = newTraitsHash;
        fulfilledReq.fulfilledMetadataURI = newMetadataURI;

        // Add to history
        auraEvolutionHistory[tokenId].push(fulfilledReq);

        // Clear the pending request as it's now fulfilled
        delete pendingEvolutionRequests[tokenId]; // Or mark as fulfilled and leave in mapping for easier pending check

        emit EvolutionFulfilled(tokenId, newTraitsHash, newMetadataURI, block.timestamp);
    }

    /**
     * @dev Triggers an internal trait modification or unlock for an Aura based on its owner's reputation score.
     * This function would ideally interact with the AI Oracle to apply the reputation-based trait.
     * For simplicity, it just emits an event and conceptually applies the boost.
     * @param tokenId The ID of the Aura NFT.
     */
    function applyReputationBoost(uint256 tokenId) external {
        require(_exists(tokenId), "AuraForge: Token does not exist");
        require(msg.sender == ownerOf(tokenId), "AuraForge: Only owner can apply boost");

        uint256 ownerReputation = reputationScores[msg.sender];
        // Here, a more complex logic would check `reputationThresholdsForTraits`
        // and trigger a specific AI evolution prompt or direct trait update.
        // E.g., if (ownerReputation >= reputationThresholdsForTraits["HeroicAura"]) {
        //   requestAuraEvolution(tokenId, "Apply Heroic Aura trait based on reputation");
        // }

        emit ReputationBoostApplied(tokenId, msg.sender, ownerReputation);
        // Conceptual: a requestAuraEvolution would be triggered here with a special prompt
        // like "apply reputation-based trait for score X".
    }

    /**
     * @dev Defines a new category of traits that the AI can generate.
     * Callable only by the contract owner (or a governance module in a more complex setup).
     * @param categoryName The name of the new trait category (e.g., "Emotion", "Background").
     * @param initialKeywords Initial keywords to guide AI generation for this category.
     */
    function addTraitCategory(string calldata categoryName, string[] calldata initialKeywords) external onlyOwner {
        _traitCategoryIdCounter.increment();
        uint256 newCategoryId = _traitCategoryIdCounter.current();

        traitCategories[newCategoryId] = TraitCategory({
            name: categoryName,
            keywords: initialKeywords,
            creationTimestamp: block.timestamp,
            isActive: true
        });

        emit TraitCategoryAdded(newCategoryId, categoryName);
    }

    /**
     * @dev Returns a log of past evolution requests and their fulfillment status for a specific Aura.
     * @param tokenId The ID of the Aura NFT.
     * @return An array of EvolutionRequest structs.
     */
    function getAuraEvolutionHistory(uint256 tokenId) external view returns (EvolutionRequest[] memory) {
        return auraEvolutionHistory[tokenId];
    }

    // --- III. Reputation System ---

    /**
     * @dev Awards reputation points to a user.
     * This function would typically be called by another trusted protocol module,
     * or by the contract owner, to reward positive on-chain actions.
     * @param user The address of the user to award reputation to.
     * @param amount The amount of reputation points to add.
     */
    function increaseReputation(address user, uint256 amount) external onlyOwner { // Or replace with AccessControl roles
        require(user != address(0), "AuraForge: Cannot increase reputation for zero address");
        reputationScores[user] += amount;
        emit ReputationIncreased(user, reputationScores[user]);
    }

    /**
     * @dev Retrieves the current reputation score of a specified user.
     * @param user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address user) public view returns (uint256) {
        return reputationScores[user];
    }

    /**
     * @dev Links a reputation score threshold to the unlock of a specific trait for an Aura.
     * When an owner's reputation exceeds this threshold, they can apply the trait.
     * @param traitName The name of the trait to be unlocked.
     * @param threshold The reputation score required to unlock this trait.
     * @param traitHash A hash representing the specific trait's data (e.g., from IPFS).
     */
    function setReputationThresholdForTrait(
        string calldata traitName,
        uint256 threshold,
        bytes32 traitHash // Represents a specific trait, for AI to pick up
    ) external onlyOwner { // Or replace with AccessControl roles
        require(threshold > 0, "AuraForge: Threshold must be positive");
        // Store the trait hash linked to the name. The AI oracle would use this.
        reputationThresholdsForTraits[traitName] = threshold;
        // In a more complex system, we'd map traitName to traitHash more robustly.
    }


    // --- IV. Governance & Protocol Parameters ---

    /**
     * @dev Allows users to propose new thematic directions or styles for AI-generated traits.
     * Requires minimum reputation to propose.
     * @param themeName The name of the proposed theme.
     * @param themeDescription A description of the theme.
     * @param samplePrompts Example prompts demonstrating the theme.
     */
    function proposeNewTraitTheme(
        string calldata themeName,
        string calldata themeDescription,
        string[] calldata samplePrompts
    ) external onlyReputationEligible(msg.sender) {
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            name: themeName,
            description: themeDescription,
            samplePrompts: samplePrompts,
            proposer: msg.sender,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + VOTING_PERIOD,
            yeas: 0,
            nays: 0,
            executed: false,
            active: true
        });

        emit NewTraitThemeProposed(newProposalId, themeName, msg.sender);
    }

    /**
     * @dev Allows eligible participants to vote on open trait theme proposals.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes', false for 'no'.
     */
    function voteOnTraitThemeProposal(uint256 proposalId, bool support) external onlyReputationEligible(msg.sender) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.active, "AuraForge: Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime, "AuraForge: Voting has not started");
        require(block.timestamp <= proposal.voteEndTime, "AuraForge: Voting has ended");
        require(!proposal.hasVoted[msg.sender], "AuraForge: Already voted on this proposal");

        if (support) {
            proposal.yeas++;
        } else {
            proposal.nays++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @dev Finalizes and integrates a successfully voted-on trait theme.
     * Callable by owner (or a specific governor role).
     * Requires a simple majority for now.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeTraitThemeProposal(uint256 proposalId) external onlyOwner { // In a real DAO, this would be callable by anyone if conditions met
        Proposal storage proposal = proposals[proposalId];
        require(proposal.active, "AuraForge: Proposal is not active");
        require(block.timestamp > proposal.voteEndTime, "AuraForge: Voting period not over");
        require(!proposal.executed, "AuraForge: Proposal already executed");

        // Simple majority rule for demonstration
        require(proposal.yeas > proposal.nays, "AuraForge: Proposal did not pass");

        proposal.executed = true;
        proposal.active = false;

        // In a real system, this would trigger adding a new TraitCategory or updating existing ones,
        // effectively integrating the theme for AI generation.
        // For now, it's a conceptual "integration."
        _traitCategoryIdCounter.increment();
        uint256 newCategoryId = _traitCategoryIdCounter.current();
        traitCategories[newCategoryId] = TraitCategory({
            name: proposal.name,
            keywords: proposal.samplePrompts, // Using sample prompts as keywords
            creationTimestamp: block.timestamp,
            isActive: true
        });

        emit ProposalExecuted(proposalId);
        emit TraitCategoryAdded(newCategoryId, proposal.name);
    }

    /**
     * @dev Updates the address of the trusted AI oracle contract.
     * @param newOracle The new address for the AI oracle.
     */
    function setAIOracleAddress(address newOracle) external onlyOwner {
        require(newOracle != address(0), "AuraForge: New oracle cannot be zero address");
        emit AIOracleAddressUpdated(aiOracleAddress, newOracle);
        aiOracleAddress = newOracle;
    }

    /**
     * @dev Adjusts the fee required for requesting an Aura evolution.
     * @param fee The new evolution fee in wei.
     */
    function setEvolutionFee(uint256 fee) external onlyOwner {
        emit EvolutionFeeUpdated(evolutionFee, fee);
        evolutionFee = fee;
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated protocol fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address recipient) external onlyOwner {
        require(recipient != address(0), "AuraForge: Recipient cannot be zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "AuraForge: No fees to withdraw");
        payable(recipient).transfer(balance);
        emit FeesWithdrawn(recipient, balance);
    }

    // --- V. View & Utility Functions ---

    /**
     * @dev Returns the total number of Aura NFTs that have been minted.
     * @return The total supply of Aura NFTs.
     */
    function getTotalAurasMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Returns any outstanding evolution requests for a specific token that are awaiting oracle fulfillment.
     * Note: Returns the most recent pending request.
     * @param tokenId The ID of the Aura NFT.
     * @return An EvolutionRequest struct, empty if no pending request.
     */
    function getPendingEvolutionRequests(uint256 tokenId) public view returns (EvolutionRequest memory) {
        return pendingEvolutionRequests[tokenId];
    }

    /**
     * @dev Provides comprehensive details about a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint252 proposalId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            string memory description,
            string[] memory samplePrompts,
            address proposer,
            uint256 voteStartTime,
            uint256 voteEndTime,
            uint256 yeas,
            uint256 nays,
            bool executed,
            bool active
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.name,
            proposal.description,
            proposal.samplePrompts,
            proposal.proposer,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.yeas,
            proposal.nays,
            proposal.executed,
            proposal.active
        );
    }

    /**
     * @dev Internal function to set the base URI for all tokens.
     * @param baseURI_ The new base URI.
     */
    function _setBaseURI(string memory baseURI_) internal override {
        // This is a placeholder. In a dynamic NFT, the `tokenURI` function
        // is usually overridden to generate URIs on the fly,
        // potentially pointing to an API endpoint that renders the current state.
        // For AuraForge, `currentMetadataURI` in the Aura struct directly stores the dynamic URI.
        // So, this base URI might only be used as a fallback or for a fixed prefix.
        // We'll leave it as an empty implementation as per `tokenURI` override.
    }
}
```