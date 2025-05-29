Okay, let's design a complex, non-standard smart contract that incorporates dynamic state, resource management, staking-like mechanisms, a simple on-chain reputation system (SBT-like), and a basic governance element.

We'll call this contract the **ChronoSphere Engine**. It will manage unique, evolving digital assets (Essences) that can be combined, attuned (staked), and generate non-transferable reputation points (Chronon Echoes) used for governance.

**Concept:**

*   **Essences (ERC721):** Unique NFTs representing different forms of energy or matter within the ChronoSphere. They have dynamic attributes like Level, Type, State (e.g., Dormant, Attuned, Volatile), and an internal resource counter (Flux Points).
*   **Flux Points:** An internal, non-transferable resource specific to each Essence NFT, gained through certain actions or over time while Attuned. Required for evolution or combination.
*   **Attunement:** Staking an Essence NFT for a period. While Attuned, the Essence cannot be transferred and potentially gains Flux Points and generates Chronon Echoes for the owner.
*   **Chronon Echoes (SBT-like):** Non-transferable tokens linked to an address, representing the owner's accumulated reputation or participation within the ChronoSphere. Used for voting power.
*   **Evolution:** Transforming an Essence NFT into a higher level or different type, consuming Flux Points and potentially other conditions.
*   **Combination:** Merging multiple Essence NFTs into a single new or enhanced Essence, consuming the inputs.
*   **Governance:** Simple on-chain proposals and voting using Chronon Echoes.

---

**Outline & Function Summary**

**Contract Name:** `ChronoSphereEngine`

**Core Functionality:** ERC721 management for dynamic "Essence" NFTs, internal resource tracking, staking ("Attunement"), non-transferable reputation ("Chronon Echoes"), combination/evolution mechanics, and basic governance.

