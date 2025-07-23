This Solidity smart contract, named `MetaMorphogenesis`, envisions a dynamic, evolving digital ecosystem centered around "Genesis Fragments" (Dynamic NFTs). It integrates advanced concepts such as soulbound tokens for reputation, a simulated AI/oracle mechanism for evolving NFT traits, and a community-driven "Discovery Protocol" for future development paths. The goal is to create a unique, interactive on-chain experience that transcends static digital collectibles.

---

## Contract: `MetaMorphogenesis`

**License:** MIT

**Solidity Version:** `^0.8.20`

**Dependencies:** OpenZeppelin Contracts

---

### **OUTLINE**

1.  **Overview**
    *   **Contract:** `MetaMorphogenesis`
    *   **Core Concept:** An evolving digital ecosystem where unique "Genesis Fragments" (Dynamic NFTs) grow and change based on user interactions, "environmental" data (via oracle), and community curation. It features a soulbound reputation system and a fungible resource token.

2.  **Key Components**
    *   **Genesis Fragments (ERC-721):** Dynamic NFTs with immutable `dna` (core traits) and mutable `currentTraitsHash` (evolving traits). Their appearance and attributes evolve over time.
    *   **Essence Token (ERC-20):** The primary fungible resource within the ecosystem, required for nurturing, staking, and community participation.
    *   **Catalyst Tokens (ERC-1155):** Special utility NFTs that provide temporary buffs or unlock unique actions for Genesis Fragments.
    *   **Evolutionary Badges (Soulbound ERC-721):** Non-transferable (soulbound) tokens representing user achievements, milestones, and on-chain reputation.
    *   **Oracle Integration:** A crucial component for feeding off-chain "environmental data" and "AI-curation" directives into the on-chain evolution logic. It simulates external computational influence on trait evolution.
    *   **Discovery Protocol:** A community-driven mechanism where users can propose and vote on new evolutionary paths, traits, or features, influencing the future development of the ecosystem.

3.  **Core Mechanics**
    *   **Nurturing:** Users interact with their Genesis Fragments through specific actions, consuming Essence, and directly influencing their fragment's mutable traits.
    *   **Evolution:** Fragment traits dynamically update based on Nurturing actions, Catalyst effects, and periodic "environmental" updates pushed by a trusted oracle (simulating AI curation).
    *   **Reputation:** Users earn Soulbound Badges for reaching specific evolutionary milestones or contributing significantly to the ecosystem, creating an on-chain, non-transferable record of their accomplishments.
    *   **Staking:** Users can stake Essence tokens to earn rewards and gain voting power within the Discovery Protocol.
    *   **Curation:** A decentralized process (simulated via Oracle/Governance) that allows for high-level adjustments to the evolutionary landscape or the introduction of new mechanics.

---

### **FUNCTION SUMMARY**

**I. Genesis Fragment (Dynamic NFT) Management**
1.  `mintGenesisFragment()`: Mints a new Genesis Fragment to the caller, assigning initial pseudo-random DNA and base evolving traits. Requires a small ETH fee.
2.  `getFragmentDNA(tokenId)`: Retrieves the immutable DNA (core traits) of a specific Genesis Fragment.
3.  `getFragmentEvolvingTraits(tokenId)`: Retrieves the current mutable, evolving traits hash of a specific Genesis Fragment.
4.  `nurtureFragment(tokenId, actionType, parameters)`: Allows the owner to perform an action (e.g., feed, train) on their fragment, consuming Essence and influencing trait evolution.
5.  `applyCatalyst(tokenId, catalystId, amount)`: Applies a Catalyst NFT to a Genesis Fragment, granting temporary effects or unlocking specific actions. The Catalyst is transferred to the contract.
6.  `requestEvolutionStatus(tokenId)`: Initiates an off-chain request (simulated by an event) to the oracle for the latest "environmental" data relevant to a fragment's evolution.
7.  `finalizeEvolution(tokenId, newTraitsHash, oracleProof)`: Called by the trusted oracle to update a fragment's evolving traits based on off-chain computation/curation and provided proof. Triggers badge checks.
8.  `updateFragmentRenderMetadata(tokenId, newURI)`: Allows the owner (or oracle/curator) to update the metadata URI of a fragment to reflect its evolved state, enabling dynamic visual updates.
9.  `releaseFragment(tokenId)`: Burns a Genesis Fragment, removing it from circulation.

**II. Essence Token (ERC-20) Management**
10. `stakeEssence(amount)`: Allows users to stake their Essence tokens, participating in the ecosystem and accruing rewards. Claims pending rewards before staking.
11. `unstakeEssence(amount)`: Allows users to unstake their Essence tokens. Claims pending rewards before unstaking.
12. `claimStakedEssenceRewards()`: Allows users to claim accumulated rewards from staking Essence.
13. `distributeEssenceToMinters(recipient, amount)`: Owner/admin function (in `EssenceToken` contract) to distribute initial Essence tokens to users or as rewards.
14. `burnEssence(amount)`: Allows users or the protocol (in `EssenceToken` contract) to burn Essence, acting as a deflationary mechanism or resource sink.

