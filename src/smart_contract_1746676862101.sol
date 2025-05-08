Okay, here is a Solidity smart contract concept called "AIArtworkGenesis".

This contract combines several advanced and trendy ideas:
1.  **NFTs (ERC-721):** Standard ownership of digital art.
2.  **Generative/Dynamic Art (Simulated):** Art traits are stored on-chain and can evolve (mutate). The `tokenURI` points to an off-chain renderer that uses these traits.
3.  **AI Integration (Conceptual):** The initial traits are influenced by a "prompt hash" provided during minting (simulating AI input), and mutations could conceptually be AI-driven (though executed by an oracle).
4.  **On-Chain Traits:** Key art properties are stored directly in the contract state.
5.  **Mutation/Evolution:** Owners can trigger a process (potentially costing tokens/ETH) to mutate their artwork's traits, making it dynamic. An oracle or admin role finalizes the mutation.
6.  **NFT-based Governance (Lite DAO):** NFT holders can propose and vote on changes to contract parameters (like mint cost, mutation cost, voting periods), giving them a say in the project's evolution.
7.  **ERC-2981 Royalties:** Standard way to handle secondary sale royalties.

**Why it's (Hopefully) Not Duplicated:** While individual components exist (NFTs, generative art, DAOs), the specific combination of:
*   On-chain traits influencing off-chain AI-like rendering.
*   User-initiated *and* externally-executed (oracle/admin) mutation process tied to on-chain traits.
*   NFT-weighted governance specifically over the parameters affecting the art's creation and evolution.
*   Simulation of "prompt hash" input during minting.

This specific synthesis aims for novelty beyond a standard generative PFP project or a simple DAO.

---

**Outline and Function Summary**

**Contract Name:** AIArtworkGenesis

**Core Concept:** A generative AI art project where unique pieces are minted as NFTs. The art's visual representation is derived from on-chain traits, which can evolve through a "mutation" process initiated by the owner and executed by an authorized entity (oracle/admin). NFT holders participate in governance to influence contract parameters.

**Interfaces & Libraries Used (Standard OpenZeppelin for best practice and security, not custom code):**
*   ERC721: For NFT standard implementation.
*   ERC2981: For NFT royalty standard implementation.
*   Ownable: For basic admin control.

**State Variables:**
*   `_tokenIdCounter`: Tracks total minted tokens.
*   `_maxSupply`: Maximum number of tokens.
*   `_mintPrice`: Cost to mint a new token.
*   `_mutationCost`: Cost to initiate a mutation.
*   `_minMutationInterval`: Minimum time between mutations for a single token.
*   `_baseTokenURI`: Base URI for metadata (points to an external server interpreting on-chain traits).
*   `_oracleAddress`: Address authorized to execute mutations.
*   `_paused`: Minting pause flag.
*   `artworks`: Mapping from token ID to `ArtworkData` struct.
*   `lastMutationTime`: Mapping from token ID to timestamp of last mutation.
*   `mutationRequests`: Mapping from token ID to `MutationRequest` struct (pending mutations).
*   `proposals`: Mapping from proposal ID to `Proposal` struct.
*   `proposalCount`: Counter for proposals.
*   `votesCast`: Mapping from proposal ID to voter address to boolean (voted or not).
*   `_votingPeriod`: Duration a proposal is open for voting.
*   `_quorumPercentage`: Percentage of total token supply required for a proposal to be valid.
*   `_royaltyRecipient`: Address receiving royalties.
*   `_royaltyFeeNumerator`: Numerator for royalty fee calculation (denominator is 10000).

**Structs:**
*   `ArtworkData`: Stores `initialPromptHash`, `birthTimestamp`, `mutationCount`, `traits` (dynamic array of uint256 representing different trait values).
*   `MutationRequest`: Stores the `requester`, `requestTimestamp`, `mutationType`, `mutationParams` for a pending mutation.
*   `Proposal`: Stores `proposer`, `description`, `targetContract`, `callData`, `startTimestamp`, `endTimestamp`, `yesVotes`, `noVotes`, `executed`, `state` (enum).

**Enums:**
*   `ProposalState`: `Pending`, `Active`, `Canceled`, `Defeated`, `Succeeded`, `Executed`.