**State Variables:**
*   Ownership & Access Control
*   Counters (Token IDs, Proposal IDs)
*   ERC721 Mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`)
*   Essence Data Mappings (`essenceData`, `attunementEndTime`, `attunementStartTime`)
*   Resource Mappings (`chrononEchoBalances`)
*   Governance Mappings (`proposals`, `proposalVotes`, `proposalVoteSnapshot`)
*   Configuration Parameters (`attunementEchoRatePerSecond`, `baseEvolutionFluxCost`, `minFluxForEvolution`, etc.)
*   Base URI for metadata

**Events:**
*   Standard ERC721 Events (`Transfer`, `Approval`, `ApprovalForAll`)
*   Core Engine Events (`EssenceMinted`, `EssenceEvolved`, `EssenceCombined`, `EssenceAttuned`, `EssenceUnattuned`, `EchoesClaimed`, `FluxGained`)
*   Governance Events (`ProposalSubmitted`, `VoteCast`, `ProposalExecuted`)
*   Configuration Events (`ConfigUpdated`)

**Structs:**
*   `EssenceData`: Stores dynamic NFT attributes (level, type, flux points, state).
*   `Proposal`: Stores governance proposal details (description, proposer, votes, execution status, snapshot data).

**Modifiers:**
*   `onlyOwner`: Standard Ownable modifier.
*   `requiresEssenceOwnership(uint256 tokenId)`: Checks if caller owns the token.
*   `requiresNotAttuned(uint256 tokenId)`: Checks if token is NOT currently attuned.
*   `requiresAttuned(uint256 tokenId)`: Checks if token IS currently attuned.
*   `requiresMinEchoes(uint256 amount)`: Checks if caller has minimum required Echoes.
*   `proposalExists(uint256 proposalId)`: Checks if proposal ID is valid.

**Functions (20+):**

1.  **ERC721 Standard (8 functions):**
    *   `balanceOf(address owner) view`: Get ERC721 balance.
    *   `ownerOf(uint256 tokenId) view`: Get token owner.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer (unchecked).
    *   `approve(address to, uint256 tokenId)`: Approve address for token.
    *   `setApprovalForAll(address operator, bool approved)`: Set operator approval.
    *   `getApproved(uint256 tokenId) view`: Get approved address for token.
    *   `isApprovedForAll(address owner, address operator) view`: Check operator approval status.

2.  **ERC721 Extensions (Metadata & Enumerable - partial):**
    *   `tokenURI(uint256 tokenId) view`: Get metadata URI for token (dynamic).
    *   `totalSupply() view`: Get total number of minted Essences.
    *   `tokenByIndex(uint256 index) view`: Get token ID by global index (caution: expensive).
    *   `tokenOfOwnerByIndex(address owner, uint256 index) view`: Get token ID by owner index (caution: expensive).

3.  **Core Engine - Minting & Access:**
    *   `mintEssence(uint8 initialType) payable`: Mint a new Essence NFT (might require payment).

4.  **Core Engine - Dynamic State & Resources:**
    *   `getEssenceDetails(uint256 tokenId) view`: Get dynamic attributes (level, type, flux, state) of an Essence.
    *   `getFluxPoints(uint256 tokenId) view`: Get current Flux Points of an Essence.
    *   `getChrononEchoBalance(address account) view`: Get Chronon Echo balance for an address.
    *   `calculateEarnedEchoes(uint256 tokenId) view`: Calculate pending Echoes for an attuned Essence.

5.  **Core Engine - Evolution & Combination:**
    *   `evolveEssence(uint256 tokenId, uint8 evolutionPath)`: Attempt to evolve an Essence (consumes Flux, changes state).
    *   `combineEssences(uint256[] calldata tokenIds)`: Attempt to combine multiple Essences into one (burns inputs, consumes Flux, mints/updates output).

6.  **Core Engine - Attunement (Staking):**
    *   `attuneEssence(uint256 tokenId, uint64 durationSeconds)`: Attune (stake) an Essence for a duration.
    *   `unattuneEssence(uint256 tokenId)`: Unattune (unstake) an Essence. Claims accumulated Echoes and Flux.
    *   `claimAttunementRewards(uint256 tokenId)`: Explicitly claim earned Echoes and Flux for an attuned Essence without unattuning.

7.  **Core Engine - Resource Management:**
    *   `transferFluxPoints(uint256 fromTokenId, uint256 toTokenId, uint256 amount)`: Transfer Flux points between two Essences owned by the same address (if allowed by state).
    *   `injectFlux(uint256 tokenId, uint256 amount)`: Inject external Flux (simulated, or could require payment/external token).

8.  **Governance:**
    *   `submitProposal(string calldata description, uint8 proposalType, bytes calldata proposalData)`: Submit a governance proposal (requires Min Echoes).
    *   `voteOnProposal(uint256 proposalId, bool support)`: Cast a vote (requires Chronon Echoes snapshot at proposal time).
    *   `executeProposal(uint256 proposalId)`: Attempt to execute a passed proposal.

9.  **Admin & Configuration (Owner Only):**
    *   `setBaseURI(string memory newBaseURI)`: Set the base URI for token metadata.
    *   `updateConfig(uint8 paramType, uint256 value)`: Update various contract parameters (e.g., costs, rates). Uses an enum for paramType.
    *   `withdrawFunds(address recipient)`: Withdraw gathered Ether (if any).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// --- Outline & Function Summary ---
// Contract Name: ChronoSphereEngine
// Core Functionality: ERC721 management for dynamic "Essence" NFTs, internal resource tracking, staking ("Attunement"), non-transferable reputation ("Chronon Echoes"), combination/evolution mechanics, and basic governance.
//
// State Variables:
// - Ownership & Access Control (Ownable)
// - Counters (Counters)
// - ERC721 Mappings (handled by OZ ERC721)
// - Essence Data Mappings (essenceData, attunementEndTime, attunementStartTime)
// - Resource Mappings (chrononEchoBalances)
// - Governance Mappings (proposals, proposalVotes, proposalVoteSnapshot)
// - Configuration Parameters (attunementEchoRatePerSecond, baseEvolutionFluxCost, minFluxForEvolution, etc.)
// - Base URI for metadata (_baseTokenURI)
//
// Events:
// - Standard ERC721 Events (Transfer, Approval, ApprovalForAll)
// - Core Engine Events (EssenceMinted, EssenceEvolved, EssenceCombined, EssenceAttuned, EssenceUnattuned, EchoesClaimed, FluxGained)
// - Governance Events (ProposalSubmitted, VoteCast, ProposalExecuted)
// - Configuration Events (ConfigUpdated)
//
// Structs:
// - EssenceData: Stores dynamic NFT attributes (level, type, flux points, state).
// - Proposal: Stores governance proposal details.
//
// Modifiers:
// - onlyOwner: Standard Ownable modifier.
// - requiresEssenceOwnership(uint256 tokenId): Checks if caller owns the token.
// - requiresNotAttuned(uint256 tokenId): Checks if token is NOT currently attuned.
// - requiresAttuned(uint256 tokenId): Checks if token IS currently attuned.
// - requiresMinEchoes(uint256 amount): Checks if caller has minimum required Echoes.
// - proposalExists(uint256 proposalId): Checks if proposal ID is valid.
//
// Functions (34 total):
// 1. balanceOf(address owner) view - ERC721 Standard
// 2. ownerOf(uint256 tokenId) view - ERC721 Standard
// 3. safeTransferFrom(address from, address to, uint256 tokenId) - ERC721 Standard
// 4. transferFrom(address from, address to, uint256 tokenId) - ERC721 Standard
// 5. approve(address to, uint256 tokenId) - ERC721 Standard
// 6. setApprovalForAll(address operator, bool approved) - ERC721 Standard
// 7. getApproved(uint256 tokenId) view - ERC721 Standard
// 8. isApprovedForAll(address owner, address operator) view - ERC721 Standard
// 9. tokenURI(uint256 tokenId) view - ERC721 Metadata Extension (Dynamic)
// 10. totalSupply() view - ERC721 Enumerable Extension (Partial)
// 11. tokenByIndex(uint256 index) view - ERC721 Enumerable Extension (Partial, costly)
// 12. tokenOfOwnerByIndex(address owner, uint256 index) view - ERC721 Enumerable Extension (Partial, costly)
// 13. mintEssence(uint8 initialType) payable - Core Engine: Minting
// 14. getEssenceDetails(uint256 tokenId) view - Core Engine: Dynamic State
// 15. getFluxPoints(uint256 tokenId) view - Core Engine: Dynamic State
// 16. getChrononEchoBalance(address account) view - Core Engine: Reputation
// 17. calculateEarnedEchoes(uint256 tokenId) view - Core Engine: Attunement Rewards Calculation
// 18. evolveEssence(uint256 tokenId, uint8 evolutionPath) - Core Engine: Evolution
// 19. combineEssences(uint256[] calldata tokenIds) - Core Engine: Combination
// 20. attuneEssence(uint256 tokenId, uint64 durationSeconds) - Core Engine: Attunement (Staking)
// 21. unattuneEssence(uint256 tokenId) - Core Engine: Unattunement (Unstaking)
// 22. claimAttunementRewards(uint256 tokenId) - Core Engine: Claim Attunement Rewards without Unstaking
// 23. transferFluxPoints(uint256 fromTokenId, uint256 toTokenId, uint256 amount) - Core Engine: Resource Transfer
// 24. injectFlux(uint256 tokenId, uint256 amount) - Core Engine: Resource Injection (Example)
// 25. burnEssence(uint256 tokenId) - Core Engine: Burning
// 26. submitProposal(string calldata description, uint8 proposalType, bytes calldata proposalData) - Governance: Submission
// 27. voteOnProposal(uint256 proposalId, bool support) - Governance: Voting
// 28. executeProposal(uint256 proposalId) - Governance: Execution
// 29. getProposalDetails(uint256 proposalId) view - Governance: Details View
// 30. getVoteStatus(uint256 proposalId, address account) view - Governance: Vote Status View
// 31. getProposalCount() view - Governance: Count View
// 32. setBaseURI(string memory newBaseURI) - Admin: Config
// 33. updateConfig(uint8 paramType, uint256 value) - Admin: Config
// 34. withdrawFunds(address recipient) - Admin: Funds

// Note: The tokenURI generation will be simplified for on-chain cost,
// returning a base URI + token ID. The dynamic data *within* the metadata
// JSON would be served off-chain by an API reading the on-chain state.

contract ChronoSphereEngine is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Dynamic Essence Data
    enum EssenceState { Dormant, Attuned, Volatile } // Example states
    enum EssenceType { Core, Stellar, Quantum } // Example types

    struct EssenceData {
        uint8 level;
        EssenceType essenceType;
        uint256 fluxPoints;
        EssenceState state;
    }

    mapping(uint256 => EssenceData) private essenceData;
    mapping(uint256 => uint64) private attunementEndTime; // Token ID -> Timestamp
    mapping(uint256 => uint64) private attunementStartTime; // Token ID -> Timestamp when attunement began

    // Non-transferable Chronon Echoes (SBT-like)
    mapping(address => uint256) private chrononEchoBalances;

    // Governance
    enum ProposalType { UpdateEvolutionCost, UpdateAttunementDuration, SignalOnly } // Example proposal types

    struct Proposal {
        address proposer;
        string description;
        uint8 proposalType;
        bytes proposalData; // Data for specific proposal types (e.g., new value for update)
        uint256 snapshotEchoTotal; // Total Echoes at proposal creation time
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Address -> Voted status
        bool executed;
        uint64 endTime;
    }

    mapping(uint256 => Proposal) private proposals;
    mapping(uint256 => uint256) private proposalVoteSnapshot; // proposalId -> voter address -> snapshot Echo balance (for weighting)

    // Configuration Parameters (Can be updated via owner/governance)
    uint256 public attunementEchoRatePerSecond = 1e17; // 0.1 Echo per second (adjust decimals)
    uint256 public baseEvolutionFluxCost = 1000;
    uint256 public minFluxForEvolution = 500;
    uint256 public essenceMintCost = 0.01 ether; // Example mint cost
    uint256 public proposalThresholdEchoes = 1000e18; // Example: need 1000 Echoes to propose
    uint64 public proposalVotingPeriodSeconds = 7 days;

    string private _baseTokenURI;

    // --- Events ---

    event EssenceMinted(address indexed owner, uint256 indexed tokenId, uint8 initialType);
    event EssenceEvolved(uint256 indexed tokenId, uint8 newLevel, EssenceType newType);
    event EssenceCombined(address indexed owner, uint256[] indexed burnedTokenIds, uint256 indexed newTokenId);
    event EssenceAttuned(uint256 indexed tokenId, address indexed owner, uint64 durationSeconds, uint64 endTime);
    event EssenceUnattuned(uint256 indexed tokenId, address indexed owner, uint256 claimedEchoes, uint256 claimedFlux);
    event EchoesClaimed(address indexed owner, uint256 indexed tokenId, uint256 amount);
    event FluxGained(uint256 indexed tokenId, uint256 amount);
    event FluxTransferred(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 amount);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description, uint64 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingWeight);
    event ProposalExecuted(uint256 indexed proposalId);

    event ConfigUpdated(uint8 indexed paramType, uint256 value);

    // --- Modifiers ---

    modifier requiresEssenceOwnership(uint256 tokenId) {
        require(_exists(tokenId), "ChronoSphere: token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoSphere: caller is not owner or approved");
        _;
    }

    modifier requiresNotAttuned(uint256 tokenId) {
        require(attunementEndTime[tokenId] <= block.timestamp, "ChronoSphere: essence is currently attuned");
        _;
    }

    modifier requiresAttuned(uint256 tokenId) {
        require(attunementEndTime[tokenId] > block.timestamp, "ChronoSphere: essence is not attuned");
        _;
    }

    modifier requiresMinEchoes(uint256 amount) {
        require(chrononEchoBalances[msg.sender] >= amount, "ChronoSphere: Insufficient Chronon Echoes");
        _;
    }

     modifier proposalExists(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= _proposalIdCounter.current(), "ChronoSphere: Invalid proposal ID");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) Ownable(msg.sender) {
        _baseTokenURI = baseURI;
    }

    // --- Internal Helpers ---

    // Grants Chronon Echoes to an address (non-transferable)
    function _increaseEchoes(address account, uint256 amount) internal {
        chrononEchoBalances[account] += amount;
        // Note: No event for general increase, only for claiming attunement rewards
    }

    // Grants Flux Points to an Essence
    function _increaseFlux(uint256 tokenId, uint256 amount) internal {
        essenceData[tokenId].fluxPoints += amount;
        emit FluxGained(tokenId, amount);
    }

    // Reduces Flux Points from an Essence
    function _decreaseFlux(uint256 tokenId, uint256 amount) internal {
         EssenceData storage data = essenceData[tokenId];
         require(data.fluxPoints >= amount, "ChronoSphere: Insufficient Flux Points");
         data.fluxPoints -= amount;
    }

    // Internal Attunement Reward Calculation & Claiming
    function _claimAttunementRewardsInternal(uint256 tokenId) internal returns (uint256 claimedEchoes, uint256 claimedFlux) {
        EssenceData storage data = essenceData[tokenId];
        uint64 startTime = attunementStartTime[tokenId];
        uint64 endTime = attunementEndTime[tokenId];

        // Calculate time elapsed since start or last claim
        uint66 durationAttuned = 0;
        if (startTime > 0) {
            uint64 currentTime = uint64(block.timestamp);
            if (currentTime > endTime) {
                durationAttuned = endTime - startTime; // Claim up to end time
            } else {
                durationAttuned = currentTime - startTime; // Claim up to current time
            }

            // Reset start time for next claim period or until unattuned
            attunementStartTime[tokenId] = currentTime;
        }


        claimedEchoes = durationAttuned * attunementEchoRatePerSecond;
        claimedFlux = durationAttuned * (data.level + 1); // Example: Flux gain scales with level

        if (claimedEchoes > 0) {
            _increaseEchoes(ownerOf(tokenId), claimedEchoes);
            emit EchoesClaimed(ownerOf(tokenId), tokenId, claimedEchoes);
        }
         if (claimedFlux > 0) {
            _increaseFlux(tokenId, claimedFlux);
        }

        return (claimedEchoes, claimedFlux);
    }

    // Internal minting helper (used by mintEssence and potentially combineEssences)
    function _mintEssenceInternal(address to, uint8 initialType) internal returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);

        essenceData[tokenId] = EssenceData({
            level: 1, // Start at level 1
            essenceType: EssenceType(initialType),
            fluxPoints: 0,
            state: EssenceState.Dormant
        });

        emit EssenceMinted(to, tokenId, initialType);
    }

    // Internal burn helper (used by combineEssences and burnEssence)
    function _burnEssenceInternal(uint256 tokenId) internal {
        address currentOwner = ownerOf(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoSphere: caller is not owner or approved");
        require(attunementEndTime[tokenId] <= block.timestamp, "ChronoSphere: cannot burn attuned essence");

        // Clean up state data
        delete essenceData[tokenId];
        delete attunementEndTime[tokenId];
        delete attunementStartTime[tokenId];

        _burn(tokenId);
    }


    // --- ERC721 Standard Implementations (Overrides) ---

    // All standard ERC721 functions are provided by OpenZeppelin's ERC721 base contract.
    // We list them here for the function count summary.
    // 1. balanceOf
    // 2. ownerOf
    // 3. safeTransferFrom (overloaded versions)
    // 4. transferFrom
    // 5. approve
    // 6. setApprovalForAll
    // 7. getApproved
    // 8. isApprovedForAll

    // --- ERC721 Metadata & Enumerable (Overrides) ---

    // 9. tokenURI: Generates a dynamic metadata URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // In a real dApp, this URI would point to an API endpoint like:
        // https://api.yourdapp.com/metadata/{tokenId}
        // The API would read the on-chain state (level, type, state, flux)
        // and generate a JSON file according to the ERC721 metadata standard.
        // For simplicity here, we return a base URI + token ID.
        // A more advanced on-chain approach could build the JSON string directly,
        // but this is very gas-intensive.
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        if (bytes(base).length > 0 && bytes(base)[bytes(base).length - 1] == "/") {
            return string(abi.encodePacked(base, tokenId.toString()));
        }
        return string(abi.encodePacked(base, "/", tokenId.toString()));

        /*
        // Example of building dynamic JSON on-chain (expensive!)
        EssenceData storage data = essenceData[tokenId];
        string memory json = string(abi.encodePacked(
            '{"name": "Essence #', tokenId.toString(),
            '", "description": "An evolving ethereal essence.",',
            '"attributes": [',
            '{"trait_type": "Level", "value": ', data.level.toString(), '},',
            '{"trait_type": "Type", "value": "', _getEssenceTypeString(data.essenceType), '"},',
            '{"trait_type": "State", "value": "', _getEssenceStateString(data.state), '"},',
            '{"trait_type": "Flux Points", "value": ', data.fluxPoints.toString(), '}',
            ']}'
        ));
        string memory base64Json = Base64.encode(bytes(json));
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
        */
    }

    // Helper for generating metadata strings (if building JSON on-chain)
    function _getEssenceTypeString(EssenceType _type) internal pure returns (string memory) {
        if (_type == EssenceType.Core) return "Core";
        if (_type == EssenceType.Stellar) return "Stellar";
        if (_type == EssenceType.Quantum) return "Quantum";
        return "Unknown"; // Should not happen
    }

     // Helper for generating metadata strings (if building JSON on-chain)
    function _getEssenceStateString(EssenceState _state) internal pure returns (string memory) {
        if (_state == EssenceState.Dormant) return "Dormant";
        if (_state == EssenceState.Attuned) return "Attuned";
        if (_state == EssenceState.Volatile) return "Volatile";
        return "Unknown"; // Should not happen
    }


    // 10. totalSupply: Get the total count of NFTs minted
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // 11. tokenByIndex: Get token ID by its global index (can be expensive for large collections)
    function tokenByIndex(uint256 index) public view returns (uint256) {
         // Note: ERC721Enumerable provides this efficiently. Without it,
         // implementing this on-chain loop is gas-prohibitive for large counts.
         // For demonstration, we'll assume an internal array or use OZ's Enumerable
         // if we were to inherit it fully. Since we aren't inheriting Enumerable
         // to keep the example focused on custom logic, a full implementation
         // without an internal ID array is impossible. We'll return 0 as a placeholder.
         // A real implementation would require tracking token IDs in an array or using OZ's extension.
         revert("ChronoSphere: tokenByIndex is not implemented for this custom ERC721 without Enumerable extension");
         // return _allTokens[index]; // Example if _allTokens array existed
    }

    // 12. tokenOfOwnerByIndex: Get token ID of owner by its index within their collection (costly)
     function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
         // Same note as tokenByIndex applies. Requires tracking owner's tokens in an array.
         revert("ChronoSphere: tokenOfOwnerByIndex is not implemented for this custom ERC721 without Enumerable extension");
         // return _ownedTokens[owner][index]; // Example if _ownedTokens mapping existed
    }


    // --- Core Engine - Minting & Access ---

    // 13. mintEssence: Mints a new base Essence NFT
    function mintEssence(uint8 initialType) public payable returns (uint256) {
        require(initialType < uint8(EssenceType.Volatile), "ChronoSphere: Invalid initial essence type"); // Example type validation
        require(msg.value >= essenceMintCost, "ChronoSphere: Insufficient mint cost");

        uint256 newTokenId = _mintEssenceInternal(msg.sender, initialType);

        // Refund excess payment if any
        if (msg.value > essenceMintCost) {
            payable(msg.sender).transfer(msg.value - essenceMintCost);
        }

        return newTokenId;
    }


    // --- Core Engine - Dynamic State & Resources ---

    // 14. getEssenceDetails: Get all dynamic data for an Essence
    function getEssenceDetails(uint256 tokenId) public view returns (EssenceData memory) {
        require(_exists(tokenId), "ChronoSphere: token does not exist");
        return essenceData[tokenId];
    }

    // 15. getFluxPoints: Get current Flux Points for an Essence
    function getFluxPoints(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronoSphere: token does not exist");
        return essenceData[tokenId].fluxPoints;
    }

    // 16. getChrononEchoBalance: Get Chronon Echo balance for an address
    function getChrononEchoBalance(address account) public view returns (uint256) {
        return chrononEchoBalances[account];
    }

    // 17. calculateEarnedEchoes: Calculate pending Echoes for an attuned Essence
    function calculateEarnedEchoes(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronoSphere: token does not exist");
        require(attunementEndTime[tokenId] > block.timestamp, "ChronoSphere: essence is not attuned or attunement ended");
        uint64 startTime = attunementStartTime[tokenId];
        uint64 endTime = attunementEndTime[tokenId];

        // Calculate based on time since start or last claim, capped by end time
        uint64 currentTime = uint64(block.timestamp);
        uint64 effectiveEndTime = currentTime > endTime ? endTime : currentTime; // Cap by end time or current time

        if (effectiveEndTime <= startTime) {
            return 0; // No time elapsed since start/last claim
        }

        uint66 durationAttuned = effectiveEndTime - startTime;
        return durationAttuned * attunementEchoRatePerSecond;
    }


    // --- Core Engine - Evolution & Combination ---

    // 18. evolveEssence: Attempts to evolve an Essence NFT
    function evolveEssence(uint256 tokenId, uint8 evolutionPath) public requiresEssenceOwnership(tokenId) requiresNotAttuned(tokenId) {
        EssenceData storage data = essenceData[tokenId];
        uint256 requiredFlux = baseEvolutionFluxCost * (data.level + 1); // Example: cost increases with level

        require(data.fluxPoints >= requiredFlux, "ChronoSphere: Insufficient Flux for evolution");
        require(data.fluxPoints >= minFluxForEvolution, "ChronoSphere: Minimum Flux threshold not met");
        require(data.level < 10, "ChronoSphere: Essence has reached maximum level"); // Example max level

        // Simulate evolution logic based on type, level, path, etc.
        // This would contain specific rules. Example:
        // if (data.essenceType == EssenceType.Core && evolutionPath == 1) { ... }
        // if (data.essenceType == EssenceType.Stellar && data.level >= 3 && evolutionPath == 2) { ... }

        // For simplicity, generic evolution:
        _decreaseFlux(tokenId, requiredFlux);
        data.level++;
        // data.essenceType = simulateTypeChange(data.essenceType, evolutionPath); // Could change type

        emit EssenceEvolved(tokenId, data.level, data.essenceType);
    }

    // 19. combineEssences: Combines multiple Essence NFTs into a new one
    function combineEssences(uint256[] calldata tokenIds) public {
        require(tokenIds.length >= 2, "ChronoSphere: Must provide at least 2 essences to combine");
        require(tokenIds.length <= 5, "ChronoSphere: Cannot combine more than 5 essences"); // Example limit

        uint256 totalFlux = 0;
        // Check ownership, not attuned, and sum up resources
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "ChronoSphere: token does not exist");
            require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoSphere: caller is not owner or approved for token to combine");
            require(attunementEndTime[tokenId] <= block.timestamp, "ChronoSphere: cannot combine attuned essence");

            totalFlux += essenceData[tokenId].fluxPoints;

            // Add other combination checks, e.g., require specific types or levels
            // require(essenceData[tokenId].essenceType == EssenceType.Core, "ChronoSphere: Can only combine Core essences");
        }

         // Simulate combination logic - consumes inputs, maybe mints a new one
         // Example: Requires certain types, sufficient total flux.
         // This is highly application specific. For simplicity, we'll burn inputs
         // and mint a new one with flux derived from the combined total.

        uint256 requiredTotalFlux = 2000 * tokenIds.length; // Example cost scale
        require(totalFlux >= requiredTotalFlux, "ChronoSphere: Insufficient total Flux for combination");


        // Burn input tokens and collect flux
        for (uint i = 0; i < tokenIds.length; i++) {
            _burnEssenceInternal(tokenIds[i]); // Burns the token and cleans up state
        }

        // Determine the output essence based on inputs (placeholder logic)
        uint8 newEssenceType = 0; // Default to Core
        if (totalFlux > 5000) newEssenceType = 1; // Stellar
        if (totalFlux > 10000) newEssenceType = 2; // Quantum

        uint256 newTokenId = _mintEssenceInternal(msg.sender, newEssenceType);

        // Grant some of the combined flux to the new essence
        _increaseFlux(newTokenId, totalFlux / 2); // Example: 50% flux is retained

        // Set initial level for the new combined essence (example: based on num inputs)
        essenceData[newTokenId].level = uint8(tokenIds.length); // New level based on inputs

        emit EssenceCombined(msg.sender, tokenIds, newTokenId);
    }


    // --- Core Engine - Attunement (Staking) ---

    // 20. attuneEssence: Locks an Essence for a duration
    function attuneEssence(uint256 tokenId, uint64 durationSeconds) public requiresEssenceOwnership(tokenId) requiresNotAttuned(tokenId) {
        require(durationSeconds > 0, "ChronoSphere: Attunement duration must be greater than zero");
        require(durationSeconds <= 365 * 24 * 3600, "ChronoSphere: Attunement duration too long (max 1 year)"); // Example limit

        attunementStartTime[tokenId] = uint64(block.timestamp);
        attunementEndTime[tokenId] = uint64(block.timestamp + durationSeconds);
        essenceData[tokenId].state = EssenceState.Attuned;

        // Note: Rewards (Echoes/Flux) are earned passively over time, claimed on unattune or explicitly
        emit EssenceAttuned(tokenId, msg.sender, durationSeconds, attunementEndTime[tokenId]);
    }

    // 21. unattuneEssence: Unlocks an attuned Essence and claims rewards
    function unattuneEssence(uint256 tokenId) public requiresEssenceOwnership(tokenId) requiresAttuned(tokenId) {
        // Calculate and claim pending rewards up to now or end time
        (uint256 claimedEchoes, uint256 claimedFlux) = _claimAttunementRewardsInternal(tokenId);

        // Only allow full unattune after the lock-up period ends
        require(attunementEndTime[tokenId] <= block.timestamp, "ChronoSphere: Attunement period has not ended yet");

        // Reset attunement state
        delete attunementStartTime[tokenId];
        delete attunementEndTime[tokenId];
        essenceData[tokenId].state = EssenceState.Dormant;

        emit EssenceUnattuned(tokenId, msg.sender, claimedEchoes, claimedFlux);
    }

    // 22. claimAttunementRewards: Claims earned rewards without unattuning (if attunement is ongoing)
    function claimAttunementRewards(uint256 tokenId) public requiresEssenceOwnership(tokenId) requiresAttuned(tokenId) {
        // This function simply calls the internal claim logic
         _claimAttunementRewardsInternal(tokenId);
        // The internal function emits the EchoesClaimed and FluxGained events
    }


    // --- Core Engine - Resource Management ---

    // 23. transferFluxPoints: Transfer Flux between Essences owned by the caller
    function transferFluxPoints(uint256 fromTokenId, uint256 toTokenId, uint256 amount) public {
        require(_exists(fromTokenId), "ChronoSphere: fromToken does not exist");
        require(_exists(toTokenId), "ChronoSphere: toToken does not exist");
        require(fromTokenId != toTokenId, "ChronoSphere: Cannot transfer flux to the same token");
        require(_isApprovedOrOwner(msg.sender, fromTokenId), "ChronoSphere: caller is not owner or approved for source token");
        require(_isApprovedOrOwner(msg.sender, toTokenId), "ChronoSphere: caller is not owner or approved for destination token");
        // Optionally require tokens are not attuned or in a specific state

        _decreaseFlux(fromTokenId, amount);
        _increaseFlux(toTokenId, amount);

        emit FluxTransferred(fromTokenId, toTokenId, amount);
    }

    // 24. injectFlux: Simulate external Flux injection (e.g., from a game mechanic or other contract)
    function injectFlux(uint256 tokenId, uint256 amount) public onlyOwner { // Example: Only owner can inject
        require(_exists(tokenId), "ChronoSphere: token does not exist");
        _increaseFlux(tokenId, amount);
        // Note: emits FluxGained via internal helper
    }

     // 25. burnEssence: Allows the owner to permanently destroy an Essence
    function burnEssence(uint256 tokenId) public requiresEssenceOwnership(tokenId) requiresNotAttuned(tokenId) {
        _burnEssenceInternal(tokenId);
        // Note: ERC721 _burn emits the Transfer event (to address(0))
    }


    // --- Governance ---

    // 26. submitProposal: Allows users with enough Echoes to propose changes
    function submitProposal(string calldata description, uint8 proposalType, bytes calldata proposalData) public requiresMinEchoes(proposalThresholdEchoes) returns (uint256 proposalId) {
        _proposalIdCounter.increment();
        proposalId = _proposalIdCounter.current();

        // Take a snapshot of the total Echo supply and proposer's Echoes at this moment
        // A more advanced system would track individual voter balances at the snapshot block.
        // For simplicity here, we only snapshot the *total* supply, and voters' *current* echoes are used (simple majority of participating echoes).
        // To be truly robust, you'd store mapping(address => uint256) balanceSnapshot for each proposal.
        // Let's simplify and just record the proposer's balance for a simple check,
        // and require voters to have *some* non-zero echo balance *when voting*.
        // A proper system needs a snapshot pattern (e.g., like Compound's GovernorAlpha/Bravo).
        // Let's use the *current* Echo balance at the time of *voting* for simplicity,
        // but record the total supply at snapshot time as a potential baseline.
        uint256 totalEchoSupply = 0; // Need a way to track this easily... let's skip total supply snapshot for this example.

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: description,
            proposalType: proposalType,
            proposalData: proposalData,
            snapshotEchoTotal: 0, // Simplified: not tracking total supply snapshot
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            endTime: uint64(block.timestamp + proposalVotingPeriodSeconds)
        });
         // No need for proposalVoteSnapshot map if using current balance at vote time

        emit ProposalSubmitted(proposalId, msg.sender, description, proposals[proposalId].endTime);

        return proposalId;
    }

    // 27. voteOnProposal: Cast a vote on an active proposal
    function voteOnProposal(uint256 proposalId, bool support) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.endTime, "ChronoSphere: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "ChronoSphere: Already voted on this proposal");
        require(chrononEchoBalances[msg.sender] > 0, "ChronoSphere: Must have Chronon Echoes to vote"); // Use current balance

        uint256 votingWeight = chrononEchoBalances[msg.sender]; // Voting weight = current Echo balance

        if (support) {
            proposal.votesFor += votingWeight;
        } else {
            proposal.votesAgainst += votingWeight;
        }

        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, votingWeight);
    }

    // 28. executeProposal: Attempt to execute a passed proposal
    function executeProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "ChronoSphere: Voting period has not ended");
        require(!proposal.executed, "ChronoSphere: Proposal already executed");

        // Example simplified passing condition: More FOR votes than AGAINST votes
        // A real system might require a minimum quorum (percentage of total supply or voters participating)
        require(proposal.votesFor > proposal.votesAgainst, "ChronoSphere: Proposal did not pass");

        // Execute the proposal based on its type
        if (proposal.proposalType == ProposalType.UpdateEvolutionCost) {
             require(proposal.proposalData.length == 32, "ChronoSphere: Invalid proposal data for UpdateEvolutionCost");
             (uint256 newValue) = abi.decode(proposal.proposalData, (uint256));
             baseEvolutionFluxCost = newValue;
             // Emit a specific ConfigUpdated event or rely on the general one below
        }
        // Add other execution types here

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
         // Emit a general config updated event if execution changed a config parameter
         // emit ConfigUpdated(uint8(proposal.proposalType), ...); // Need logic to map type to param/value
    }

    // 29. getProposalDetails: View function for proposal details
    function getProposalDetails(uint256 proposalId) public view proposalExists(proposalId) returns (
        address proposer,
        string memory description,
        uint8 proposalType,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        uint64 endTime
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.proposalType,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.endTime
        );
    }

    // 30. getVoteStatus: Check if an address has voted on a proposal
    function getVoteStatus(uint256 proposalId, address account) public view proposalExists(proposalId) returns (bool hasVoted) {
        return proposals[proposalId].hasVoted[account];
    }

    // 31. getProposalCount: Get the total number of proposals submitted
    function getProposalCount() public view returns (uint256) {
        return _proposalIdCounter.current();
    }


    // --- Admin & Configuration (Owner Only) ---

    // 32. setBaseURI: Update the base URI for token metadata
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    // 33. updateConfig: Generic function to update various configuration parameters
    // Using an enum allows changing multiple parameters via one function and potentially governance
    enum ConfigParam { AttunementEchoRate, BaseEvolutionFluxCost, MinFluxForEvolution, EssenceMintCost, ProposalThresholdEchoes, ProposalVotingPeriod }

    function updateConfig(uint8 paramType, uint256 value) public onlyOwner { // Could add governance check here later
        ConfigParam param = ConfigParam(paramType);
        if (param == ConfigParam.AttunementEchoRate) {
            attunementEchoRatePerSecond = value;
        } else if (param == ConfigParam.BaseEvolutionFluxCost) {
            baseEvolutionFluxCost = value;
        } else if (param == ConfigParam.MinFluxForEvolution) {
            minFluxForEvolution = value;
        } else if (param == ConfigParam.EssenceMintCost) {
            essenceMintCost = value;
        } else if (param == ConfigParam.ProposalThresholdEchoes) {
             proposalThresholdEchoes = value;
        } else if (param == ConfigParam.ProposalVotingPeriod) {
             require(value > 0, "ChronoSphere: Voting period must be > 0");
             // Note: value is uint256, but period is uint64
             require(value <= type(uint64).max, "ChronoSphere: Voting period too large");
             proposalVotingPeriodSeconds = uint64(value);
        } else {
            revert("ChronoSphere: Invalid config parameter type");
        }
        emit ConfigUpdated(paramType, value);
    }

    // 34. withdrawFunds: Allows owner to withdraw collected Ether (e.g., from mint fees)
    function withdrawFunds(address payable recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "ChronoSphere: No funds to withdraw");
        payable(recipient).transfer(balance);
    }

    // --- Receive/Fallback for payments ---
    receive() external payable {}
    fallback() external payable {}
}
```