**III. Catalyst Token (ERC-1155) Management**
15. `mintCatalyst(catalystType, amount, data)`: Owner/admin function (in `Catalyst` contract) to mint new Catalyst tokens of specified types for distribution.
16. `getAppliedCatalysts(tokenId)`: Returns a list of active Catalyst IDs and their expiry timestamps currently applied to a specific Genesis Fragment.
17. `removeExpiredCatalyst(tokenId, catalystId)`: Allows the owner to explicitly remove an expired Catalyst effect from their Genesis Fragment.

**IV. Evolutionary Badge (Soulbound ERC-721) Management**
18. `awardEvolutionaryBadge(to, badgeURI, criteriaHash)`: Awards a new, non-transferable Evolutionary Badge (SBT) to an address upon meeting specific criteria or achievements.
19. `getEvolutionaryBadges(addr)`: Retrieves all Evolutionary Badge token IDs owned by a specific address.
20. `verifyBadgeCriteria(badgeId, criteriaHash)`: Helper function to verify the criteria hash associated with a specific badge ID, ensuring transparency of achievement conditions.

**V. Discovery Protocol (Community Curation)**
21. `proposeDiscovery(targetTraitType, requiredEssence)`: Allows users with staked Essence to propose new "discovery" paths for fragment evolution, contributing Essence to the proposal.
22. `voteOnDiscovery(proposalId, support)`: Allows users (with staked Essence) to vote for or against an active discovery proposal, with their vote weight proportional to their staked amount.
23. `finalizeDiscovery(proposalId)`: Can be called by anyone after the voting period ends to finalize a discovery proposal, marking it as Succeeded or Failed based on vote outcomes.

**VI. Oracle & Curator Integration**
24. `setOracleAddress(newOracle)`: Owner/admin function to update the address of the trusted oracle responsible for providing external data and fulfilling evolution requests.
25. `setCuratorAddress(newCurator)`: Owner/admin function to update the address of the trusted curator (e.g., a DAO multisig or specific governance contract) responsible for high-level ecosystem adjustments.

**VII. Administrative & Security**
26. `pauseContract()`: Owner/admin function to pause critical contract functionalities during emergencies, inherited from `Pausable`.
27. `unpauseContract()`: Owner/admin function to unpause the contract, inherited from `Pausable`.
28. `withdrawCollectedFees()`: Owner/admin function to withdraw any collected protocol fees (e.g., ETH from minting) to the contract owner's address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For staking rewards calculations

// Define an interface for a hypothetical Oracle (for demonstration)
// In a real scenario, this would align with a specific oracle network (e.g., Chainlink Functions, custom attestation)
interface IOracle {
    function requestData(uint256 _queryId, bytes calldata _data) external returns (bytes32 requestId);
    function fulfillData(uint256 _queryId, bytes calldata _data) external;
}


// --- OUTLINE ---
// 1. Overview
//    - Contract: MetaMorphogenesis
//    - Core Concept: An evolving digital ecosystem where unique "Genesis Fragments" (Dynamic NFTs) grow and change based on user interactions, "environmental" data (via oracle), and community curation. It features a soulbound reputation system and a fungible resource token.
// 2. Key Components
//    - Genesis Fragments (ERC-721): Dynamic NFTs with immutable DNA and mutable Evolving Traits.
//    - Essence Token (ERC-20): The primary resource for nurturing, staking, and community participation.
//    - Catalyst Tokens (ERC-1155): Special utility NFTs that provide temporary buffs or unlock unique actions.
//    - Evolutionary Badges (Soulbound ERC-721): Non-transferable tokens representing user achievements and reputation.
//    - Oracle Integration: A crucial component for feeding off-chain "environmental data" and "AI-curation" directives into the on-chain evolution logic.
//    - Discovery Protocol: A community-driven mechanism for proposing and finalizing new evolutionary paths or traits.
// 3. Core Mechanics
//    - Nurturing: Users interact with their Genesis Fragments to influence their evolution using Essence.
//    - Evolution: Fragment traits dynamically update based on Nurturing actions, Catalyst effects, and Oracle inputs.
//    - Reputation: Earning Soulbound Badges for reaching milestones, signifying on-chain accomplishments.
//    - Staking: Locking Essence tokens to participate in governance or earn rewards.
//    - Curation: A decentralized process (simulated via Oracle/Governance) guiding the overall evolutionary landscape.

// --- FUNCTION SUMMARY ---