**Events:**
*   `ArtworkMinted(uint256 tokenId, address minter, string initialPromptHash)`
*   `ArtworkMutated(uint256 tokenId, address executor, uint256 mutationType, uint256 mutationCount, uint256[] newTraits)`
*   `MutationRequested(uint256 tokenId, address requester, uint256 mutationType)`
*   `MutationRequestCanceled(uint256 tokenId)`
*   `ProposalCreated(uint256 proposalId, address proposer, string description)`
*   `VoteCast(uint256 proposalId, address voter, bool support, uint256 weight)`
*   `ProposalExecuted(uint256 proposalId)`
*   `ParametersChanged(string parameterName, uint256 oldValue, uint256 newValue)` (Generic event for admin/governance changes)

**Functions (20+ Required):**

*   **Core ERC-721 / Standard:**
    1.  `balanceOf(address owner) view`: Returns the number of tokens owned by an address.
    2.  `ownerOf(uint256 tokenId) view`: Returns the owner of a token.
    3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers token ownership.
    4.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership (unsafe).
    5.  `approve(address to, uint256 tokenId)`: Approves an address to spend a token.
    6.  `getApproved(uint256 tokenId) view`: Gets the approved address for a token.
    7.  `setApprovalForAll(address operator, bool approved)`: Approves or removes approval for an operator for all tokens.
    8.  `isApprovedForAll(address owner, address operator) view`: Checks if an operator is approved for an owner.
    9.  `totalSupply() view`: Returns the total number of tokens in existence.
    10. `tokenByIndex(uint256 index) view`: Returns the token ID at a specific index (enumeration).
    11. `tokenOfOwnerByIndex(address owner, uint256 index) view`: Returns the token ID at a specific index for an owner (enumeration).
    12. `tokenURI(uint256 tokenId) view override`: Returns the metadata URI for a token, incorporating the base URI and token ID.

*   **Custom Artwork & Minting:**
    13. `mint(string memory initialPromptHash) payable`: Mints a new unique artwork, requires payment, assigns initial traits based on hash (simplified).
    14. `batchMint(uint256 count, string[] memory initialPromptHashes) payable`: Mints multiple artworks in one transaction.
    15. `getArtworkData(uint256 tokenId) view`: Retrieves the full on-chain trait data and history for a token.
    16. `setMaxSupply(uint256 supply)`: Admin function to set maximum total tokens.
    17. `setMintPrice(uint256 price)`: Admin function to set the minting cost.
    18. `pauseMinting()`: Admin function to pause minting.
    19. `unpauseMinting()`: Admin function to unpause minting.

*   **Mutation & Evolution:**
    20. `initiateMutation(uint256 tokenId, uint256 mutationType, string memory mutationParameters) payable`: Owner initiates a mutation request for their token, pays the mutation cost.
    21. `executeMutation(uint256 tokenId, uint256[] memory newTraits)`: Callable ONLY by the `_oracleAddress`. Finalizes a pending mutation request and updates the token's traits.
    22. `cancelMutationRequest(uint256 tokenId)`: Owner or admin can cancel a pending mutation request.
    23. `getMutationRequest(uint256 tokenId) view`: Checks for and returns details of a pending mutation request for a token.
    24. `setMutationCost(uint256 cost)`: Admin function to set the cost to initiate a mutation.
    25. `setMinMutationInterval(uint256 interval)`: Admin function to set the minimum time between mutations for a token.
    26. `setOracleAddress(address oracle)`: Admin function to set the authorized oracle address.

*   **Governance (NFT-Weighted):**
    27. `submitProposal(string memory description, address targetContract, bytes memory callData)`: NFT holders (`balanceOf(msg.sender) > 0`) can submit a proposal to call a function on a target contract (potentially this contract itself to change parameters).
    28. `voteOnProposal(uint256 proposalId, bool support)`: NFT holders can vote on an active proposal. Voting weight is based on the number of tokens they hold at the time of voting.
    29. `getProposalState(uint256 proposalId) view`: Returns the current state of a proposal (Pending, Active, Defeated, etc.).
    30. `executeProposal(uint256 proposalId)`: Any address can call this to attempt to execute a successful proposal after the voting period ends.
    31. `setVotingPeriod(uint256 period)`: Admin function to set the duration proposals are active.
    32. `setQuorumPercentage(uint256 quorumPercentage)`: Admin function to set the percentage of total supply needed for a proposal to be valid.

