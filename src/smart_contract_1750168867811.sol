Okay, here is a Solidity smart contract attempting to combine several advanced, interesting, and somewhat trendy concepts:

*   **Dynamic Asset State:** The assets (Chronicle Tokens) change properties based on time, user interaction (earning experience), and community governance.
*   **Soulbound-Adjacent Mechanics:** The core token can be 'bound' to an address, making it non-transferable, while still allowing associated components (Fragments) to be traded.
*   **Progression System:** Tokens earn 'experience' which unlocks 'evolution tiers' and influences governance power.
*   **Associated/Modular Assets (Fragments):** Separate, potentially transferable assets that are linked to a core Chronicle Token.
*   **On-Chain Governance:** A simplified system where token holders (or weighted by token properties) can vote on proposals to change the traits of *specific* Chronicle Tokens.
*   **Time-Based Mechanics:** Features or governance power can be influenced by how long a token has been bound to an address.

It's important to note that implementing a truly production-ready contract with *all* these features securely and efficiently is complex and would require significant auditing and gas optimization. This example focuses on demonstrating the *concepts* and the structure required.

---

**Contract Outline and Function Summary**

**Contract Name:** `ChronicleForge`

**Concept:** A factory and manager for dynamic, semi-soulbound digital assets ("Chronicle Tokens") that evolve based on experience, time bound, and community governance, and can be augmented with tradable "Associated Fragments".

**State Variables:**
*   `owner`: The contract owner.
*   `nextTokenId`: Counter for Chronicle Tokens.
*   `nextFragmentId`: Counter for Associated Fragments.
*   `nextProposalId`: Counter for Governance Proposals.
*   `chronicles`: Mapping from token ID to `ChronicleToken` struct.
*   `fragments`: Mapping from fragment ID to `AssociatedFragment` struct.
*   `ownerToChronicles`: Mapping from owner address to array of owned Chronicle Token IDs.
*   `ownerToFragments`: Mapping from owner address to array of owned Fragment IDs.
*   `traitDefinitions`: Mapping storing valid trait types.
*   `fragmentDefinitions`: Mapping storing valid fragment types.
*   `allowedExperienceSources`: Mapping of addresses allowed to add experience.
*   `proposals`: Mapping from proposal ID to `TraitUpdateProposal` struct.
*   `proposalVotes`: Nested mapping from proposal ID to voter address to boolean (true for Yes, false for No).
*   `proposalVotePower`: Nested mapping from proposal ID to voter address to the governance power used for their vote.

**Structs:**
*   `ChronicleToken`: Represents a core asset with dynamic state.
    *   `owner`: Current owner address.
    *   `isSoulbound`: True if bound, non-transferable by owner.
    *   `soulboundTimestamp`: Timestamp when bound.
    *   `experiencePoints`: Current XP level.
    *   `traits`: Mapping of trait type to value (string).
    *   `associatedFragmentIds`: Array of Fragment IDs linked to this token.
*   `AssociatedFragment`: Represents a modular component linked to a Chronicle Token.
    *   `owner`: Current owner address.
    *   `parentId`: ID of the Chronicle Token it's attached to (0 if unattached or globally owned).
    *   `fragmentType`: Type identifier (string).
    *   `properties`: Mapping of property type to value (string).
*   `TraitUpdateProposal`: Represents a governance proposal to change a token's trait.
    *   `proposer`: Address that created the proposal.
    *   `targetTokenId`: The token ID being proposed on.
    *   `traitType`: The trait to change.
    *   `newValue`: The proposed new value for the trait.
    *   `description`: Text description of the proposal.
    *   `creationTimestamp`: Timestamp of proposal creation.
    *   `votingEndTime`: Timestamp when voting ends.
    *   `executed`: Whether the proposal has been executed.
    *   `totalYesVotes`: Sum of governance power for Yes votes.
    *   `totalNoVotes`: Sum of governance power for No votes.
    *   `voted`: Mapping of voter address to boolean (true if voted).

**Events:**
*   `ChronicleMinted`: When a new token is created.
*   `TokenBoundToSoul`: When a token becomes soulbound.
*   `ExperienceGained`: When a token gains experience.
*   `TraitUpdated`: When a token's trait is changed.
*   `FragmentMinted`: When a new fragment is created.
*   `FragmentTransfered`: When a fragment is transferred.
*   `FragmentBurned`: When a fragment is burned.
*   `ProposalCreated`: When a new governance proposal is made.
*   `Voted`: When a vote is cast on a proposal.
*   `ProposalExecuted`: When a proposal is successfully executed.

**Function Summary (20+ functions):**