// I. Genesis Fragment (Dynamic NFT) Management
// 1.  mintGenesisFragment(): Mints a new Genesis Fragment with initial random or base DNA.
// 2.  getFragmentDNA(tokenId): Retrieves the immutable DNA (core traits) of a Genesis Fragment.
// 3.  getFragmentEvolvingTraits(tokenId): Retrieves the current mutable, evolving traits of a Genesis Fragment.
// 4.  nurtureFragment(tokenId, actionType, parameters): Allows an owner to perform an action (e.g., feed, train) on their fragment, consuming Essence and influencing trait evolution.
// 5.  applyCatalyst(tokenId, catalystId, amount): Applies a Catalyst NFT to a Genesis Fragment, granting temporary effects or unlocking specific actions.
// 6.  requestEvolutionStatus(tokenId): Initiates an off-chain request to the oracle for the latest "environmental" data relevant to a fragment's evolution.
// 7.  finalizeEvolution(tokenId, newTraitsHash, oracleProof): Called by the trusted oracle to update a fragment's evolving traits based on off-chain computation/curation and provided proof.
// 8.  updateFragmentRenderMetadata(tokenId, newURI): Allows the owner (or oracle) to update the metadata URI of a fragment to reflect its evolved state.
// 9.  releaseFragment(tokenId): Burns a Genesis Fragment, potentially reclaiming some spent Essence or triggering a final event.

// II. Essence Token (ERC-20) Management
// 10. stakeEssence(amount): Allows users to stake their Essence tokens, participating in the ecosystem and potentially earning rewards.
// 11. unstakeEssence(amount): Allows users to unstake their Essence tokens.
// 12. claimStakedEssenceRewards(): Allows users to claim accumulated rewards from staking.
// 13. distributeEssenceToMinters(recipient, amount): Owner/admin function to distribute Essence tokens, e.g., as initial supply or rewards.
// 14. burnEssence(amount): Allows users or the protocol to burn Essence, acting as a deflationary mechanism or resource sink.

// III. Catalyst Token (ERC-1155) Management
// 15. mintCatalyst(catalystType, amount, data): Owner/admin function to mint new Catalyst tokens (different types for different effects).
// 16. getAppliedCatalysts(tokenId): Returns a list of active Catalyst IDs applied to a specific Genesis Fragment.
// 17. removeExpiredCatalyst(tokenId, catalystId): Removes an expired Catalyst effect from a Genesis Fragment.

// IV. Evolutionary Badge (Soulbound ERC-721) Management
// 18. awardEvolutionaryBadge(to, badgeId, criteriaHash): Awards a non-transferable Evolutionary Badge to an address upon meeting specific criteria or achievements.
// 19. getEvolutionaryBadges(addr): Retrieves all Evolutionary Badges owned by a specific address.
// 20. verifyBadgeCriteria(badgeId, criteriaHash): Helper function to verify the criteria hash associated with a specific badge ID. (Pure function)

// V. Discovery Protocol (Community Curation)
// 21. proposeDiscovery(targetTraitType, requiredEssence): Allows users to propose new "discovery" paths for fragment evolution, requiring an Essence contribution.
// 22. voteOnDiscovery(proposalId, voteSupport): Allows users (e.g., stakers) to vote on active discovery proposals.
// 23. finalizeDiscovery(proposalId): Owner/governance function to finalize a discovery proposal, unlocking new trait possibilities if successful.

// VI. Oracle & Curator Integration
// 24. setOracleAddress(newOracle): Owner/admin function to update the address of the trusted oracle responsible for providing external data.
// 25. setCuratorAddress(newCurator): Owner/admin function to update the address of the trusted curator (e.g., a DAO multisig) responsible for high-level ecosystem adjustments.

// VII. Administrative & Security
// 26. pauseContract(): Owner/admin function to pause critical contract functionalities during emergencies.
// 27. unpauseContract(): Owner/admin function to unpause the contract.
// 28. withdrawCollectedFees(): Owner/admin function to withdraw any collected protocol fees (if applicable, though not explicitly defined here, good to have).

// --- ERC-20 Token for Essence ---
contract EssenceToken is ERC20, Ownable {
    using SafeMath for uint256;

    constructor() ERC20("Essence", "ESS") Ownable(msg.sender) {
        // Initial supply can be minted by the owner or distributed later
        // _mint(msg.sender, 1000000 * (10 ** 18)); // Example initial mint
    }

    // Function 13: Distribute Essence to specific recipients
    function distributeEssenceToMinters(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }

    // Function 14: Burn Essence from the caller's balance
    function burnEssence(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

// --- ERC-1155 Token for Catalysts ---
contract Catalyst is ERC1155, Ownable {
    constructor() ERC1155("") Ownable(msg.sender) {} // Base URI set by owner

    // Override uri to support individual token URIs if desired, or a base URI with ID appended
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(_tokenId), Strings.toString(_tokenId), ".json"));
    }

    // Function 15: Mint Catalyst tokens of a specific type
    function mintCatalyst(uint256 catalystType, uint256 amount, bytes memory data) external onlyOwner {
        _mint(msg.sender, catalystType, amount, data);
    }

    // Allows the owner to set the base URI for all catalysts
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
}