*   **Royalty (ERC-2981):**
    33. `royaltyInfo(uint256 tokenId, uint256 salePrice) view override`: Returns royalty recipient and amount based on standard (set via admin).
    34. `setDefaultRoyalty(address recipient, uint96 feeNumerator)`: Admin function to set the default royalty information.

*   **Admin / Utility:**
    35. `withdraw()`: Owner can withdraw accumulated Ether.
    36. `setBaseURI(string memory baseURI)`: Admin function to set the base for token metadata URIs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";


/*
 * Outline and Function Summary
 *
 * Contract Name: AIArtworkGenesis
 *
 * Core Concept:
 * A generative AI art project where unique pieces are minted as NFTs (ERC-721).
 * The art's visual representation is derived from on-chain traits stored within the contract.
 * These traits can evolve through a "mutation" process initiated by the owner and
 * executed by an authorized entity (oracle/admin). NFT holders participate in
 * governance (a simple DAO) to propose and vote on changes to contract parameters,
 * such as mint cost, mutation cost, or voting periods, giving them a say in the
 * project's evolution. Initial art generation parameters are influenced by a "prompt hash"
 * provided during minting. Royalties on secondary sales are supported via ERC-2981.
 *
 * State Variables:
 * _tokenIdCounter: Tracks total minted tokens.
 * _maxSupply: Maximum number of tokens that can be minted.
 * _mintPrice: Cost in wei to mint a new token.
 * _mutationCost: Cost in wei to initiate a mutation request.
 * _minMutationInterval: Minimum time in seconds between mutations for a single token.
 * _baseTokenURI: Base URI for metadata (points to an external server interpreting on-chain traits).
 * _oracleAddress: Address authorized to execute mutations.
 * _paused: Flag to pause minting.
 * artworks: Mapping from token ID to ArtworkData struct.
 * lastMutationTime: Mapping from token ID to timestamp of last mutation.
 * mutationRequests: Mapping from token ID to MutationRequest struct (pending mutations).
 * proposals: Mapping from proposal ID to Proposal struct.
 * proposalCount: Counter for governance proposals.
 * votesCast: Mapping from proposal ID to voter address to boolean (to prevent double voting).
 * _votingPeriod: Duration in seconds a proposal is open for voting.
 * _quorumPercentage: Percentage (0-100) of total token supply (at vote time) required for a proposal to be valid.
 * _royaltyRecipient: Address receiving royalties.
 * _royaltyFeeNumerator: Numerator for royalty fee calculation (denominator is 10000).
 *
 * Structs:
 * ArtworkData: Stores token-specific data: initialPromptHash, birthTimestamp, mutationCount, traits.
 * MutationRequest: Stores details of a pending mutation request: requester, requestTimestamp, type, params.
 * Proposal: Stores governance proposal details: proposer, description, targetContract, callData, timestamps, votes, state.
 *
 * Enums:
 * ProposalState: Tracks the lifecycle of a proposal (Pending, Active, Canceled, Defeated, Succeeded, Executed).
 *
 * Events:
 * ArtworkMinted: Logs when a new token is minted.
 * ArtworkMutated: Logs when a token's traits are updated by an executor (oracle/admin).
 * MutationRequested: Logs when an owner initiates a mutation request.
 * MutationRequestCanceled: Logs when a pending mutation request is canceled.
 * ProposalCreated: Logs when a new governance proposal is submitted.
 * VoteCast: Logs when a token holder votes on a proposal.
 * ProposalExecuted: Logs when a governance proposal is successfully executed.
 * ParametersChanged: Generic event for tracking key parameter updates (admin or governance).
 *
 * Functions (36 Total):
 * Core ERC-721 / Standard (12):
 * 1.  balanceOf(address owner) view
 * 2.  ownerOf(uint256 tokenId) view
 * 3.  safeTransferFrom(address from, address to, uint256 tokenId)
 * 4.  transferFrom(address from, address to, uint256 tokenId)
 * 5.  approve(address to, uint256 tokenId)
 * 6.  getApproved(uint256 tokenId) view
 * 7.  setApprovalForAll(address operator, bool approved)
 * 8.  isApprovedForAll(address owner, address operator) view
 * 9.  totalSupply() view
 * 10. tokenByIndex(uint256 index) view
 * 11. tokenOfOwnerByIndex(address owner, uint256 index) view
 * 12. tokenURI(uint256 tokenId) view override
 *
 * Custom Artwork & Minting (7):
 * 13. mint(string memory initialPromptHash) payable
 * 14. batchMint(uint256 count, string[] memory initialPromptHashes) payable
 * 15. getArtworkData(uint256 tokenId) view
 * 16. setMaxSupply(uint256 supply) onlyOwner
 * 17. setMintPrice(uint256 price) onlyOwner
 * 18. pauseMinting() onlyOwner
 * 19. unpauseMinting() onlyOwner
 *
 * Mutation & Evolution (7):
 * 20. initiateMutation(uint256 tokenId, uint256 mutationType, string memory mutationParameters) payable
 * 21. executeMutation(uint256 tokenId, uint256[] memory newTraits) onlyOracle
 * 22. cancelMutationRequest(uint256 tokenId)
 * 23. getMutationRequest(uint256 tokenId) view
 * 24. setMutationCost(uint256 cost) onlyOwner
 * 25. setMinMutationInterval(uint256 interval) onlyOwner
 * 26. setOracleAddress(address oracle) onlyOwner
 *
 * Governance (NFT-Weighted) (6):
 * 27. submitProposal(string memory description, address targetContract, bytes memory callData)
 * 28. voteOnProposal(uint256 proposalId, bool support)
 * 29. getProposalState(uint256 proposalId) view
 * 30. executeProposal(uint256 proposalId)
 * 31. setVotingPeriod(uint256 period) onlyOwner
 * 32. setQuorumPercentage(uint256 quorumPercentage) onlyOwner
 *
 * Royalty (ERC-2981) (2):
 * 33. royaltyInfo(uint256 tokenId, uint256 salePrice) view override
 * 34. setDefaultRoyalty(address recipient, uint96 feeNumerator) onlyOwner
 *
 * Admin / Utility (2):
 * 35. withdraw() onlyOwner
 * 36. setBaseURI(string memory baseURI) onlyOwner
 */