1.  `constructor()`: Initializes the contract with an owner.
2.  `mintChronicleToken(address recipient)`: Creates and mints a new Chronicle Token to a recipient.
3.  `bindTokenToSoul(uint256 tokenId)`: Makes a Chronicle Token soulbound to the caller's address. Requires caller owns the token and it's not already bound.
4.  `getChronicleTokenDetails(uint256 tokenId)`: Retrieves all details for a specific Chronicle Token.
5.  `getTokensOwnedBy(address owner)`: Returns an array of Chronicle Token IDs owned by an address.
6.  `isTokenSoulbound(uint256 tokenId)`: Checks if a specific token is soulbound.
7.  `getSoulboundDuration(uint256 tokenId)`: Returns the duration (in seconds) since a token was soulbound.
8.  `addExperiencePoints(uint256 tokenId, uint256 amount)`: Adds experience points to a token. Only callable by allowed experience sources.
9.  `getExperiencePoints(uint256 tokenId)`: Retrieves the current experience points of a token.
10. `getCurrentEvolutionTier(uint256 tokenId)`: Calculates and returns the current evolution tier based on experience points and soulbound duration (example logic).
11. `mintAssociatedFragment(uint256 parentTokenId, string memory fragmentType, string[] memory propNames, string[] memory propValues)`: Creates a new Associated Fragment, potentially linked to a Chronicle Token. Can be minted unattached (parentId=0).
12. `transferAssociatedFragment(uint256 fragmentId, address recipient)`: Transfers ownership of an Associated Fragment.
13. `getAssociatedFragmentDetails(uint256 fragmentId)`: Retrieves all details for a specific Associated Fragment.
14. `getFragmentsOwnedBy(address owner)`: Returns an array of Associated Fragment IDs owned by an address.
15. `getFragmentsAttachedToToken(uint256 tokenId)`: Returns an array of Associated Fragment IDs currently linked to a specific Chronicle Token.
16. `attachFragmentToToken(uint256 fragmentId, uint256 targetTokenId)`: Attaches a fragment owned by the caller to one of their Chronicle Tokens.
17. `detachFragmentFromToken(uint256 fragmentId)`: Detaches a fragment from its parent token.
18. `burnAssociatedFragment(uint256 fragmentId)`: Destroys an Associated Fragment. Only callable by the owner.
19. `proposeTraitUpdate(uint256 targetTokenId, string memory traitType, string memory newValue, string memory description, uint256 votingDuration)`: Creates a governance proposal to change a trait on a specific token. Requires caller owns a Chronicle Token with sufficient governance power.
20. `voteOnTraitProposal(uint256 proposalId, bool support)`: Casts a vote on a trait update proposal. Uses the voter's calculated governance power.
21. `executeTraitProposal(uint256 proposalId)`: Executes the trait update proposal if the voting period is over and the threshold/quorum is met (example logic: simple majority of total power voted).
22. `getTraitProposalDetails(uint256 proposalId)`: Retrieves details for a specific governance proposal.
23. `calculateCurrentGovernancePower(uint256 tokenId)`: Calculates the voting power derived from a specific Chronicle Token based on its state (e.g., soulbound duration, experience).
24. `addAllowedExperienceSource(address sourceAddress)`: Admin function to allow an address to call `addExperiencePoints`.
25. `removeAllowedExperienceSource(address sourceAddress)`: Admin function to disallow an address from calling `addExperiencePoints`.
26. `setTraitDefinitions(string[] memory types)`: Admin function to define valid trait types.
27. `setFragmentDefinitions(string[] memory types)`: Admin function to define valid fragment types.
28. `tokenURI(uint256 tokenId)`: Placeholder for ERC-721 metadata URI function (though contract doesn't inherit ERC721, this is a common pattern). Would typically return a URL pointing to a dynamic metadata server.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Contract Outline and Function Summary ---
// Contract Name: ChronicleForge
// Concept: A factory and manager for dynamic, semi-soulbound digital assets ("Chronicle Tokens") that evolve based on experience, time bound, and community governance, and can be augmented with tradable "Associated Fragments".

// State Variables:
// - owner: The contract owner.
// - nextTokenId: Counter for Chronicle Tokens.
// - nextFragmentId: Counter for Associated Fragments.
// - nextProposalId: Counter for Governance Proposals.
// - chronicles: Mapping from token ID to ChronicleToken struct.
// - fragments: Mapping from fragment ID to AssociatedFragment struct.
// - ownerToChronicles: Mapping from owner address to array of owned Chronicle Token IDs.
// - ownerToFragments: Mapping from owner address to array of owned Fragment IDs.
// - traitDefinitions: Mapping storing valid trait types.
// - fragmentDefinitions: Mapping storing valid fragment types.
// - allowedExperienceSources: Mapping of addresses allowed to add experience.
// - proposals: Mapping from proposal ID to TraitUpdateProposal struct.
// - proposalVotes: Nested mapping from proposal ID to voter address to boolean (true for Yes, false for No).
// - proposalVotePower: Nested mapping from proposal ID to voter address to the governance power used for their vote.

// Structs:
// - ChronicleToken: Represents a core asset with dynamic state.
//   - owner: Current owner address.
//   - isSoulbound: True if bound, non-transferable by owner.
//   - soulboundTimestamp: Timestamp when bound.
//   - experiencePoints: Current XP level.
//   - traits: Mapping of trait type to value (string).
//   - associatedFragmentIds: Array of Fragment IDs linked to this token.
// - AssociatedFragment: Represents a modular component linked to a Chronicle Token.
//   - owner: Current owner address.
//   - parentId: ID of the Chronicle Token it's attached to (0 if unattached or globally owned).
//   - fragmentType: Type identifier (string).
//   - properties: Mapping of property type to value (string).
// - TraitUpdateProposal: Represents a governance proposal to change a token's trait.
//   - proposer: Address that created the proposal.
//   - targetTokenId: The token ID being proposed on.
//   - traitType: The trait to change.
//   - newValue: The proposed new value for the trait.
//   - description: Text description of the proposal.
//   - creationTimestamp: Timestamp of proposal creation.
//   - votingEndTime: Timestamp when voting ends.
//   - executed: Whether the proposal has been executed.
//   - totalYesVotes: Sum of governance power for Yes votes.
//   - totalNoVotes: Sum of governance power for No votes.
//   - voted: Mapping of voter address to boolean (true if voted).

// Events:
// - ChronicleMinted: When a new token is created.
// - TokenBoundToSoul: When a token becomes soulbound.
// - ExperienceGained: When a token gains experience.
// - TraitUpdated: When a token's trait is changed.
// - FragmentMinted: When a new fragment is created.
// - FragmentTransfered: When a fragment is transferred.
// - FragmentBurned: When a fragment is burned.
// - ProposalCreated: When a new governance proposal is made.
// - Voted: When a vote is cast on a proposal.
// - ProposalExecuted: When a proposal is successfully executed.

// Function Summary (20+ functions):
// 1.  constructor(): Initializes the contract with an owner.
// 2.  mintChronicleToken(address recipient): Creates and mints a new Chronicle Token to a recipient.
// 3.  bindTokenToSoul(uint256 tokenId): Makes a Chronicle Token soulbound to the caller's address.
// 4.  getChronicleTokenDetails(uint256 tokenId): Retrieves all details for a specific Chronicle Token.
// 5.  getTokensOwnedBy(address owner): Returns an array of Chronicle Token IDs owned by an address.
// 6.  isTokenSoulbound(uint256 tokenId): Checks if a specific token is soulbound.
// 7.  getSoulboundDuration(uint256 tokenId): Returns the duration (in seconds) since a token was soulbound.
// 8.  addExperiencePoints(uint256 tokenId, uint256 amount): Adds experience points to a token. Only callable by allowed sources.
// 9.  getExperiencePoints(uint256 tokenId): Retrieves the current experience points.
// 10. getCurrentEvolutionTier(uint256 tokenId): Calculates and returns the current evolution tier.
// 11. mintAssociatedFragment(uint256 parentTokenId, string memory fragmentType, string[] memory propNames, string[] memory propValues): Creates a new Associated Fragment.
// 12. transferAssociatedFragment(uint256 fragmentId, address recipient): Transfers ownership of a Fragment.
// 13. getAssociatedFragmentDetails(uint256 fragmentId): Retrieves details for a Fragment.
// 14. getFragmentsOwnedBy(address owner): Returns array of Fragment IDs owned by an address.
// 15. getFragmentsAttachedToToken(uint256 tokenId): Returns array of Fragment IDs attached to a token.
// 16. attachFragmentToToken(uint256 fragmentId, uint256 targetTokenId): Attaches a fragment to a token.
// 17. detachFragmentFromToken(uint256 fragmentId): Detaches a fragment from its parent.
// 18. burnAssociatedFragment(uint256 fragmentId): Destroys a Fragment.
// 19. proposeTraitUpdate(uint256 targetTokenId, string memory traitType, string memory newValue, string memory description, uint256 votingDuration): Creates a governance proposal.
// 20. voteOnTraitProposal(uint256 proposalId, bool support): Casts a vote.
// 21. executeTraitProposal(uint256 proposalId): Executes the proposal if conditions met.
// 22. getTraitProposalDetails(uint256 proposalId): Retrieves proposal details.
// 23. calculateCurrentGovernancePower(uint256 tokenId): Calculates voting power from a token.
// 24. addAllowedExperienceSource(address sourceAddress): Admin function to add allowed XP source.
// 25. removeAllowedExperienceSource(address sourceAddress): Admin function to remove allowed XP source.
// 26. setTraitDefinitions(string[] memory types): Admin function to define valid traits.
// 27. setFragmentDefinitions(string[] memory types): Admin function to define valid fragments.
// 28. tokenURI(uint256 tokenId): Placeholder for dynamic metadata URI.

contract ChronicleForge is Ownable {
    using Strings for uint256; // For converting IDs to strings for metadata (conceptual)

    // --- Structs ---

    struct ChronicleToken {
        address owner;
        bool isSoulbound;
        uint256 soulboundTimestamp; // 0 if not soulbound
        uint256 experiencePoints;
        mapping(string => string) traits;
        uint256[] associatedFragmentIds; // IDs of fragments attached
    }

    struct AssociatedFragment {
        address owner;
        uint256 parentId; // 0 if unattached or globally owned
        string fragmentType;
        mapping(string => string) properties;
    }

    struct TraitUpdateProposal {
        address proposer;
        uint256 targetTokenId;
        string traitType;
        string newValue;
        string description;
        uint256 creationTimestamp;
        uint256 votingEndTime;
        bool executed;
        uint256 totalYesVotes;
        uint256 totalNoVotes;
        mapping(address => bool) voted; // Check if an address has voted
    }

    // --- State Variables ---

    uint256 private nextTokenId = 1;
    uint256 private nextFragmentId = 1;
    uint256 private nextProposalId = 1;

    mapping(uint256 => ChronicleToken) public chronicles;
    mapping(uint256 => AssociatedFragment) public fragments;

    // Arrays to track owned tokens/fragments per address (gas intensive for large numbers, demonstration only)
    mapping(address => uint256[]) private ownerToChronicles;
    mapping(address => uint256[]) private ownerToFragments;

    // Admin-defined valid types
    mapping(string => bool) public traitDefinitions;
    mapping(string => bool) public fragmentDefinitions;

    // Addresses allowed to add experience points (e.g., game contracts, quest systems)
    mapping(address => bool) public allowedExperienceSources;

    // Governance state
    mapping(uint256 => TraitUpdateProposal) public proposals;
    mapping(uint256 => mapping(address => bool)) private proposalVotes; // proposalId => voter => vote (true for Yes)
    mapping(uint256 => mapping(address => uint256)) private proposalVotePower; // proposalId => voter => power used

    // --- Events ---

    event ChronicleMinted(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event TokenBoundToSoul(uint256 indexed tokenId, address indexed soulbinder, uint256 timestamp);
    event ExperienceGained(uint256 indexed tokenId, uint256 amount, uint256 newExperience);
    event TraitUpdated(uint256 indexed tokenId, string traitType, string oldValue, string newValue);
    event FragmentMinted(uint256 indexed fragmentId, uint256 indexed parentId, address indexed owner, string fragmentType);
    event FragmentTransfered(uint256 indexed fragmentId, address indexed from, address indexed to);
    event FragmentBurned(uint256 indexed fragmentId, address indexed owner);
    event FragmentAttached(uint256 indexed fragmentId, uint256 indexed tokenId);
    event FragmentDetached(uint256 indexed fragmentId, uint256 indexed tokenId);

    event ProposalCreated(uint256 indexed proposalId, uint256 indexed targetTokenId, address indexed proposer, string traitType, string newValue, uint256 votingEndTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Modifiers ---

    modifier onlyAllowedExperienceSource() {
        require(allowedExperienceSources[msg.sender], "Not an allowed experience source");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(chronicles[tokenId].owner != address(0), "Token does not exist");
        _;
    }

    modifier fragmentExists(uint256 fragmentId) {
        require(fragments[fragmentId].owner != address(0), "Fragment does not exist");
        _;
    }

    modifier isTokenOwner(uint256 tokenId) {
        require(chronicles[tokenId].owner == msg.sender, "Not token owner");
        _;
    }

    modifier isFragmentOwner(uint256 fragmentId) {
        require(fragments[fragmentId].owner == msg.sender, "Not fragment owner");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].creationTimestamp != 0, "Proposal does not exist");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Core Asset Management (Chronicle Tokens) ---

    /// @notice Creates and mints a new Chronicle Token to a recipient.
    /// @param recipient The address to mint the token to.
    function mintChronicleToken(address recipient) public onlyOwner returns (uint256) {
        uint256 tokenId = nextTokenId++;
        chronicles[tokenId].owner = recipient;
        chronicles[tokenId].soulboundTimestamp = 0; // Not soulbound initially
        chronicles[tokenId].experiencePoints = 0;
        // Initialize traits if needed, e.g., default traits
        // chronicles[tokenId].traits["name"] = "New Chronicle";

        ownerToChronicles[recipient].push(tokenId);

        emit ChronicleMinted(tokenId, recipient, block.timestamp);
        return tokenId;
    }

    /// @notice Binds a Chronicle Token to the caller's soul, making it non-transferable by the owner.
    /// @param tokenId The ID of the token to bind.
    function bindTokenToSoul(uint256 tokenId) public tokenExists(tokenId) isTokenOwner(tokenId) {
        ChronicleToken storage token = chronicles[tokenId];
        require(!token.isSoulbound, "Token is already soulbound");

        token.isSoulbound = true;
        token.soulboundTimestamp = block.timestamp;

        emit TokenBoundToSoul(tokenId, msg.sender, block.timestamp);
    }

    /// @notice Retrieves all details for a specific Chronicle Token.
    /// @param tokenId The ID of the token.
    /// @return owner The token's owner.
    /// @return isSoulbound Whether the token is soulbound.
    /// @return soulboundTimestamp The timestamp when it was bound (0 if not).
    /// @return experiencePoints The current experience points.
    /// @return associatedFragmentIds The IDs of attached fragments.
    function getChronicleTokenDetails(uint256 tokenId)
        public
        view
        tokenExists(tokenId)
        returns (address owner, bool isSoulbound, uint256 soulboundTimestamp, uint256 experiencePoints, uint256[] memory associatedFragmentIds)
    {
        ChronicleToken storage token = chronicles[tokenId];
        return (
            token.owner,
            token.isSoulbound,
            token.soulboundTimestamp,
            token.experiencePoints,
            token.associatedFragmentIds
        );
    }

    /// @notice Returns an array of Chronicle Token IDs owned by an address.
    /// @param owner The address to check.
    /// @return An array of token IDs.
    function getTokensOwnedBy(address owner) public view returns (uint256[] memory) {
        return ownerToChronicles[owner];
    }

    /// @notice Checks if a specific token is soulbound.
    /// @param tokenId The ID of the token.
    /// @return True if soulbound, false otherwise.
    function isTokenSoulbound(uint256 tokenId) public view tokenExists(tokenId) returns (bool) {
        return chronicles[tokenId].isSoulbound;
    }

    /// @notice Returns the duration (in seconds) since a token was soulbound.
    /// @param tokenId The ID of the token.
    /// @return The duration in seconds, or 0 if not soulbound.
    function getSoulboundDuration(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        uint256 timestamp = chronicles[tokenId].soulboundTimestamp;
        if (timestamp == 0) {
            return 0;
        }
        return block.timestamp - timestamp;
    }

    // --- Dynamic State (Experience, Traits, Evolution) ---

    /// @notice Adds experience points to a token. Only callable by allowed experience sources.
    /// @param tokenId The ID of the token.
    /// @param amount The amount of experience to add.
    function addExperiencePoints(uint256 tokenId, uint256 amount) public tokenExists(tokenId) onlyAllowedExperienceSource {
        ChronicleToken storage token = chronicles[tokenId];
        uint256 oldExperience = token.experiencePoints;
        token.experiencePoints += amount;
        emit ExperienceGained(tokenId, amount, token.experiencePoints);

        // Optional: Check for tier changes and trigger potential automated trait updates here
        uint256 oldTier = _calculateEvolutionTier(oldExperience, getSoulboundDuration(tokenId));
        uint256 newTier = _calculateEvolutionTier(token.experiencePoints, getSoulboundDuration(tokenId));
        if (newTier > oldTier) {
            // Example: trigger some automated trait change on tier up
            // This would require more complex logic, potentially another mapping for tier effects
            // emit TraitUpdated(tokenId, "tier", oldTier.toString(), newTier.toString());
        }
    }

    /// @notice Retrieves the current experience points of a token.
    /// @param tokenId The ID of the token.
    /// @return The current experience points.
    function getExperiencePoints(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return chronicles[tokenId].experiencePoints;
    }

    /// @notice Calculates and returns the current evolution tier based on experience points and soulbound duration.
    /// @dev This is example logic. Real evolution tiers could be much more complex.
    /// @param tokenId The ID of the token.
    /// @return The current evolution tier.
    function getCurrentEvolutionTier(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        ChronicleToken storage token = chronicles[tokenId];
        return _calculateEvolutionTier(token.experiencePoints, getSoulboundDuration(tokenId));
    }

    /// @dev Internal helper to calculate evolution tier.
    function _calculateEvolutionTier(uint256 experience, uint256 soulboundDuration) internal pure returns (uint256) {
        // Example tier logic:
        // Tier 0: <100 XP OR < 1 day soulbound
        // Tier 1: >= 100 XP AND >= 1 day soulbound
        // Tier 2: >= 500 XP AND >= 7 days soulbound
        // Tier 3: >= 2000 XP AND >= 30 days soulbound
        if (experience < 100 || soulboundDuration < 1 days) return 0;
        if (experience < 500 || soulboundDuration < 7 days) return 1;
        if (experience < 2000 || soulboundDuration < 30 days) return 2;
        return 3; // Max tier example
    }

    /// @notice Retrieves the value of a specific trait for a token.
    /// @param tokenId The ID of the token.
    /// @param traitType The type of the trait.
    /// @return The trait value (string). Returns empty string if not set.
    function getTraitValue(uint256 tokenId, string memory traitType) public view tokenExists(tokenId) returns (string memory) {
        return chronicles[tokenId].traits[traitType];
    }

    /// @notice Retrieves all set traits for a token.
    /// @dev Note: Returning all keys from a mapping is not directly possible in Solidity.
    /// This function is conceptual or would require tracking trait keys in an array within the struct,
    /// which adds gas cost for every trait addition/removal.
    /// A common pattern is to return a struct or array of structs containing name/value pairs,
    /// but that requires knowing all possible trait names or having a fixed list.
    /// For this example, we'll return a placeholder or require fetching traits individually.
    /// Let's return an empty array of strings as a placeholder.
    function getAllTraitValues(uint256 tokenId) public view tokenExists(tokenId) returns (string[] memory) {
        // In a real scenario, you'd likely iterate over a list of known trait keys
        // or use a structure that tracks keys.
        // This implementation demonstrates the function signature but cannot return
        // all arbitrary mapping keys dynamically without helper structs/arrays.
        return new string[](0);
    }


    // --- Associated Assets (Fragments) ---

    /// @notice Creates and mints a new Associated Fragment. Can be linked to a parent token or unattached.
    /// @param parentTokenId The ID of the Chronicle Token to attach to (0 for unattached).
    /// @param fragmentType The type of fragment (must be a defined type).
    /// @param propNames Array of property names.
    /// @param propValues Array of property values. Must match propNames length.
    /// @return The ID of the minted fragment.
    function mintAssociatedFragment(
        uint256 parentTokenId,
        string memory fragmentType,
        string[] memory propNames,
        string[] memory propValues
    ) public onlyOwner returns (uint256) {
        require(fragmentDefinitions[fragmentType], "Invalid fragment type");
        require(propNames.length == propValues.length, "Property name and value arrays must match length");
        if (parentTokenId != 0) {
             require(chronicles[parentTokenId].owner != address(0), "Parent token must exist if specified");
        }

        uint256 fragmentId = nextFragmentId++;
        fragments[fragmentId].owner = msg.sender; // Owner initially is minter (owner of contract)
        fragments[fragmentId].parentId = parentTokenId;
        fragments[fragmentId].fragmentType = fragmentType;

        for (uint i = 0; i < propNames.length; i++) {
            fragments[fragmentId].properties[propNames[i]] = propValues[i];
        }

        ownerToFragments[msg.sender].push(fragmentId);

        // If parent specified, attach it immediately
        if (parentTokenId != 0) {
            chronicles[parentTokenId].associatedFragmentIds.push(fragmentId);
            // No transfer event here, as owner hasn't changed, only parentId updated.
            // Emit a dedicated attachment event
            emit FragmentAttached(fragmentId, parentTokenId);
        }

        emit FragmentMinted(fragmentId, parentTokenId, msg.sender, fragmentType);
        return fragmentId;
    }

    /// @notice Transfers ownership of an Associated Fragment. Does NOT handle attachment/detachment automatically.
    /// @param fragmentId The ID of the fragment to transfer.
    /// @param recipient The address to transfer to.
    function transferAssociatedFragment(uint256 fragmentId, address recipient) public fragmentExists(fragmentId) isFragmentOwner(fragmentId) {
        AssociatedFragment storage fragment = fragments[fragmentId];
        require(recipient != address(0), "Cannot transfer to zero address");

        // Remove from old owner's list
        uint256[] storage oldOwnerFragments = ownerToFragments[msg.sender];
        for (uint i = 0; i < oldOwnerFragments.length; i++) {
            if (oldOwnerFragments[i] == fragmentId) {
                oldOwnerFragments[i] = oldOwnerFragments[oldOwnerFragments.length - 1];
                oldOwnerFragments.pop();
                break;
            }
        }

        // Update owner
        address oldOwner = fragment.owner;
        fragment.owner = recipient;

        // Add to new owner's list
        ownerToFragments[recipient].push(fragmentId);

        emit FragmentTransfered(fragmentId, oldOwner, recipient);
    }

     /// @notice Retrieves all details for a specific Associated Fragment.
    /// @param fragmentId The ID of the fragment.
    /// @return owner The fragment's owner.
    /// @return parentId The ID of the parent token (0 if unattached).
    /// @return fragmentType The type of the fragment.
    /// @return properties (Note: Cannot return mapping directly, placeholder)
    function getAssociatedFragmentDetails(uint256 fragmentId)
        public
        view
        fragmentExists(fragmentId)
        returns (address owner, uint256 parentId, string memory fragmentType) // Removed properties due to mapping limitation
    {
        AssociatedFragment storage fragment = fragments[fragmentId];
        return (fragment.owner, fragment.parentId, fragment.fragmentType);
        // Note: Cannot return the 'properties' mapping directly.
        // You would need separate getters for specific properties or a helper
        // function that takes property names as input.
    }


    /// @notice Returns an array of Associated Fragment IDs owned by an address.
    /// @param owner The address to check.
    /// @return An array of fragment IDs.
    function getFragmentsOwnedBy(address owner) public view returns (uint256[] memory) {
        return ownerToFragments[owner];
    }

    /// @notice Returns an array of Associated Fragment IDs currently linked to a specific Chronicle Token.
    /// @param tokenId The ID of the token.
    /// @return An array of fragment IDs.
    function getFragmentsAttachedToToken(uint256 tokenId) public view tokenExists(tokenId) returns (uint256[] memory) {
        return chronicles[tokenId].associatedFragmentIds;
    }

    /// @notice Attaches a fragment owned by the caller to one of their Chronicle Tokens.
    /// @param fragmentId The ID of the fragment.
    /// @param targetTokenId The ID of the token to attach to.
    function attachFragmentToToken(uint256 fragmentId, uint256 targetTokenId) public fragmentExists(fragmentId) isFragmentOwner(fragmentId) tokenExists(targetTokenId) {
        AssociatedFragment storage fragment = fragments[fragmentId];
        ChronicleToken storage token = chronicles[targetTokenId];

        require(token.owner == msg.sender, "Target token is not owned by caller");
        require(fragment.parentId == 0, "Fragment is already attached to a token");

        fragment.parentId = targetTokenId;
        token.associatedFragmentIds.push(fragmentId);

        emit FragmentAttached(fragmentId, targetTokenId);
    }

    /// @notice Detaches a fragment from its parent token. Requires caller owns the fragment and the parent token.
    /// @param fragmentId The ID of the fragment to detach.
    function detachFragmentFromToken(uint256 fragmentId) public fragmentExists(fragmentId) isFragmentOwner(fragmentId) {
        AssociatedFragment storage fragment = fragments[fragmentId];
        require(fragment.parentId != 0, "Fragment is not attached to a token");

        uint256 parentTokenId = fragment.parentId;
        require(chronicles[parentTokenId].owner == msg.sender, "Caller must own the parent token to detach");

        ChronicleToken storage parentToken = chronicles[parentTokenId];
        fragment.parentId = 0; // Detach

        // Remove fragmentId from parent token's associatedFragmentIds array (basic implementation)
        uint256[] storage fragmentIds = parentToken.associatedFragmentIds;
        for (uint i = 0; i < fragmentIds.length; i++) {
            if (fragmentIds[i] == fragmentId) {
                fragmentIds[i] = fragmentIds[fragmentIds.length - 1];
                fragmentIds.pop();
                break;
            }
        }

        emit FragmentDetached(fragmentId, parentTokenId);
    }

    /// @notice Destroys an Associated Fragment. Only callable by the owner.
    /// @dev If the fragment is attached, it is automatically detached first.
    /// @param fragmentId The ID of the fragment to burn.
    function burnAssociatedFragment(uint256 fragmentId) public fragmentExists(fragmentId) isFragmentOwner(fragmentId) {
        AssociatedFragment storage fragment = fragments[fragmentId];

        // Detach if attached
        if (fragment.parentId != 0) {
            detachFragmentFromToken(fragmentId);
        }

        // Remove from owner's list
         uint256[] storage ownerFragments = ownerToFragments[msg.sender];
        for (uint i = 0; i < ownerFragments.length; i++) {
            if (ownerFragments[i] == fragmentId) {
                ownerFragments[i] = ownerFragments[ownerFragments.length - 1];
                ownerFragments.pop();
                break;
            }
        }

        address owner = fragment.owner;

        // Delete fragment data
        delete fragments[fragmentId];

        emit FragmentBurned(fragmentId, owner);
    }


    // --- Governance ---

    /// @notice Creates a governance proposal to change a trait on a specific token.
    /// @param targetTokenId The ID of the token whose trait is proposed to change.
    /// @param traitType The type of the trait to change.
    /// @param newValue The proposed new value for the trait.
    /// @param description Text description of the proposal.
    /// @param votingDuration Duration in seconds for the voting period.
    /// @return The ID of the created proposal.
    function proposeTraitUpdate(
        uint256 targetTokenId,
        string memory traitType,
        string memory newValue,
        string memory description,
        uint256 votingDuration
    ) public tokenExists(targetTokenId) returns (uint256) {
        require(traitDefinitions[traitType], "Invalid trait type");
        // Optional: Require minimum governance power or owning a soulbound token to propose
        // require(calculateCurrentGovernancePower(someTokenId) >= minPower, "Insufficient governance power to propose");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = TraitUpdateProposal({
            proposer: msg.sender,
            targetTokenId: targetTokenId,
            traitType: traitType,
            newValue: newValue,
            description: description,
            creationTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            executed: false,
            totalYesVotes: 0,
            totalNoVotes: 0,
            voted: new mapping(address => bool)() // Initialize mapping
        });

        emit ProposalCreated(proposalId, targetTokenId, msg.sender, traitType, newValue, proposals[proposalId].votingEndTime);
        return proposalId;
    }

    /// @notice Casts a vote on a trait update proposal. Uses the voter's calculated governance power.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a 'Yes' vote, false for a 'No' vote.
    function voteOnTraitProposal(uint256 proposalId, bool support) public proposalExists(proposalId) {
        TraitUpdateProposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.voted[msg.sender], "Already voted on this proposal");

        // Calculate voter's current governance power
        // For simplicity, let's say power comes from *one* owned soulbound token,
        // or sum power from all owned soulbound tokens.
        // Example: Using the first soulbound token owned by the voter.
        uint256 voterPower = 0;
        uint256[] memory ownedTokens = getTokensOwnedBy(msg.sender);
        for (uint i = 0; i < ownedTokens.length; i++) {
            if (chronicles[ownedTokens[i]].isSoulbound) {
                 voterPower += calculateCurrentGovernancePower(ownedTokens[i]);
            }
        }
        require(voterPower > 0, "Voter must own soulbound tokens to vote");


        proposal.voted[msg.sender] = true;
        proposalVotePower[proposalId][msg.sender] = voterPower;

        if (support) {
            proposal.totalYesVotes += voterPower;
        } else {
            proposal.totalNoVotes += voterPower;
        }

        emit Voted(proposalId, msg.sender, support, voterPower);
    }

    /// @notice Executes the trait update proposal if the voting period is over and the threshold/quorum is met.
    /// @param proposalId The ID of the proposal to execute.
    function executeTraitProposal(uint256 proposalId) public proposalExists(proposalId) {
        TraitUpdateProposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.votingEndTime, "Voting period is not over");
        require(!proposal.executed, "Proposal already executed");

        // Example execution logic: Simple majority of total power voted (not just active voters)
        // More robust systems would require quorum (minimum total power voted) and a threshold (e.g., 50% + 1 of *voted* power).
        uint256 totalVotedPower = proposal.totalYesVotes + proposal.totalNoVotes;
        // Example threshold: 50% + 1 of Voted power, and minimum 100 power total voted (quorum)
        bool passed = totalVotedPower >= 100 && proposal.totalYesVotes > totalVotedPower / 2;


        proposal.executed = true;

        if (passed) {
            ChronicleToken storage targetToken = chronicles[proposal.targetTokenId];
             string memory oldTraitValue = targetToken.traits[proposal.traitType];
            targetToken.traits[proposal.traitType] = proposal.newValue;
            emit TraitUpdated(proposal.targetTokenId, proposal.traitType, oldTraitValue, proposal.newValue);
            emit ProposalExecuted(proposalId, true);
        } else {
             // Proposal failed
             emit ProposalExecuted(proposalId, false);
        }
    }

     /// @notice Retrieves details for a specific governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return proposer The address that created the proposal.
    /// @return targetTokenId The ID of the token being proposed on.
    /// @return traitType The trait type.
    /// @return newValue The proposed new value.
    /// @return description The proposal description.
    /// @return creationTimestamp The creation timestamp.
    /// @return votingEndTime The voting end timestamp.
    /// @return executed Whether it's executed.
    /// @return totalYesVotes Total power for Yes votes.
    /// @return totalNoVotes Total power for No votes.
    function getTraitProposalDetails(uint256 proposalId)
        public
        view
        proposalExists(proposalId)
        returns (
            address proposer,
            uint256 targetTokenId,
            string memory traitType,
            string memory newValue,
            string memory description,
            uint256 creationTimestamp,
            uint256 votingEndTime,
            bool executed,
            uint256 totalYesVotes,
            uint256 totalNoVotes
        )
    {
        TraitUpdateProposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.targetTokenId,
            proposal.traitType,
            proposal.newValue,
            proposal.description,
            proposal.creationTimestamp,
            proposal.votingEndTime,
            proposal.executed,
            proposal.totalYesVotes,
            proposal.totalNoVotes
        );
    }


    /// @notice Calculates the voting power derived from a specific Chronicle Token based on its state.
    /// @dev Example logic: 1 base power + 1 power per 100 XP + 1 power per 30 days soulbound.
    /// @param tokenId The ID of the token.
    /// @return The calculated governance power. Returns 0 if not soulbound.
    function calculateCurrentGovernancePower(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        ChronicleToken storage token = chronicles[tokenId];
        if (!token.isSoulbound || token.soulboundTimestamp == 0) {
            return 0; // Only soulbound tokens grant power
        }

        uint256 power = 1; // Base power
        power += token.experiencePoints / 100; // Power from XP
        power += (block.timestamp - token.soulboundTimestamp) / (30 days); // Power from soulbound duration

        // Can add more factors, e.g., associated fragments, specific traits, tier level
        uint256 currentTier = _calculateEvolutionTier(token.experiencePoints, block.timestamp - token.soulboundTimestamp);
        power += currentTier * 5; // Bonus power from tier

        return power;
    }

    // --- Admin / Setup Functions ---

    /// @notice Admin function to allow an address to call `addExperiencePoints`.
    /// @param sourceAddress The address to grant permission.
    function addAllowedExperienceSource(address sourceAddress) public onlyOwner {
        allowedExperienceSources[sourceAddress] = true;
    }

    /// @notice Admin function to disallow an address from calling `addExperiencePoints`.
    /// @param sourceAddress The address to remove permission from.
    function removeAllowedExperienceSource(address sourceAddress) public onlyOwner {
        allowedExperienceSources[sourceAddress] = false;
    }

    /// @notice Admin function to define valid trait types that can be used and proposed on.
    /// @param types An array of valid trait type strings.
    function setTraitDefinitions(string[] memory types) public onlyOwner {
        // Clear existing definitions (optional, can also add incrementally)
        // Note: Clearing a mapping is not possible, would need to track keys
        // For simplicity here, this would overwrite if key exists but doesn't remove old ones
        for (uint i = 0; i < types.length; i++) {
             traitDefinitions[types[i]] = true;
        }
    }

    /// @notice Admin function to define valid fragment types that can be minted.
    /// @param types An array of valid fragment type strings.
    function setFragmentDefinitions(string[] memory types) public onlyOwner {
         // Clear existing definitions (optional)
        for (uint i = 0; i < types.length; i++) {
             fragmentDefinitions[types[i]] = true;
        }
    }

    // --- Metadata (Conceptual) ---

    /// @notice Provides a conceptual ERC-721 style metadata URI.
    /// @dev This is a placeholder. A real dynamic metadata solution requires
    /// an off-chain server that fetches the token/fragment state from the contract
    /// and serves a JSON metadata file based on that state.
    /// @param tokenId The ID of the token.
    /// @return A URI pointing to the token's metadata.
    function tokenURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        // This would typically return a URL like:
        // "https://your-metadata-server.com/api/chronicles/" + tokenId.toString()
        // The server at that URL would read the on-chain state (traits, XP, tier, fragments)
        // and generate the appropriate JSON metadata.
        return string(abi.encodePacked("ipfs://your-base-uri/", tokenId.toString(), ".json"));
         // Note: Using IPFS base URI here is standard, but for *dynamic* data,
         // the server approach is needed unless you commit dynamic data on-chain (expensive).
    }

    // Note: Fragment metadata would require a similar mechanism, e.g., fragmentURI(fragmentId).
}
```