// --- Soulbound ERC-721 for Evolutionary Badges ---
contract EvolutionaryBadge is ERC721, Ownable {
    // Mapping to store badge criteria hashes (for transparency and verification)
    mapping(uint256 => bytes32) private _badgeCriteriaHashes;
    // Counter for unique badge types/IDs
    uint256 private _badgeCounter;

    constructor() ERC721("Evolutionary Badge", "EVB") Ownable(msg.sender) {}

    // Override _beforeTokenTransfer to make tokens soulbound (non-transferable once minted)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow minting (from zero address) and burning (to zero address), but no transfers between users
        if (from != address(0) && to != address(0)) {
            revert("EvolutionaryBadge: Badges are soulbound and cannot be transferred");
        }
    }

    // Function 18: Award Evolutionary Badge (mints a new badge)
    function awardEvolutionaryBadge(address to, string memory badgeURI, bytes32 criteriaHash) external onlyOwner {
        _badgeCounter++;
        uint256 newBadgeId = _badgeCounter;
        _safeMint(to, newBadgeId);
        _setTokenURI(newBadgeId, badgeURI);
        _badgeCriteriaHashes[newBadgeId] = criteriaHash;
        emit BadgeAwarded(to, newBadgeId, criteriaHash);
    }

    // Function 19: Get Evolutionary Badges for an address
    // Returns all token IDs owned by a specific address.
    function getEvolutionaryBadges(address addr) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(addr);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokens;
    }

    // Function 20: Verify Badge Criteria
    function verifyBadgeCriteria(uint256 badgeId, bytes32 criteriaHash) external view returns (bool) {
        return _badgeCriteriaHashes[badgeId] == criteriaHash;
    }

    event BadgeAwarded(address indexed to, uint256 indexed badgeId, bytes32 criteriaHash);
}