contract AIArtworkGenesis is ERC721Enumerable, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    Counters.Counter private _tokenIdCounter;

    uint256 public _maxSupply;
    uint256 public _mintPrice;
    uint256 public _mutationCost;
    uint256 public _minMutationInterval; // Minimum time between mutations for a single token
    string private _baseTokenURI;
    address public _oracleAddress;
    bool public _paused = false;

    struct ArtworkData {
        string initialPromptHash; // Represents initial AI input parameters
        uint256 birthTimestamp;
        uint256 mutationCount;
        uint256[] traits; // Array representing different art traits (e.g., color palette, style ID, form parameters)
        // Note: The interpretation of these traits into visual art happens off-chain
    }

    mapping(uint256 => ArtworkData) private artworks;
    mapping(uint256 => uint256) private lastMutationTime; // tokenId => timestamp

    struct MutationRequest {
        address requester;
        uint256 requestTimestamp;
        uint256 mutationType; // Identifier for the type of mutation requested
        string mutationParameters; // Optional parameters for the mutation
        bool exists; // To check if a request exists for a token ID
    }

    mapping(uint256 => MutationRequest) public mutationRequests; // tokenId => request details

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address targetContract;
        bytes callData;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        ProposalState state;
    }

    mapping(uint256 => Proposal) private proposals;
    mapping(uint256 => mapping(address => bool)) private votesCast; // proposalId => voter => voted
    uint256 public proposalCount;

    uint256 public _votingPeriod; // in seconds
    uint256 public _quorumPercentage; // 0-100

    address payable public _royaltyRecipient;
    uint96 public _royaltyFeeNumerator; // Fee numerator (denominator is 10000 for 100%)

    // Modifiers
    modifier onlyOracle() {
        require(msg.sender == _oracleAddress, "Caller is not the oracle");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposalCount, "Proposal does not exist");
        _;
    }

    modifier activeProposal(uint256 proposalId) {
        proposalExists(proposalId);
        require(proposals[proposalId].state == ProposalState.Active, "Proposal is not active");
        _;
    }

    // Events
    event ArtworkMinted(uint256 tokenId, address minter, string initialPromptHash);
    event ArtworkMutated(uint256 tokenId, address executor, uint256 mutationType, uint256 mutationCount, uint256[] newTraits);
    event MutationRequested(uint256 tokenId, address requester, uint256 mutationType);
    event MutationRequestCanceled(uint256 tokenId);
    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event VoteCast(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 proposalId);
    event ParametersChanged(string parameterName, uint256 oldValue, uint256 newValue, uint256 newUintValue, string newStringValue, address newAddressValue);


    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 mintPrice,
        uint256 mutationCost,
        uint256 minMutationInterval,
        address oracleAddress,
        string memory baseTokenURI,
        uint256 votingPeriod,
        uint256 quorumPercentage,
        address royaltyRecipient,
        uint96 royaltyFeeNumerator
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _maxSupply = maxSupply;
        _mintPrice = mintPrice;
        _mutationCost = mutationCost;
        _minMutationInterval = minMutationInterval;
        _oracleAddress = oracleAddress;
        _baseTokenURI = baseTokenURI;
        _votingPeriod = votingPeriod;
        _quorumPercentage = quorumPercentage;
        _royaltyRecipient = payable(royaltyRecipient);
        _royaltyFeeNumerator = royaltyFeeNumerator;

        emit ParametersChanged("maxSupply", 0, maxSupply, maxSupply, "", address(0));
        emit ParametersChanged("mintPrice", 0, mintPrice, mintPrice, "", address(0));
        emit ParametersChanged("mutationCost", 0, mutationCost, mutationCost, "", address(0));
        emit ParametersChanged("minMutationInterval", 0, minMutationInterval, minMutationInterval, "", address(0));
        emit ParametersChanged("oracleAddress", 0, 0, 0, "", oracleAddress);
        emit ParametersChanged("baseTokenURI", 0, 0, 0, baseTokenURI, address(0));
        emit ParametersChanged("votingPeriod", 0, votingPeriod, votingPeriod, "", address(0));
        emit ParametersChanged("quorumPercentage", 0, quorumPercentage, quorumPercentage, "", address(0));
        emit ParametersChanged("royaltyRecipient", 0, 0, 0, "", royaltyRecipient);
        emit ParametersChanged("royaltyFeeNumerator", 0, royaltyFeeNumerator, royaltyFeeNumerator, "", address(0));
    }

    // --- ERC721 and ERC2981 Overrides ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        // Append tokenId to base URI. The server at base URI should serve metadata based on token ID.
        // This metadata should ideally include the on-chain traits from getArtworkData.
        string memory base = _baseTokenURI;
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Custom logic if needed before transfer, e.g., cancelling pending mutation requests on transfer
        if (from != address(0) && mutationRequests[tokenId].exists) {
             // Cancel any pending mutation request when transferred
             // Or maybe just make it non-transferable while request is pending?
             // Let's cancel for simplicity here.
             delete mutationRequests[tokenId];
             emit MutationRequestCanceled(tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        _requireMinted(tokenId); // Ensure token exists
        uint256 royaltyAmountCalculated = salePrice.mul(_royaltyFeeNumerator) / 10000; // Denominator is 10000 for 100%
        return (address(_royaltyRecipient), royaltyAmountCalculated);
    }


    // --- Custom Artwork & Minting Functions ---

    /**
     * @dev Mints a new unique artwork token.
     * @param initialPromptHash A string representing input parameters influencing initial traits (conceptual).
     */
    function mint(string memory initialPromptHash) public payable whenNotPaused {
        uint256 currentTokenId = _tokenIdCounter.current();
        require(currentTokenId < _maxSupply, "Max supply reached");
        require(msg.value >= _mintPrice, "Insufficient payment");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Simulate initial trait generation based on hash/timestamp/etc.
        // In a real system, this might involve an off-chain call or more complex on-chain logic.
        uint256[] memory initialTraits = _generateInitialTraits(newTokenId, initialPromptHash);

        artworks[newTokenId] = ArtworkData({
            initialPromptHash: initialPromptHash,
            birthTimestamp: block.timestamp,
            mutationCount: 0,
            traits: initialTraits
        });

        _safeMint(msg.sender, newTokenId);

        if (msg.value > _mintPrice) {
            // Return excess ETH
            payable(msg.sender).transfer(msg.value - _mintPrice);
        }

        emit ArtworkMinted(newTokenId, msg.sender, initialPromptHash);
    }

     /**
     * @dev Mints multiple artwork tokens in a single transaction.
     * @param count The number of tokens to mint.
     * @param initialPromptHashes An array of prompt hashes for each token.
     */
    function batchMint(uint256 count, string[] memory initialPromptHashes) public payable whenNotPaused {
        require(count > 0 && count == initialPromptHashes.length, "Invalid count or prompt hashes");
        require(_tokenIdCounter.current().add(count) <= _maxSupply, "Exceeds max supply");
        uint256 totalCost = _mintPrice.mul(count);
        require(msg.value >= totalCost, "Insufficient payment for batch mint");

        for (uint i = 0; i < count; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();

             uint256[] memory initialTraits = _generateInitialTraits(newTokenId, initialPromptHashes[i]);

            artworks[newTokenId] = ArtworkData({
                initialPromptHash: initialPromptHashes[i],
                birthTimestamp: block.timestamp,
                mutationCount: 0,
                traits: initialTraits
            });

            _safeMint(msg.sender, newTokenId);
            emit ArtworkMinted(newTokenId, msg.sender, initialPromptHashes[i]);
        }

        if (msg.value > totalCost) {
            // Return excess ETH
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }


    /**
     * @dev Retrieves the on-chain data for a specific artwork token.
     * @param tokenId The ID of the token.
     * @return ArtworkData struct containing the token's state.
     */
    function getArtworkData(uint256 tokenId) public view returns (ArtworkData memory) {
        _requireMinted(tokenId); // Ensure token exists
        return artworks[tokenId];
    }

    /**
     * @dev Admin function to set the maximum supply of tokens.
     * @param supply The new maximum supply.
     */
    function setMaxSupply(uint256 supply) public onlyOwner {
        uint256 oldSupply = _maxSupply;
        _maxSupply = supply;
        emit ParametersChanged("maxSupply", oldSupply, supply, supply, "", address(0));
    }

    /**
     * @dev Admin function to set the price for minting new tokens.
     * @param price The new mint price in wei.
     */
    function setMintPrice(uint256 price) public onlyOwner {
        uint256 oldPrice = _mintPrice;
        _mintPrice = price;
        emit ParametersChanged("mintPrice", oldPrice, price, price, "", address(0));
    }

    /**
     * @dev Admin function to pause minting.
     */
    function pauseMinting() public onlyOwner {
        require(!_paused, "Minting is already paused");
        _paused = true;
         emit ParametersChanged("paused", 0, 1, 1, "", address(0)); // Using 0/1 for boolean state
    }

    /**
     * @dev Admin function to unpause minting.
     */
    function unpauseMinting() public onlyOwner {
        require(_paused, "Minting is not paused");
        _paused = false;
        emit ParametersChanged("paused", 1, 0, 0, "", address(0)); // Using 0/1 for boolean state
    }

    // --- Mutation & Evolution Functions ---

    /**
     * @dev Allows the token owner to initiate a mutation request.
     * This requires payment and adheres to cooldowns. The actual trait change
     * is executed separately by an oracle.
     * @param tokenId The ID of the token to mutate.
     * @param mutationType An identifier for the type of mutation requested.
     * @param mutationParameters Optional string parameters for the mutation.
     */
    function initiateMutation(uint256 tokenId, uint256 mutationType, string memory mutationParameters) public payable {
        _requireOwned(tokenId);
        require(msg.sender == ownerOf(tokenId), "Must own the token to initiate mutation");
        require(msg.value >= _mutationCost, "Insufficient payment to initiate mutation");
        require(!mutationRequests[tokenId].exists, "Mutation request already pending for this token");
        require(block.timestamp >= lastMutationTime[tokenId].add(_minMutationInterval), "Mutation cooldown not over");

        mutationRequests[tokenId] = MutationRequest({
            requester: msg.sender,
            requestTimestamp: block.timestamp,
            mutationType: mutationType,
            mutationParameters: mutationParameters,
            exists: true
        });

        if (msg.value > _mutationCost) {
             payable(msg.sender).transfer(msg.value - _mutationCost); // Return excess ETH
        }

        emit MutationRequested(tokenId, msg.sender, mutationType);
    }

    /**
     * @dev Executes a pending mutation request for a token, updating its traits.
     * Callable only by the authorized oracle address.
     * @param tokenId The ID of the token to mutate.
     * @param newTraits The array of new traits for the artwork.
     */
    function executeMutation(uint256 tokenId, uint256[] memory newTraits) public onlyOracle {
         _requireMinted(tokenId); // Ensure token exists
        require(mutationRequests[tokenId].exists, "No pending mutation request for this token");

        MutationRequest storage req = mutationRequests[tokenId];
        ArtworkData storage art = artworks[tokenId];

        // Apply mutation logic (simplified here to just updating traits)
        // In a real system, _applyMutation might use req.mutationType and req.mutationParameters
        // and potentially some randomness/AI result provided by the oracle off-chain.
        art.traits = newTraits; // Oracle provides the resulting traits
        art.mutationCount = art.mutationCount.add(1);
        lastMutationTime[tokenId] = block.timestamp;

        // Clear the mutation request
        delete mutationRequests[tokenId];

        emit ArtworkMutated(tokenId, msg.sender, req.mutationType, art.mutationCount, newTraits);
    }

    /**
     * @dev Allows the token owner or admin to cancel a pending mutation request.
     * @param tokenId The ID of the token whose request to cancel.
     */
    function cancelMutationRequest(uint256 tokenId) public {
        _requireMinted(tokenId); // Ensure token exists
        require(mutationRequests[tokenId].exists, "No pending mutation request for this token");
        require(msg.sender == ownerOf(tokenId) || msg.sender == owner() || msg.sender == _oracleAddress,
               "Must be token owner, contract owner, or oracle to cancel request");

        delete mutationRequests[tokenId];
        emit MutationRequestCanceled(tokenId);
    }

    /**
     * @dev Gets the details of a pending mutation request for a token.
     * @param tokenId The ID of the token.
     * @return MutationRequest struct.
     */
    function getMutationRequest(uint256 tokenId) public view returns (MutationRequest memory) {
        return mutationRequests[tokenId]; // Returns default struct if none exists, .exists will be false
    }


    /**
     * @dev Admin function to set the cost to initiate a mutation.
     * @param cost The new mutation cost in wei.
     */
    function setMutationCost(uint256 cost) public onlyOwner {
        uint256 oldCost = _mutationCost;
        _mutationCost = cost;
        emit ParametersChanged("mutationCost", oldCost, cost, cost, "", address(0));
    }

    /**
     * @dev Admin function to set the minimum time interval between mutations for a token.
     * @param interval The new minimum interval in seconds.
     */
    function setMinMutationInterval(uint256 interval) public onlyOwner {
        uint256 oldInterval = _minMutationInterval;
        _minMutationInterval = interval;
        emit ParametersChanged("minMutationInterval", oldInterval, interval, interval, "", address(0));
    }

    /**
     * @dev Admin function to set the authorized oracle address.
     * @param oracle The new oracle address.
     */
    function setOracleAddress(address oracle) public onlyOwner {
        address oldOracle = _oracleAddress;
        _oracleAddress = oracle;
        emit ParametersChanged("oracleAddress", 0, 0, 0, "", oracle); // Use 0 for uint values when not applicable
    }


    // --- Governance (NFT-Weighted) Functions ---

    /**
     * @dev Allows any holder of an NFT from this contract to submit a governance proposal.
     * @param description A description of the proposal.
     * @param targetContract The address of the contract the proposal will interact with.
     * @param callData The encoded function call data for the target contract.
     */
    function submitProposal(string memory description, address targetContract, bytes memory callData) public {
        require(balanceOf(msg.sender) > 0, "Must hold a token to submit proposal");

        uint256 proposalId = proposalCount;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            targetContract: targetContract,
            callData: callData,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp.add(_votingPeriod),
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            state: ProposalState.Active // Proposals start active
        });
        proposalCount = proposalCount.add(1);

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /**
     * @dev Allows NFT holders to vote on an active proposal. Voting weight is based on the number of tokens held.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes' vote, False for 'no' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public activeProposal(proposalId) {
        require(balanceOf(msg.sender) > 0, "Must hold a token to vote");
        require(!votesCast[proposalId][msg.sender], "Already voted on this proposal");

        uint256 weight = balanceOf(msg.sender); // 1 token = 1 vote
        require(weight > 0, "Voting weight must be greater than 0");

        if (support) {
            proposals[proposalId].yesVotes = proposals[proposalId].yesVotes.add(weight);
        } else {
            proposals[proposalId].noVotes = proposals[proposalId].noVotes.add(weight);
        }

        votesCast[proposalId][msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, weight);
    }

    /**
     * @dev Gets the current state of a governance proposal.
     * Updates state based on time and vote counts if necessary.
     * @param proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function getProposalState(uint256 proposalId) public view proposalExists(proposalId) returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active) {
             if (block.timestamp < proposal.endTimestamp) {
                 return ProposalState.Active; // Still within voting period
             } else {
                 // Voting period ended, determine outcome
                 uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
                 uint256 currentTotalSupply = totalSupply(); // Quorum based on current supply

                 // Prevent division by zero if no tokens exist
                 bool quorumReached = currentTotalSupply == 0 ? (totalVotes == 0) : (totalVotes.mul(100) / currentTotalSupply >= _quorumPercentage);

                 if (!quorumReached) {
                     return ProposalState.Defeated; // Quorum not met
                 } else if (proposal.yesVotes > proposal.noVotes) {
                     return ProposalState.Succeeded; // Succeeded if Yes > No and quorum met
                 } else {
                     return ProposalState.Defeated; // Defeated if Yes <= No (even if quorum met)
                 }
             }
        }
        return proposal.state; // Return stored state if already Canceled, Defeated, Succeeded, Executed
    }

    /**
     * @dev Executes a governance proposal that has succeeded.
     * Callable by anyone after the voting period ends and state is Succeeded.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Proposal not in succeeded state");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        // Execute the proposed action
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Admin function to set the voting period duration for proposals.
     * @param period The new voting period in seconds.
     */
    function setVotingPeriod(uint256 period) public onlyOwner {
        uint256 oldPeriod = _votingPeriod;
        _votingPeriod = period;
        emit ParametersChanged("votingPeriod", oldPeriod, period, period, "", address(0));
    }

    /**
     * @dev Admin function to set the quorum percentage required for a proposal to pass.
     * @param quorumPercentage The new quorum percentage (0-100).
     */
    function setQuorumPercentage(uint256 quorumPercentage) public onlyOwner {
        require(quorumPercentage <= 100, "Quorum percentage cannot exceed 100");
        uint256 oldQuorum = _quorumPercentage;
        _quorumPercentage = quorumPercentage;
        emit ParametersChanged("quorumPercentage", oldQuorum, quorumPercentage, quorumPercentage, "", address(0));
    }


    // --- Royalty (ERC-2981) Functions ---

    /**
     * @dev Admin function to set the default royalty information for the contract.
     * @param recipient The address receiving the royalties.
     * @param feeNumerator The numerator for the royalty fee (out of 10000).
     */
    function setDefaultRoyalty(address recipient, uint96 feeNumerator) public onlyOwner {
        _royaltyRecipient = payable(recipient);
        _royaltyFeeNumerator = feeNumerator;
        emit ParametersChanged("royaltyRecipient", 0, 0, 0, "", recipient);
        emit ParametersChanged("royaltyFeeNumerator", 0, feeNumerator, feeNumerator, "", address(0));
    }


    // --- Admin / Utility Functions ---

    /**
     * @dev Allows the contract owner to withdraw accumulated Ether.
     */
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Admin function to set the base URI for token metadata.
     * @param baseURI The new base URI string.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        string memory oldBaseURI = _baseTokenURI;
        _baseTokenURI = baseURI;
        emit ParametersChanged("baseTokenURI", 0, 0, 0, baseURI, address(0));
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Simulates initial trait generation.
     * In a real system, this would be more complex, potentially using on-chain
     * entropy, the prompt hash, and maybe an off-chain oracle call result.
     * @param tokenId The ID of the token being minted.
     * @param initialPromptHash The prompt hash provided during minting.
     * @return An array of uint256 representing initial traits.
     */
    function _generateInitialTraits(uint256 tokenId, string memory initialPromptHash) internal pure returns (uint256[] memory) {
        // This is a placeholder. A real generative art contract would use
        // more sophisticated on-chain randomness (if available and safe),
        // hash inputs, or rely on oracle-provided data.
        // Here we just create a simple, deterministic (for testing) trait array.
        uint256 hash = uint256(keccak256(abi.encodePacked(tokenId, initialPromptHash, block.timestamp, msg.sender)));

        // Example: 3 traits represented by uint256
        uint256[] memory traits = new uint256[](3);
        traits[0] = (hash % 100);      // Trait 1: 0-99
        traits[1] = (hash / 100 % 50); // Trait 2: 0-49
        traits[2] = (hash / 5000 % 10); // Trait 3: 0-9

        return traits;
    }

     /**
     * @dev Requires that a token ID has been minted.
     * @param tokenId The ID of the token.
     */
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

     /**
     * @dev Requires that the caller is the owner of a token.
     * @param tokenId The ID of the token.
     */
    function _requireOwned(uint256 tokenId) internal view {
        require(ownerOf(tokenId) == msg.sender, "Caller is not token owner");
    }

}
```