// --- Main MetaMorphogenesis Contract ---
contract MetaMorphogenesis is ERC721, ERC721Burnable, Ownable, Pausable {
    using Strings for uint256;
    using SafeMath for uint256; // For safe arithmetic operations

    // --- State Variables ---

    // External Contract Instances
    EssenceToken public essenceToken;
    Catalyst public catalystToken;
    EvolutionaryBadge public evolutionaryBadge;
    address public oracleAddress;   // Address of the trusted oracle (e.g., Chainlink node, custom off-chain service)
    address public curatorAddress;  // Address of the trusted curator (e.g., DAO multisig, governance contract)

    // Genesis Fragment data structure
    struct GenesisFragmentData {
        bytes32 dna;                    // Immutable core traits (e.g., genetic code, base phenotype)
        uint256 currentTraitsHash;      // Hash representing current mutable traits (e.g., physical form, stats, accumulated evolution)
        uint256 lastNurtureTime;        // Timestamp of last nurture action
        uint256 lastEvolutionUpdate;    // Timestamp of last oracle-driven evolution update
        mapping(uint256 => uint256) appliedCatalysts; // Catalyst ID => expiry timestamp
        uint256[] activeCatalystIds;    // List of active catalyst IDs for easier lookup and iteration
    }
    mapping(uint256 => GenesisFragmentData) public fragments;
    uint256 private _nextTokenId; // Counter for unique fragment IDs

    // Staking data for Essence
    uint256 public constant STAKING_REWARD_RATE_PER_SECOND = 100; // Example: 100 wei ESS per second per (1e18) staked ESS
    mapping(address => uint256) public stakedEssence;
    mapping(address => uint256) public lastStakingRewardClaimTime;

    // Discovery Protocol data
    enum ProposalStatus { Active, Succeeded, Failed }
    struct DiscoveryProposal {
        address proposer;
        string targetTraitType;     // Description of what is being discovered/researched
        uint256 requiredEssence;    // Essence locked by the proposer for the proposal
        uint256 votesFor;           // Total staked Essence voting "for"
        uint256 votesAgainst;       // Total staked Essence voting "against"
        uint256 creationTime;
        uint256 votingEndTime;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks if an address has already voted
    }
    mapping(uint256 => DiscoveryProposal) public discoveryProposals;
    uint256 public nextProposalId;
    uint256 public constant VOTING_PERIOD = 7 days; // Default voting period for proposals

    // --- Events ---
    event FragmentMinted(address indexed owner, uint256 indexed tokenId, bytes32 dna);
    event FragmentNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 actionType, uint256 essenceCost);
    event CatalystApplied(uint256 indexed tokenId, uint256 indexed catalystId, uint256 expiryTime);
    event EvolutionRequested(uint256 indexed tokenId, uint256 queryId); // Placeholder for oracle query ID
    event EvolutionFinalized(uint256 indexed tokenId, uint256 newTraitsHash);
    event EssenceStaked(address indexed user, uint256 amount);
    event EssenceUnstaked(address indexed user, uint256 amount);
    event EssenceRewardsClaimed(address indexed user, uint256 amount);
    event CatalystExpired(uint256 indexed tokenId, uint256 indexed catalystId);
    event DiscoveryProposed(uint256 indexed proposalId, address indexed proposer, string targetTraitType);
    event DiscoveryVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event DiscoveryFinalized(uint256 indexed proposalId, ProposalStatus status);
    event OracleAddressUpdated(address indexed newAddress);
    event CuratorAddressUpdated(address indexed newAddress);


    constructor(address _essenceTokenAddr, address _catalystTokenAddr, address _evolutionaryBadgeAddr)
        ERC721("MetaMorphogenesis Genesis Fragment", "MMGF") // NFT name and symbol
        Ownable(msg.sender)
    {
        essenceToken = EssenceToken(_essenceTokenAddr);
        catalystToken = Catalyst(_catalystTokenAddr);
        evolutionaryBadge = EvolutionaryBadge(_evolutionaryBadgeAddr);
        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "MetaMorphogenesis: Caller is not the oracle");
        _;
    }

    modifier onlyCurator() {
        require(msg.sender == curatorAddress, "MetaMorphogenesis: Caller is not the curator");
        _;
    }

    // --- I. Genesis Fragment (Dynamic NFT) Management ---

    // Function 1: Mint Genesis Fragment
    // Allows users to mint a new Genesis Fragment by paying a small ETH fee.
    function mintGenesisFragment() external payable whenNotPaused returns (uint256) {
        require(msg.value >= 0.001 ether, "MetaMorphogenesis: Insufficient minting fee (0.001 ETH required)");

        uint256 newTokenId = _nextTokenId++;
        // Generate pseudo-random DNA based on block data and caller address for initial uniqueness
        bytes32 initialDNA = keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId, block.difficulty));
        // Initial traits hash derived from DNA; this will evolve
        uint256 initialTraitsHash = uint256(keccak256(abi.encodePacked("initial_genesis", initialDNA))); 

        _safeMint(msg.sender, newTokenId);
        // Set a placeholder URI; this will be updated as the fragment evolves
        _setTokenURI(newTokenId, string(abi.encodePacked("ipfs://placeholder/", newTokenId.toString())));

        fragments[newTokenId] = GenesisFragmentData({
            dna: initialDNA,
            currentTraitsHash: initialTraitsHash,
            lastNurtureTime: block.timestamp,
            lastEvolutionUpdate: block.timestamp,
            activeCatalystIds: new uint256[](0) // Initialize empty dynamic array
        });

        emit FragmentMinted(msg.sender, newTokenId, initialDNA);
        return newTokenId;
    }

    // Function 2: Get Fragment DNA
    // Returns the immutable genetic code of a Genesis Fragment.
    function getFragmentDNA(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "MetaMorphogenesis: Fragment does not exist");
        return fragments[tokenId].dna;
    }

    // Function 3: Get Fragment Evolving Traits
    // Returns the current hash representing the mutable, evolving traits of a Genesis Fragment.
    function getFragmentEvolvingTraits(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "MetaMorphogenesis: Fragment does not exist");
        return fragments[tokenId].currentTraitsHash;
    }

    // Function 4: Nurture Fragment
    // Allows the owner to interact with their fragment, consuming Essence and influencing its evolution.
    function nurtureFragment(uint256 tokenId, uint256 actionType, bytes calldata parameters) external whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "MetaMorphogenesis: Caller is not the fragment owner");
        
        // Example logic for Essence cost: more complex actions might cost more
        uint256 essenceCost = 100 * (actionType + 1); // Cost increases with action complexity
        require(essenceToken.transferFrom(msg.sender, address(this), essenceCost), "Essence transfer failed for nurturing");

        GenesisFragmentData storage fragment = fragments[tokenId];
        fragment.lastNurtureTime = block.timestamp;

        // Simple on-chain trait influence: trait hash evolves with each nurture action
        // In a more complex system, 'parameters' and 'actionType' would intricately modify specific trait attributes.
        fragment.currentTraitsHash = uint256(keccak256(abi.encodePacked(
            fragment.currentTraitsHash,
            actionType,
            parameters,
            block.timestamp,
            block.number
        )));

        emit FragmentNurtured(tokenId, msg.sender, actionType, essenceCost);
    }

    // Function 5: Apply Catalyst
    // Allows the owner to apply a Catalyst NFT to their Genesis Fragment, granting temporary effects.
    function applyCatalyst(uint256 tokenId, uint256 catalystId, uint256 amount) external whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "MetaMorphogenesis: Caller is not the fragment owner");
        require(amount == 1, "MetaMorphogenesis: Only one catalyst of a kind can be applied at once"); // Simplicity constraint

        // Transfer Catalyst from user to contract (contract holds it while active)
        catalystToken.safeTransferFrom(msg.sender, address(this), catalystId, amount, "");

        GenesisFragmentData storage fragment = fragments[tokenId];
        // Example: Catalyst effect lasts for 24 hours (86400 seconds)
        uint256 expiryTime = block.timestamp.add(1 days);

        // Update catalyst's expiry time
        fragment.appliedCatalysts[catalystId] = expiryTime;
        // Add to active list if not already present, ensuring no duplicates
        bool found = false;
        for(uint i=0; i<fragment.activeCatalystIds.length; i++){
            if(fragment.activeCatalystIds[i] == catalystId){
                found = true;
                break;
            }
        }
        if (!found) {
            fragment.activeCatalystIds.push(catalystId);
        }

        emit CatalystApplied(tokenId, catalystId, expiryTime);
    }

    // Function 6: Request Evolution Status
    // Initiates an off-chain request to the oracle for external data relevant to a fragment's complex evolution.
    function requestEvolutionStatus(uint256 tokenId) external whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "MetaMorphogenesis: Caller is not the fragment owner");
        require(address(oracleAddress) != address(0), "MetaMorphogenesis: Oracle address not set");

        // In a real application, this would call a method on the IOracle interface,
        // e.g., `IOracle(oracleAddress).requestData(queryId, abi.encode(tokenId, fragments[tokenId].currentTraitsHash));`
        // For this example, we simulate the request by emitting an event with a query ID.
        uint256 queryId = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, block.number)));
        emit EvolutionRequested(tokenId, queryId);
    }

    // Function 7: Finalize Evolution
    // Called by the trusted oracle to update a fragment's evolving traits based on off-chain computation/curation.
    function finalizeEvolution(uint256 tokenId, uint256 newTraitsHash, bytes memory oracleProof) external onlyOracle whenNotPaused {
        // In a production system, 'oracleProof' would be cryptographically verified (e.g., Chainlink's fulfill callback data, VRF proof).
        // For this example, the `onlyOracle` modifier serves as the trust mechanism.
        require(_exists(tokenId), "MetaMorphogenesis: Fragment does not exist");

        GenesisFragmentData storage fragment = fragments[tokenId];
        fragment.currentTraitsHash = newTraitsHash; // Update traits based on oracle's computation
        fragment.lastEvolutionUpdate = block.timestamp;

        // Perform cleanup of any expired catalysts and check for badge awards
        _cleanupExpiredCatalysts(tokenId);
        _checkAndAwardBadges(ownerOf(tokenId), tokenId, newTraitsHash);

        emit EvolutionFinalized(tokenId, newTraitsHash);
    }

    // Function 8: Update Fragment Render Metadata
    // Allows authorized parties to update the NFT's metadata URI to reflect its evolved state.
    function updateFragmentRenderMetadata(uint256 tokenId, string memory newURI) external whenNotPaused {
        require(ownerOf(tokenId) == msg.sender || msg.sender == oracleAddress || msg.sender == curatorAddress,
            "MetaMorphogenesis: Not authorized to update metadata URI");
        _setTokenURI(tokenId, newURI);
    }

    // Function 9: Release Fragment (Burn)
    // Allows the owner to burn their Genesis Fragment.
    function releaseFragment(uint256 tokenId) external whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "MetaMorphogenesis: Caller is not the fragment owner");
        // Optional: Could include logic here to refund some Essence, or trigger a final event.
        _burn(tokenId); // Utilizes OpenZeppelin's ERC721Burnable
    }

    // --- II. Essence Token (ERC-20) Management ---

    // Function 10: Stake Essence
    // Allows users to stake their Essence tokens in the contract.
    function stakeEssence(uint256 amount) external whenNotPaused {
        require(amount > 0, "MetaMorphogenesis: Amount must be greater than 0");
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "Essence transfer failed during staking");

        // Claim any pending rewards before updating stake to prevent unfair accumulation
        _claimStakedEssenceRewards(msg.sender);

        stakedEssence[msg.sender] = stakedEssence[msg.sender].add(amount);
        lastStakingRewardClaimTime[msg.sender] = block.timestamp;
        emit EssenceStaked(msg.sender, amount);
    }

    // Function 11: Unstake Essence
    // Allows users to unstake their Essence tokens from the contract.
    function unstakeEssence(uint256 amount) external whenNotPaused {
        require(amount > 0, "MetaMorphogenesis: Amount must be greater than 0");
        require(stakedEssence[msg.sender] >= amount, "MetaMorphogenesis: Insufficient staked Essence");

        // Claim any pending rewards before unstaking
        _claimStakedEssenceRewards(msg.sender);

        stakedEssence[msg.sender] = stakedEssence[msg.sender].sub(amount);
        require(essenceToken.transfer(msg.sender, amount), "Essence withdrawal failed during unstaking");
        emit EssenceUnstaked(msg.sender, amount);
    }

    // Function 12: Claim Staked Essence Rewards
    // Allows users to claim their accrued staking rewards.
    function claimStakedEssenceRewards() external whenNotPaused {
        _claimStakedEssenceRewards(msg.sender);
    }

    // Internal helper function for claiming staking rewards
    function _claimStakedEssenceRewards(address user) internal {
        uint256 currentStaked = stakedEssence[user];
        if (currentStaked == 0) return; // No Essence staked, no rewards

        uint256 timeElapsed = block.timestamp.sub(lastStakingRewardClaimTime[user]);
        // Reward calculation: staked_amount * rate_per_second * time_elapsed.
        // Divide by 1e18 if STAKING_REWARD_RATE_PER_SECOND is based on 1 ETH (1e18 wei).
        uint256 pendingRewards = currentStaked.mul(STAKING_REWARD_RATE_PER_SECOND).mul(timeElapsed).div(1e18);

        if (pendingRewards > 0) {
            lastStakingRewardClaimTime[user] = block.timestamp;
            require(essenceToken.transfer(user, pendingRewards), "Reward transfer failed");
            emit EssenceRewardsClaimed(user, pendingRewards);
        }
    }
    
    // --- III. Catalyst Token (ERC-1155) Management ---

    // Function 16: Get Applied Catalysts
    // Returns a list of active catalyst IDs and their expiry times for a given fragment.
    function getAppliedCatalysts(uint256 tokenId) public view returns (uint256[] memory activeCatalystIds, uint256[] memory expiryTimes) {
        require(_exists(tokenId), "MetaMorphogenesis: Fragment does not exist");
        GenesisFragmentData storage fragment = fragments[tokenId];

        uint256[] memory tempActiveIds = new uint256[](fragment.activeCatalystIds.length);
        uint256[] memory tempExpiryTimes = new uint256[](fragment.activeCatalystIds.length);
        uint256 count = 0;

        // Filter out expired catalysts for the returned list
        for (uint252 i = 0; i < fragment.activeCatalystIds.length; i++) {
            uint256 catalystId = fragment.activeCatalystIds[i];
            uint256 expiry = fragment.appliedCatalysts[catalystId];
            if (expiry > block.timestamp) { // Only return catalysts that are still active
                tempActiveIds[count] = catalystId;
                tempExpiryTimes[count] = expiry;
                count++;
            }
        }
        
        // Resize arrays to actual count of active catalysts
        activeCatalystIds = new uint256[](count);
        expiryTimes = new uint256[](count);
        for(uint i=0; i<count; i++){
            activeCatalystIds[i] = tempActiveIds[i];
            expiryTimes[i] = tempExpiryTimes[i];
        }

        return (activeCatalystIds, expiryTimes);
    }

    // Function 17: Remove Expired Catalyst
    // Allows the owner to remove an expired catalyst's effect from their fragment, freeing up resources or slots.
    function removeExpiredCatalyst(uint256 tokenId, uint256 catalystId) external whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "MetaMorphogenesis: Caller is not the fragment owner");
        GenesisFragmentData storage fragment = fragments[tokenId];
        
        // Ensure the catalyst was applied and has indeed expired
        require(fragment.appliedCatalysts[catalystId] > 0, "MetaMorphogenesis: Catalyst not applied or already removed");
        require(fragment.appliedCatalysts[catalystId] <= block.timestamp, "MetaMorphogenesis: Catalyst not yet expired");

        fragment.appliedCatalysts[catalystId] = 0; // Mark as expired/removed

        // Efficiently remove from active list by swapping with last element and popping
        for (uint256 i = 0; i < fragment.activeCatalystIds.length; i++) {
            if (fragment.activeCatalystIds[i] == catalystId) {
                fragment.activeCatalystIds[i] = fragment.activeCatalystIds[fragment.activeCatalystIds.length - 1];
                fragment.activeCatalystIds.pop();
                break;
            }
        }
        emit CatalystExpired(tokenId, catalystId);
    }
    
    // Internal helper to clean up catalysts during evolution finalization or other processes
    function _cleanupExpiredCatalysts(uint256 tokenId) internal {
        GenesisFragmentData storage fragment = fragments[tokenId];
        uint256[] memory currentActive = fragment.activeCatalystIds;
        fragment.activeCatalystIds = new uint256[](0); // Reset the dynamic array

        // Re-populate the active list with only non-expired catalysts
        for (uint256 i = 0; i < currentActive.length; i++) {
            uint256 catalystId = currentActive[i];
            if (fragment.appliedCatalysts[catalystId] > block.timestamp) {
                fragment.activeCatalystIds.push(catalystId);
            } else {
                fragment.appliedCatalysts[catalystId] = 0; // Explicitly zero out expired ones in the mapping
            }
        }
    }

    // Internal helper to check and award badges based on fragment's evolution
    function _checkAndAwardBadges(address user, uint256 tokenId, uint256 newTraitsHash) internal {
        // This function would contain complex logic to determine if the fragment's newTraitsHash,
        // cumulative nurture actions, specific catalyst uses, or time metrics meet criteria for a badge.
        // The criteria themselves could be defined off-chain by the 'AI-curator' and verified using `criteriaHash`.

        // Example: Award a badge for reaching "Advanced Form" (a specific hash pattern)
        bytes32 advancedFormCriteria = keccak256(abi.encodePacked("AdvancedFormAchievedV1")); 
        // Check if the user hasn't already received a specific badge (e.g., Badge ID 1) for this criteria
        // and if a simplified condition on the newTraitsHash is met.
        if (newTraitsHash % 1000 == 0 && !evolutionaryBadge.verifyBadgeCriteria(1, advancedFormCriteria)) {
            // In a real scenario, badgeID 1 would correspond to a specific set of achievements.
            // The badgeURI would point to the metadata for this badge.
            evolutionaryBadge.awardEvolutionaryBadge(user, "ipfs://Qmbadgev1advanced", advancedFormCriteria);
        }
        // More complex rules and conditions for different badges would be added here.
    }

    // --- V. Discovery Protocol (Community Curation) ---

    // Function 21: Propose Discovery
    // Allows users to propose new "discovery" paths for fragment evolution or ecosystem features.
    function proposeDiscovery(string memory targetTraitType, uint256 requiredEssence) external whenNotPaused {
        require(stakedEssence[msg.sender] > 0, "MetaMorphogenesis: Must have staked Essence to propose");
        require(requiredEssence > 0, "MetaMorphogenesis: Required Essence contribution must be greater than 0");
        // Transfer required Essence from proposer to the contract for locking during the proposal period
        require(essenceToken.transferFrom(msg.sender, address(this), requiredEssence), "Essence transfer for proposal failed");

        uint256 proposalId = nextProposalId++;
        discoveryProposals[proposalId] = DiscoveryProposal({
            proposer: msg.sender,
            targetTraitType: targetTraitType,
            requiredEssence: requiredEssence,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(VOTING_PERIOD),
            status: ProposalStatus.Active,
            // hasVoted mapping is initialized per-proposal implicitly by Solidity
            hasVoted: new mapping(address => bool)() // Explicitly initialize
        });

        emit DiscoveryProposed(proposalId, msg.sender, targetTraitType);
    }

    // Function 22: Vote on Discovery
    // Allows users (who have staked Essence) to vote on active discovery proposals.
    function voteOnDiscovery(uint256 proposalId, bool support) external whenNotPaused {
        DiscoveryProposal storage proposal = discoveryProposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "MetaMorphogenesis: Proposal is not active or does not exist");
        require(block.timestamp <= proposal.votingEndTime, "MetaMorphogenesis: Voting period has ended for this proposal");
        require(stakedEssence[msg.sender] > 0, "MetaMorphogenesis: Must have staked Essence to vote");
        require(!proposal.hasVoted[msg.sender], "MetaMorphogenesis: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor = proposal.votesFor.add(stakedEssence[msg.sender]); // Votes weighted by staked amount
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(stakedEssence[msg.sender]);
        }

        emit DiscoveryVoted(proposalId, msg.sender, support);
    }

    // Function 23: Finalize Discovery
    // Can be called by anyone after the voting period ends to finalize a discovery proposal.
    function finalizeDiscovery(uint256 proposalId) external whenNotPaused {
        DiscoveryProposal storage proposal = discoveryProposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "MetaMorphogenesis: Proposal is not active or does not exist");
        require(block.timestamp > proposal.votingEndTime, "MetaMorphogenesis: Voting period has not ended yet");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Succeeded;
            // Logic for successful discovery: e.g., register new trait type,
            // trigger a curator action, or unlock specific oracle behaviors.
            // For now, we simply mark it as succeeded.
            // Option: Refund proposer's Essence
            essenceToken.transfer(proposal.proposer, proposal.requiredEssence);
        } else {
            proposal.status = ProposalStatus.Failed;
            // Option: Burn the Essence used for proposal as a failure penalty
            essenceToken.burnEssence(proposal.requiredEssence); // This calls burn from EssenceToken itself
        }
        
        emit DiscoveryFinalized(proposalId, proposal.status);
    }

    // --- VI. Oracle & Curator Integration ---

    // Function 24: Set Oracle Address
    // Allows the owner to update the address of the trusted oracle.
    function setOracleAddress(address newOracle) external onlyOwner {
        require(newOracle != address(0), "MetaMorphogenesis: Oracle address cannot be zero");
        oracleAddress = newOracle;
        emit OracleAddressUpdated(newOracle);
    }

    // Function 25: Set Curator Address
    // Allows the owner to update the address of the trusted curator (e.g., a DAO contract).
    function setCuratorAddress(address newCurator) external onlyOwner {
        require(newCurator != address(0), "MetaMorphogenesis: Curator address cannot be zero");
        curatorAddress = newCurator;
        emit CuratorAddressUpdated(newCurator);
    }

    // --- VII. Administrative & Security ---

    // Function 26 & 27: Pause/Unpause
    // Inherited from OpenZeppelin's Pausable contract, allows owner to pause/unpause critical functions.
    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // Function 28: Withdraw Collected Fees
    // Allows the owner to withdraw any collected ETH fees (e.g., from minting) from the contract.
    function withdrawCollectedFees() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
        // If the contract also holds other tokens (e.g., Essence from failed proposals),
        // additional withdrawal functions would be needed here.
    }

    // Fallback function to allow the contract to receive ETH (e.g., for minting fees)
    receive() external payable {}
}
```