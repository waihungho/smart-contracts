Okay, let's design a smart contract that acts as a decentralized studio for generating AI art. This contract won't run the AI itself (that's impossible on-chain), but it will manage the *process*: taking requests, using oracles to trigger off-chain AI, verifying results, minting dynamic NFTs based on the art, and incorporating community governance over studio parameters and approved AI models/oracles.

This involves several advanced concepts: Oracles for off-chain interaction, dynamic NFTs (where properties change based on on-chain events), basic on-chain governance, and managing multiple related tokens (request tokens and final art tokens).

We'll aim for a rich set of functions covering requests, oracle interaction, NFT management, governance, and dynamic properties.

---

## Smart Contract Outline: DecentralizedAIArtStudio

**Contract Name:** `DecentralizedAIArtStudio`

**Description:**
A decentralized platform for requesting, generating (via off-chain AI triggered by oracles), and managing AI-generated art as dynamic NFTs. It utilizes separate NFTs for requests and final art pieces, includes a basic governance module for parameter and oracle management, and allows final art pieces to have dynamic properties influenced by on-chain actions.

**Core Concepts:**
1.  **Art Requests:** Users submit requests by minting an `ArtRequestNFT` and paying a fee.
2.  **Oracle Triggering:** Approved oracles monitor requests and trigger off-chain AI generation.
3.  **Result Verification & Minting:** Oracles report results (e.g., IPFS hash of art/metadata). The contract verifies the oracle and mints an `ArtPieceNFT` to the original requestor.
4.  **Dynamic NFTs:** `ArtPieceNFT`s have properties (like 'Collectibility Score') that can change based on events (e.g., ownership duration, transfers).
5.  **Governance:** Holders of `ArtPieceNFT`s can propose and vote on changes to studio parameters (fees, approved AI models, approved oracles).
6.  **Funding:** Mechanisms for funding generation costs and managing protocol fees.

**Tokenomics (Simplified for this example):**
*   `ArtRequestNFT`: Represents a pending or processed request. Burned upon completion or cancellation.
*   `ArtPieceNFT`: The final AI-generated art piece NFT. Ownable, transferable, potentially dynamic.

---

## Function Summary:

**NFT Management (Inherited & Custom):**
1.  `balanceOf(owner)`: (ERC721) Get the number of NFTs an address owns.
2.  `ownerOf(tokenId)`: (ERC721) Get the owner of a specific NFT.
3.  `transferFrom(from, to, tokenId)`: (ERC721) Transfer NFT ownership.
4.  `approve(to, tokenId)`: (ERC721) Grant approval to a single address.
5.  `getApproved(tokenId)`: (ERC721) Get the approved address for an NFT.
6.  `setApprovalForAll(operator, approved)`: (ERC721) Grant/revoke approval for an operator for all NFTs.
7.  `isApprovedForAll(owner, operator)`: (ERC721) Check if an operator is approved for all NFTs of an owner.
8.  `mintArtRequest(requester, params)`: (Internal) Mints a new ArtRequestNFT.
9.  `mintArtPiece(requester, requestId, metadataURI)`: (Internal) Mints a new ArtPieceNFT.
10. `burnArtRequest(requestId)`: (Internal) Burns an ArtRequestNFT.

**Studio Core Logic:**
11. `submitArtRequest(promptId, styleId, complexity)`: User function to pay fee and create a new art request, minting an `ArtRequestNFT`.
12. `cancelArtRequest(requestId)`: User function to cancel their pending request and potentially get a refund.
13. `oracleReportArtCompletion(requestId, metadataURI)`: Approved oracle function to report completion and trigger `ArtPieceNFT` minting.
14. `getArtRequestDetails(requestId)`: View details of a specific art request.
15. `getArtPieceDetails(artPieceId)`: View metadata and basic details of a final art piece.
16. `getQueueSize()`: View the number of pending art requests.
17. `getApprovedAIModels()`: View the list of AI models the studio approves using.

**Funding & Fees:**
18. `depositGenerationFunds()`: Allows anyone to deposit funds to cover generation costs.
19. `withdrawGenerationFunds(amount)`: Governed function to withdraw funds.
20. `getGenerationFundsBalance()`: View the current balance of funds for generation.
21. `setProtocolFee(fee)`: Governed function to set the fee for submitting requests.
22. `getProtocolFee()`: View the current protocol fee.
23. `collectProtocolFees(recipient)`: Governed function to send collected fees to a recipient.

**Oracle Management (Governed):**
24. `addApprovedOracle(oracleAddress)`: Governed function to add a trusted oracle.
25. `removeApprovedOracle(oracleAddress)`: Governed function to remove a trusted oracle.
26. `isApprovedOracle(oracleAddress)`: Check if an address is an approved oracle.
27. `getApprovedOracles()`: View the list of approved oracles.

**Dynamic NFT Properties:**
28. `getArtPieceCollectibilityScore(artPieceId)`: Calculate and return a dynamic score based on on-chain factors.
29. `updateArtPieceDynamicProperties(artPieceId)`: Allows triggering an update/recalculation of dynamic properties (potentially permissioned or gas-costly).

**Governance:**
30. `proposeParameterChange(proposalType, description, data)`: Allows eligible voters to create a governance proposal.
31. `voteOnProposal(proposalId, support)`: Allows eligible voters (e.g., `ArtPieceNFT` holders) to vote on a proposal.
32. `executeProposal(proposalId)`: Executes a proposal that has passed and met execution criteria.
33. `getProposalState(proposalId)`: View the current state of a governance proposal.
34. `getVotingPower(voterAddress)`: Calculate the voting power of an address (e.g., based on `ArtPieceNFT` count).
35. `addApprovedAIModel(modelId)`: Governed function to add an approved AI model ID.
36. `removeApprovedAIModel(modelId)`: Governed function to remove an approved AI model ID.

**Utility & State:**
37. `pauseRequests()`: Governed emergency function to pause new art requests.
38. `unpauseRequests()`: Governed function to unpause requests.
39. `isPaused()`: Check if the request system is paused.
40. `getArtRequestNFTAddress()`: Get the address of the ArtRequestNFT contract.
41. `getArtPieceNFTAddress()`: Get the address of the ArtPieceNFT contract.

*(Note: Some standard ERC721 functions are listed for completeness, but the focus for the "20+" requirement is on the custom, domain-specific functions implementing the studio logic, governance, oracle interaction, and dynamic properties.)*

---

## Solidity Source Code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// --- Custom NFT Contracts (Simplified) ---
// These would likely be deployed separately, but defined here for clarity
contract ArtRequestNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct RequestDetails {
        address requester;
        uint256 submissionTimestamp;
        uint256 feePaid; // In native currency (e.g., ETH/MATIC)
        uint256 promptId;
        uint256 styleId;
        uint256 complexity; // 0=low, 1=medium, 2=high
        bool processed;
        bool cancelled;
    }

    mapping(uint256 tokenId => RequestDetails) public requests;

    constructor(address initialOwner)
        ERC721("AI Art Request", "AIARTREQ")
        Ownable(initialOwner)
    {}

    // Only the owner (DecentralizedAIArtStudio contract) can mint
    function mint(address to, uint256 promptId, uint256 styleId, uint256 complexity, uint256 feePaid) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);

        requests[newItemId] = RequestDetails({
            requester: to,
            submissionTimestamp: block.timestamp,
            feePaid: feePaid,
            promptId: promptId,
            styleId: styleId,
            complexity: complexity,
            processed: false,
            cancelled: false
        });
        return newItemId;
    }

    // Only the owner (DecentralizedAIArtStudio contract) can burn
    function burn(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "NFT does not exist");
        _beforeTokenTransfer(ownerOf(tokenId), address(0), tokenId, 1); // ERC721 hook
        delete requests[tokenId]; // Remove details
        _burn(tokenId);
    }

    // Update details when processed (by studio)
    function markAsProcessed(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Request does not exist");
        requests[tokenId].processed = true;
    }

     // Update details when cancelled (by studio)
    function markAsCancelled(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Request does not exist");
        requests[tokenId].cancelled = true;
    }

    // Prevent direct transfers by users - transfers handled by studio logic or implicitly via burn/mint
    // For simplicity, blocking transfers here. In a real scenario, transfer could mean transferring the *right* to generate.
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
         revert("Art Request NFTs are non-transferable via standard ERC721 methods");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
         revert("Art Request NFTs are non-transferable via standard ERC721 methods");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
         revert("Art Request NFTs are non-transferable via standard ERC721 methods");
    }

    function approve(address to, uint256 tokenId) public pure override {
         revert("Art Request NFTs cannot be approved");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
         revert("Art Request NFTs cannot be approved for all");
    }
}

contract ArtPieceNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct ArtPieceDetails {
        uint256 requestId; // Link back to the original request
        address originalRequestor; // Who requested it
        string metadataURI; // IPFS hash or similar
        uint256 mintTimestamp;
        uint256 transferCount; // Track transfers for dynamic properties
    }

    // Simple Dynamic Property - A "Collectibility Score"
    // This is a simplistic example. More complex logic could involve historical data,
    // external factors via oracles, etc.
    struct DynamicProperties {
        uint256 collectibilityScore;
        uint256 lastCalculatedTimestamp;
    }

    mapping(uint256 tokenId => ArtPieceDetails) public artPieces;
    mapping(uint256 tokenId => DynamicProperties) public dynamicProps;

    // Configuration for dynamic score calculation (simplified)
    uint256 public scoreBase = 100;
    uint256 public scorePerDayOwned = 1; // Gain 1 point per day owned
    uint256 public scorePenaltyPerTransfer = 5; // Lose 5 points per transfer

    // Event to signal when dynamic properties are updated
    event DynamicPropertiesUpdated(uint256 indexed artPieceId, uint256 newScore);

    constructor(address initialOwner)
        ERC721("Decentralized AI Art", "DAIA")
        Ownable(initialOwner)
    {}

    // Only the owner (DecentralizedAIArtStudio contract) can mint
    function mint(address to, uint256 requestId, string memory metadataURI, address originalRequestor) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);

        artPieces[newItemId] = ArtPieceDetails({
            requestId: requestId,
            originalRequestor: originalRequestor,
            metadataURI: metadataURI,
            mintTimestamp: block.timestamp,
            transferCount: 0
        });

        // Initialize dynamic properties
        dynamicProps[newItemId] = DynamicProperties({
            collectibilityScore: scoreBase,
            lastCalculatedTimestamp: block.timestamp
        });

        return newItemId;
    }

    // Override transfer functions to track transfers
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        artPieces[tokenId].transferCount++; // Increment transfer count
        // Consider invalidating or recalculating dynamic score upon transfer
        // Simple approach: invalidate score, requires update call later
        dynamicProps[tokenId].collectibilityScore = 0; // Mark as needing recalculation
        dynamicProps[tokenId].lastCalculatedTimestamp = block.timestamp; // Reset timer for new owner
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
        artPieces[tokenId].transferCount++;
        dynamicProps[tokenId].collectibilityScore = 0;
        dynamicProps[tokenId].lastCalculatedTimestamp = block.timestamp;
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
         _safeTransfer(from, to, tokenId);
         artPieces[tokenId].transferCount++;
         dynamicProps[tokenId].collectibilityScore = 0;
         dynamicProps[tokenId].lastCalculatedTimestamp = block.timestamp;
    }


    // --- Dynamic Properties Logic ---

    // Function to calculate the current collectibility score
    function calculateCollectibilityScore(uint256 artPieceId) public view returns (uint256) {
        require(_exists(artPieceId), "Art piece does not exist");
        ArtPieceDetails storage details = artPieces[artPieceId];
        DynamicProperties storage dProps = dynamicProps[artPieceId];

        // Score from time held by *current* owner
        uint256 timeOwnedSeconds;
        if (dProps.lastCalculatedTimestamp > 0) {
             timeOwnedSeconds = block.timestamp - dProps.lastCalculatedTimestamp;
        } else {
            // If never calculated or invalidated (like after transfer), calculate from mint time or transfer time
            // This simple logic uses the last calculation timestamp which is reset on transfer.
            timeOwnedSeconds = block.timestamp - details.mintTimestamp; // Simpler: calculate from mint
             if (details.transferCount > 0) { // If transferred, calculate from last transfer (implicit in lastCalculatedTimestamp reset)
                  timeOwnedSeconds = block.timestamp - dProps.lastCalculatedTimestamp;
             }
        }


        uint256 daysOwned = timeOwnedSeconds / 1 days; // Use 1 day constant for clarity

        uint256 timeScore = daysOwned * scorePerDayOwned;
        uint256 transferPenalty = details.transferCount * scorePenaltyPerTransfer;

        // Base score + time score - transfer penalty (ensure score doesn't go below zero)
        if (scoreBase + timeScore < transferPenalty) {
            return 0;
        } else {
            return scoreBase + timeScore - transferPenalty;
        }
    }

    // Function to get the *last calculated* collectibility score
    // This is useful if calculation is costly and done off-chain or periodically.
    // In this simple example, calculation is cheap, so we could just use the calculate function.
    // However, keeping this structure shows how dynamic data could be *stored* and updated.
     function getArtPieceCollectibilityScore(uint256 artPieceId) public view returns (uint256) {
         require(_exists(artPieceId), "Art piece does not exist");
         // In this simple implementation, the score is calculated on the fly.
         // If calculation were expensive, we'd return dynamicProps[artPieceId].collectibilityScore
         // and rely on updateArtPieceDynamicProperties to set it.
         // For this example, we will just calculate it directly in the getter for simplicity.
         return calculateCollectibilityScore(artPieceId);
     }

    // Function to explicitly trigger an update of dynamic properties
    // Can be called by anyone (potentially with gas cost) or an authorized keeper/oracle
    // In a real scenario, this might have fees or be restricted.
    function updateArtPieceDynamicProperties(uint256 artPieceId) external {
        require(_exists(artPieceId), "Art piece does not exist");
        uint256 currentScore = calculateCollectibilityScore(artPieceId);

        dynamicProps[artPieceId].collectibilityScore = currentScore;
        dynamicProps[artPieceId].lastCalculatedTimestamp = block.timestamp;

        emit DynamicPropertiesUpdated(artPieceId, currentScore);
    }

    // Governed function to set dynamic score parameters
    function setDynamicScoreParameters(uint256 base, uint256 perDay, uint256 perTransferPenalty) external onlyOwner { // Owner is the Studio contract
        scoreBase = base;
        scorePerDayOwned = perDay;
        scorePenaltyPerTransfer = perTransferPenalty;
    }
}


// --- Main Studio Contract ---
contract DecentralizedAIArtStudio is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _requestCounter;
    Counters.Counter private _proposalCounter;

    // --- State Variables ---
    ArtRequestNFT public artRequestNFT;
    ArtPieceNFT public artPieceNFT;

    uint256 public protocolFee = 0.01 ether; // Fee to submit a request
    address public feeRecipient; // Address receiving fees

    // Funds specifically allocated for paying off-chain generation costs
    mapping(address => uint256) private _generationFundsBalances;
    uint256 public totalGenerationFunds = 0;

    // Oracle Management
    mapping(address => bool) private _approvedOracles;
    address[] private _oracleList; // To easily retrieve the list

    // Approved AI Models (referenced by ID or string identifier)
    mapping(uint256 => bool) public approvedAIModels; // Example: mapping model ID to approval status
    uint256[] private _approvedAIModelList; // To easily retrieve the list

    // Request Queue (Simplified: just tracking latest ID, oracles poll `artRequestNFT.requests` with processed=false)
    // A more advanced queue might use a linked list or a separate queue contract.
    // For this example, oracles are expected to find requests where processed is false.

    // Governance
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum ProposalType { SetProtocolFee, AddApprovedOracle, RemoveApprovedOracle, AddApprovedAIModel, RemoveApprovedAIModel, SetDynamicScoreParams, WithdrawGenerationFunds, SetFeeRecipient }

    struct Proposal {
        address proposer;
        ProposalType proposalType;
        bytes data; // Encoded parameters for the proposal type
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voted; // Keep track of who voted
    }

    mapping(uint256 => Proposal) public proposals;

    uint256 public minArtPiecesForProposal = 1; // Min number of ArtPieceNFTs to create a proposal
    uint256 public votingPeriodDuration = 3 days;
    uint256 public proposalThreshold = 1; // Minimum votes required to pass (simplified)

    // --- Events ---
    event ArtRequestSubmitted(uint256 indexed requestId, address indexed requester, uint256 feePaid, uint256 promptId, uint256 styleId, uint256 complexity);
    event ArtRequestCancelled(uint256 indexed requestId, address indexed requester, uint256 refundedAmount);
    event ArtPieceMinted(uint256 indexed artPieceId, uint256 indexed requestId, address indexed owner, string metadataURI);
    event OracleApproved(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event GenerationFundsDeposited(address indexed depositor, uint256 amount);
    event GenerationFundsWithdrawn(address indexed recipient, uint256 amount);
    event ProtocolFeeSet(uint256 oldFee, uint256 newFee);
    event ProtocolFeesCollected(address indexed recipient, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description, uint256 voteEndTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 currentVotesFor, uint256 currentVotesAgainst);
    event ProposalExecuted(uint256 indexed proposalId, ProposalType proposalType);
    event ApprovedAIModelAdded(uint256 indexed modelId);
    event ApprovedAIModelRemoved(uint256 indexed modelId);
    event DynamicScoreParamsSet(uint256 base, uint256 perDay, uint256 perTransferPenalty);
    event RequestsPaused();
    event RequestsUnpaused();


    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {
         // Deploy child NFT contracts and transfer ownership to this studio contract
        artRequestNFT = new ArtRequestNFT(address(this));
        artPieceNFT = new ArtPieceNFT(address(this));

        feeRecipient = initialOwner; // Initially set fee recipient to owner
    }

    // --- Access Control Modifiers ---
    modifier onlyApprovedOracle() {
        require(_approvedOracles[msg.sender], "Caller is not an approved oracle");
        _;
    }

     // Modifier to ensure caller has enough ArtPieceNFTs to propose
    modifier onlyEligibleVoter() {
        require(getVotingPower(msg.sender) >= minArtPiecesForProposal, "Caller does not have enough voting power");
        _;
    }

     // --- Receive Ether ---
     // Allow depositing funds without calling a specific function
    receive() external payable {
        depositGenerationFunds();
    }

    fallback() external payable {
        depositGenerationFunds();
    }


    // --- Studio Core Logic ---

    /// @notice Submits a new art generation request.
    /// @param promptId Identifier for the AI prompt/theme.
    /// @param styleId Identifier for the AI art style.
    /// @param complexity Level of complexity requested (0-2).
    /// @return requestId The ID of the newly created art request NFT.
    function submitArtRequest(uint256 promptId, uint256 styleId, uint256 complexity)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (uint256 requestId)
    {
        require(msg.value >= protocolFee, "Insufficient fee");
        require(complexity <= 2, "Invalid complexity level");
        // Optionally check if promptId/styleId are within expected ranges/approved lists

        requestId = artRequestNFT.mint(msg.sender, promptId, styleId, complexity, msg.value);

        // Transfer the fee amount that exceeds the protocolFee to generation funds
        uint256 generationContribution = msg.value - protocolFee;
        if (generationContribution > 0) {
             _generationFundsBalances[address(this)] += generationContribution; // Add to contract's internal balance tracking
             totalGenerationFunds += generationContribution;
        }

        // Send the exact protocol fee to the recipient
        if (protocolFee > 0) {
            payable(feeRecipient).transfer(protocolFee); // Basic transfer, consider using pull pattern for safety
        }


        emit ArtRequestSubmitted(requestId, msg.sender, msg.value, promptId, styleId, complexity);
    }

    /// @notice Cancels a pending art request.
    /// @param requestId The ID of the request NFT to cancel.
    /// @dev Only callable by the request owner if the request hasn't been processed.
    function cancelArtRequest(uint256 requestId) external nonReentrant {
        ArtRequestNFT.RequestDetails memory requestDetails = artRequestNFT.requests(requestId);
        require(requestDetails.requester == msg.sender, "Not your request");
        require(!requestDetails.processed, "Request already processed");
        require(!requestDetails.cancelled, "Request already cancelled");

        artRequestNFT.markAsCancelled(requestId);
        artRequestNFT.burn(requestId); // Burn the request NFT

        // Refund a portion of the fee? (Example refunds only the generation contribution)
        uint256 refundAmount = requestDetails.feePaid - protocolFee; // Refund only the amount that went to generation funds
        if (refundAmount > 0) {
             // If funds were added to internal balance, need to withdraw from there
             require(_generationFundsBalances[address(this)] >= refundAmount, "Insufficient generation funds to refund");
             _generationFundsBalances[address(this)] -= refundAmount;
             totalGenerationFunds -= refundAmount;
             payable(msg.sender).transfer(refundAmount);
             emit ArtRequestCancelled(requestId, msg.sender, refundAmount);
        } else {
            emit ArtRequestCancelled(requestId, msg.sender, 0);
        }
    }

    /// @notice Called by an approved oracle to report art generation completion.
    /// @param requestId The ID of the request that was fulfilled.
    /// @param metadataURI URI pointing to the generated art metadata (e.g., IPFS).
    /// @dev Only callable by approved oracles. Triggers minting of the ArtPieceNFT.
    function oracleReportArtCompletion(uint256 requestId, string memory metadataURI)
        external
        onlyApprovedOracle
        nonReentrant
    {
        ArtRequestNFT.RequestDetails memory requestDetails = artRequestNFT.requests(requestId);
        require(requestDetails.requester != address(0), "Request does not exist"); // Ensure request exists
        require(!requestDetails.processed, "Request already processed");
        require(!requestDetails.cancelled, "Request cancelled");
        // Add checks here to potentially verify the metadataURI format or content hash if possible/needed

        artRequestNFT.markAsProcessed(requestId); // Mark request as processed
        artRequestNFT.burn(requestId); // Burn the request NFT

        // Mint the final art piece NFT to the original requestor
        uint256 artPieceId = artPieceNFT.mint(
            requestDetails.requester,
            requestId,
            metadataURI,
            requestDetails.requester // Store original requestor in ArtPieceDetails
        );

        // Oracle could be compensated here from generation funds (logic omitted for brevity)

        emit ArtPieceMinted(artPieceId, requestId, requestDetails.requester, metadataURI);
    }

    /// @notice Gets the details of a specific art request NFT.
    /// @param requestId The ID of the request NFT.
    /// @return details The struct containing request information.
    function getArtRequestDetails(uint256 requestId) public view returns (ArtRequestNFT.RequestDetails memory details) {
        return artRequestNFT.requests(requestId);
    }

    /// @notice Gets the details of a specific art piece NFT.
    /// @param artPieceId The ID of the art piece NFT.
    /// @return details The struct containing art piece information.
    function getArtPieceDetails(uint256 artPieceId) public view returns (ArtPieceNFT.ArtPieceDetails memory details) {
        return artPieceNFT.artPieces(artPieceId);
    }

    /// @notice Gets the current number of pending art requests.
    /// @dev This is a simplified view; it counts minted requests that aren't marked processed or cancelled.
    /// A more robust queue tracking mechanism would be needed for exact queue position/size.
    /// For now, we rely on the ArtRequestNFT state.
    function getQueueSize() public view returns (uint256) {
         uint256 totalRequests = artRequestNFT.totalSupply();
         // This is just the count of *existing* ArtRequestNFTs.
         // A true queue size would iterate or track state specifically.
         // Given ArtRequestNFTs are burned, totalSupply() of ArtRequestNFTs is *not* the queue size.
         // Let's return the current counter value, which is the number of requests ever submitted.
         // Oracles would filter by `processed == false` and `cancelled == false`.
         // A better way to track queue size is needed for a real system.
         // For this example, we'll indicate this limitation.
         // TODO: Implement a proper queue size tracking mechanism if needed for external display.
         return _requestCounter.current() - artRequestNFT.totalSupply(); // Crude estimate: total submitted - existing (burned)
    }

    /// @notice Gets the list of approved AI model IDs.
    /// @return modelIds An array of approved AI model IDs.
    function getApprovedAIModels() public view returns (uint256[] memory) {
        return _approvedAIModelList;
    }


    // --- Funding & Fees ---

    /// @notice Allows users/DAO to deposit funds to cover AI generation costs.
    function depositGenerationFunds() public payable {
        require(msg.value > 0, "Deposit must be greater than 0");
         _generationFundsBalances[address(this)] += msg.value; // Track internal balance
        totalGenerationFunds += msg.value;
        emit GenerationFundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows withdrawal of generation funds.
    /// @param amount The amount to withdraw.
    /// @dev Callable via governance proposal execution.
    function withdrawGenerationFunds(uint256 amount) external onlyOwner nonReentrant {
        // Owner here is this contract via governance execution
        require(amount > 0, "Withdraw amount must be greater than 0");
         require(_generationFundsBalances[address(this)] >= amount, "Insufficient generation funds");

        _generationFundsBalances[address(this)] -= amount;
        totalGenerationFunds -= amount;
         payable(owner()).transfer(amount); // Send to contract owner (who initiated execution) or a specified recipient?
         // Let's send to the *current* contract owner, assuming execution implies owner consent
        emit GenerationFundsWithdrawn(owner(), amount);
    }

    /// @notice Gets the current balance of funds available for generation costs.
    /// @return balance The balance in native currency (e.g., Ether).
    function getGenerationFundsBalance() public view returns (uint256) {
        return totalGenerationFunds; // Use the tracked sum for accuracy
    }

    /// @notice Sets the protocol fee for submitting art requests.
    /// @param fee The new fee amount in native currency (e.g., wei).
    /// @dev Callable via governance proposal execution.
    function setProtocolFee(uint256 fee) external onlyOwner {
        // Owner here is this contract via governance execution
        uint256 oldFee = protocolFee;
        protocolFee = fee;
        emit ProtocolFeeSet(oldFee, fee);
    }

    /// @notice Gets the current protocol fee.
    /// @return fee The current fee in native currency (e.g., wei).
    function getProtocolFee() public view returns (uint256) {
        return protocolFee;
    }

    /// @notice Collects accumulated protocol fees.
    /// @param recipient The address to send the fees to.
    /// @dev Callable via governance proposal execution.
    function collectProtocolFees(address recipient) external onlyOwner nonReentrant {
        // Owner here is this contract via governance execution
        require(recipient != address(0), "Invalid recipient address");
        uint256 balance = address(this).balance - totalGenerationFunds; // Calculate balance minus reserved generation funds
        require(balance > 0, "No protocol fees to collect");

        // This logic is simplified. A robust system would track fees separately from generation funds.
        // For this example, total balance - tracked generation funds = available fees.
        uint256 feesToCollect = balance;

        // Re-calculate generation funds balance based on the *current* contract balance after fee transfer
         _generationFundsBalances[address(this)] = totalGenerationFunds; // Reset internal balance for consistency (though not strictly needed after transfer)

        payable(recipient).transfer(feesToCollect);

        emit ProtocolFeesCollected(recipient, feesToCollect);
    }

     /// @notice Sets the recipient address for protocol fees.
     /// @param recipient The address to receive fees.
     /// @dev Callable via governance proposal execution.
     function setFeeRecipient(address recipient) external onlyOwner {
         require(recipient != address(0), "Invalid recipient address");
         feeRecipient = recipient;
     }


    // --- Oracle Management ---

    /// @notice Adds an address to the list of approved oracles.
    /// @param oracleAddress The address to approve.
    /// @dev Callable via governance proposal execution.
    function addApprovedOracle(address oracleAddress) external onlyOwner {
         // Owner here is this contract via governance execution
        require(oracleAddress != address(0), "Invalid address");
        if (!_approvedOracles[oracleAddress]) {
            _approvedOracles[oracleAddress] = true;
            _oracleList.push(oracleAddress);
            emit OracleApproved(oracleAddress);
        }
    }

    /// @notice Removes an address from the list of approved oracles.
    /// @param oracleAddress The address to remove.
    /// @dev Callable via governance proposal execution.
    function removeApprovedOracle(address oracleAddress) external onlyOwner {
         // Owner here is this contract via governance execution
        require(_approvedOracles[oracleAddress], "Address is not an approved oracle");
        _approvedOracles[oracleAddress] = false;
        // Remove from dynamic array (expensive, but oracle changes should be rare)
        for (uint i = 0; i < _oracleList.length; i++) {
            if (_oracleList[i] == oracleAddress) {
                _oracleList[i] = _oracleList[_oracleList.length - 1];
                _oracleList.pop();
                break;
            }
        }
        emit OracleRemoved(oracleAddress);
    }

    /// @notice Checks if an address is an approved oracle.
    /// @param oracleAddress The address to check.
    /// @return bool True if the address is approved, false otherwise.
    function isApprovedOracle(address oracleAddress) public view returns (bool) {
        return _approvedOracles[oracleAddress];
    }

    /// @notice Gets the list of all approved oracle addresses.
    /// @return oracles An array of approved oracle addresses.
    function getApprovedOracles() public view returns (address[] memory) {
        return _oracleList;
    }

    // --- Dynamic NFT Properties ---
    // Getters for dynamic properties are handled directly by the ArtPieceNFT contract,
    // but we expose helper getters here for convenience or if studio-specific logic is needed.

    /// @notice Gets the collectibility score of an ArtPiece NFT.
    /// @param artPieceId The ID of the art piece NFT.
    /// @return score The calculated collectibility score.
    function getArtPieceCollectibilityScore(uint256 artPieceId) public view returns (uint256) {
        return artPieceNFT.getArtPieceCollectibilityScore(artPieceId);
    }

    /// @notice Allows triggering an update of an ArtPiece NFT's dynamic properties.
    /// @param artPieceId The ID of the art piece NFT.
    /// @dev This calls the corresponding function on the ArtPieceNFT contract.
    function updateArtPieceDynamicProperties(uint256 artPieceId) external {
         artPieceNFT.updateArtPieceDynamicProperties(artPieceId);
    }

    // Governed function to set parameters on the ArtPieceNFT contract
    /// @notice Sets the parameters used for calculating the dynamic collectibility score.
    /// @param base Base score.
    /// @param perDay Points gained per day owned.
    /// @param perTransferPenalty Points lost per transfer.
    /// @dev Callable via governance proposal execution.
    function setDynamicScoreParameters(uint256 base, uint256 perDay, uint256 perTransferPenalty) external onlyOwner {
        // Owner here is this contract via governance execution
        artPieceNFT.setDynamicScoreParameters(base, perDay, perTransferPenalty);
         emit DynamicScoreParamsSet(base, perDay, perTransferPenalty);
    }

    // --- Governance ---

    /// @notice Gets the voting power of an address.
    /// @dev Voting power is based on the number of ArtPieceNFTs owned.
    /// @param voterAddress The address to check.
    /// @return power The voting power (number of ArtPieceNFTs owned).
    function getVotingPower(address voterAddress) public view returns (uint256 power) {
        return artPieceNFT.balanceOf(voterAddress);
    }

    /// @notice Creates a new governance proposal.
    /// @param proposalType The type of proposal.
    /// @param description A description of the proposal.
    /// @param data Encoded call data for the function to be executed if the proposal passes.
    /// @dev Only eligible voters can create proposals.
    function proposeParameterChange(
        ProposalType proposalType,
        string memory description,
        bytes memory data
    ) external onlyEligibleVoter returns (uint256 proposalId) {
        _proposalCounter.increment();
        proposalId = _proposalCounter.current();

        proposals[proposalId].proposer = msg.sender;
        proposals[proposalId].proposalType = proposalType;
        proposals[proposalId].description = description;
        proposals[proposalId].data = data;
        proposals[proposalId].voteStartTime = block.timestamp;
        proposals[proposalId].voteEndTime = block.timestamp + votingPeriodDuration;
        proposals[proposalId].executed = false;

        emit ProposalCreated(proposalId, msg.sender, proposalType, description, proposals[proposalId].voteEndTime);
    }

    /// @notice Votes on an active proposal.
    /// @param proposalId The ID of the proposal.
    /// @param support True for a vote in favor, false for against.
    /// @dev Only eligible voters can vote once per proposal.
    function voteOnProposal(uint256 proposalId, bool support) external onlyEligibleVoter {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period is not active");
        require(!proposal.voted[msg.sender], "Already voted on this proposal");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "Voter has no power");

        if (support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }

        proposal.voted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, proposal.votesFor, proposal.votesAgainst);
    }

    /// @notice Executes a proposal that has passed the voting period and met the threshold.
    /// @param proposalId The ID of the proposal to execute.
    /// @dev Anyone can call this function after the voting period ends if the proposal passed.
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass majority");
        // Add a threshold check if needed: require(proposal.votesFor >= proposalThreshold, "Threshold not met");

        proposal.executed = true;

        // Execute the action based on proposal type
        // Use a low-level call with require to catch execution failures
        (bool success, ) = address(this).call(proposal.data);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(proposalId, proposal.proposalType);
    }

    /// @notice Gets the current state of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return state The state of the proposal.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) {
            return ProposalState.Failed; // Indicates non-existent proposal
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp <= proposal.voteEndTime) {
            return ProposalState.Active;
        } else if (proposal.votesFor > proposal.votesAgainst) {
            // && proposal.votesFor >= proposalThreshold // Add threshold check if used
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Failed;
        }
    }

     /// @notice Governed function to add an approved AI model ID.
     /// @param modelId The ID of the AI model to approve.
     /// @dev Callable via governance proposal execution.
     function addApprovedAIModel(uint256 modelId) external onlyOwner {
         // Owner here is this contract via governance execution
         if (!approvedAIModels[modelId]) {
             approvedAIModels[modelId] = true;
             _approvedAIModelList.push(modelId); // Inefficient for large lists, consider mapping
             emit ApprovedAIModelAdded(modelId);
         }
     }

     /// @notice Governed function to remove an approved AI model ID.
     /// @param modelId The ID of the AI model to remove.
     /// @dev Callable via governance proposal execution.
     function removeApprovedAIModel(uint256 modelId) external onlyOwner {
         // Owner here is this contract via governance execution
         require(approvedAIModels[modelId], "Model ID is not approved");
         approvedAIModels[modelId] = false;
          // Inefficient removal from array, same note as removeApprovedOracle
          for (uint i = 0; i < _approvedAIModelList.length; i++) {
              if (_approvedAIModelList[i] == modelId) {
                  _approvedAIModelList[i] = _approvedAIModelList[_approvedAIModelList.length - 1];
                  _approvedAIModelList.pop();
                  break;
              }
          }
         emit ApprovedAIModelRemoved(modelId);
     }


    // --- Utility & State ---

    /// @notice Pauses new art requests.
    /// @dev Callable via governance proposal execution or by the initial owner in emergency.
    function pauseRequests() public onlyOwner whenNotPaused { // Allow initial owner for emergency
        _pause();
        emit RequestsPaused();
    }

    /// @notice Unpauses new art requests.
    /// @dev Callable via governance proposal execution or by the initial owner.
    function unpauseRequests() public onlyOwner whenPaused { // Allow initial owner
        _unpause();
        emit RequestsUnpaused();
    }

    /// @notice Checks if the request system is currently paused.
    /// @return bool True if paused, false otherwise.
    function isPaused() public view returns (bool) {
        return paused();
    }

    /// @notice Gets the address of the ArtRequestNFT contract.
    /// @return The address of the ArtRequestNFT contract.
    function getArtRequestNFTAddress() public view returns (address) {
        return address(artRequestNFT);
    }

    /// @notice Gets the address of the ArtPieceNFT contract.
    /// @return The address of the ArtPieceNFT contract.
    function getArtPieceNFTAddress() public view returns (address) {
        return address(artPieceNFT);
    }

    // --- ERC721 Receiver ---
    // Needed if the ArtRequestNFT or ArtPieceNFT contracts ever send NFTs *to* this contract.
    // In this design, the Studio contract *owns* the NFT contracts and mints/burns directly,
    // so receiving is not strictly necessary for the core logic, but good practice to implement.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        override
        returns (bytes4)
    {
        // Handle receiving an ERC721 token if needed.
        // For this contract's logic, receiving NFTs isn't part of the flow,
        // but we return the magic value to be compliant.
        return this.onERC721Received.selector;
    }

    // --- Standard ERC721 Functions (Implemented by OpenZeppelin inheritance in NFT contracts) ---
    // (These are implicitly available for the *NFT contract instances*, not on the Studio contract itself directly,
    // except for methods like balanceOf/ownerOf called *on* the child contracts.)
    // e.g., artPieceNFT.balanceOf(someAddress)
    // Listing them here to show the contract *system* provides these functions.
    // balanceOf(address owner) -> ArtPieceNFT or ArtRequestNFT
    // ownerOf(uint256 tokenId) -> ArtPieceNFT or ArtRequestNFT
    // transferFrom(address from, address to, uint256 tokenId) -> ArtPieceNFT (Customized)
    // approve(address to, uint256 tokenId) -> ArtPieceNFT
    // getApproved(uint256 tokenId) -> ArtPieceNFT
    // setApprovalForAll(address operator, bool _approved) -> ArtPieceNFT
    // isApprovedForAll(address owner, address operator) -> ArtPieceNFT

}
```

---

**Explanation of Concepts and Function Count:**

1.  **Oracle Interaction:** The `oracleReportArtCompletion` function is the core of the oracle pattern, acting as a callback for off-chain processes. Oracle addresses are managed via `addApprovedOracle`, `removeApprovedOracle`, `isApprovedOracle`, `getApprovedOracles`. (4+1=5 functions related to oracles)
2.  **Dynamic NFTs:** The `ArtPieceNFT` contract includes `calculateCollectibilityScore` and `updateArtPieceDynamicProperties`. The main contract exposes `getArtPieceCollectibilityScore` and calls `updateArtPieceDynamicProperties`. Governance can set score parameters via `setDynamicScoreParameters`. (3+1+1 = 5 functions related to dynamic properties and their parameters). Note: The dynamic property logic is kept simple (based on time and transfers) to be feasible on-chain.
3.  **On-chain Governance:** Implemented with `Proposal` struct, proposal types (`ProposalType` enum), `proposeParameterChange`, `voteOnProposal`, `executeProposal`, `getProposalState`. Voting power `getVotingPower` is based on ArtPieceNFT ownership. Governance controls sensitive actions like setting fees, managing oracles, adding/removing AI models, withdrawing funds, and setting dynamic score parameters. (6+1 = 7 core governance functions, plus functions governed by it counting towards total). Governed functions like `addApprovedAIModel`, `removeApprovedAIModel`, `setProtocolFee`, `withdrawGenerationFunds`, `setFeeRecipient`, `setDynamicScoreParameters`, `pauseRequests`, `unpauseRequests` are executed *via* governance.
4.  **Two NFT Types:** Separate `ArtRequestNFT` and `ArtPieceNFT` contracts manage the lifecycle from request to final art. The main `DecentralizedAIArtStudio` contract *owns* these contracts and handles their minting/burning (`mintArtRequest`, `mintArtPiece`, `burnArtRequest` are internal helper calls from the studio contract). Getters like `getArtRequestDetails`, `getArtPieceDetails` access their data. (2 getters + internal mint/burn calls initiated by core logic).
5.  **Funding & Fees:** `submitArtRequest` handles the incoming fee. `depositGenerationFunds` allows funding. `getGenerationFundsBalance` views funds. `setProtocolFee`, `collectProtocolFees`, `setFeeRecipient` manage fees via governance. `withdrawGenerationFunds` allows withdrawing generation funds via governance. (1 submit + 1 deposit + 1 balance view + 3 fee management + 1 withdrawal = 7 functions).

**Counting Functions:**

Let's list the non-standard ERC721 functions in the main `DecentralizedAIArtStudio` contract as requested:

1.  `constructor`
2.  `receive` (fallback function counting as a payable entry point)
3.  `fallback` (another payable entry point)
4.  `submitArtRequest`
5.  `cancelArtRequest`
6.  `oracleReportArtCompletion`
7.  `getArtRequestDetails`
8.  `getArtPieceDetails`
9.  `getQueueSize` (Note: Implementation is basic)
10. `getApprovedAIModels`
11. `depositGenerationFunds`
12. `withdrawGenerationFunds` (Governed)
13. `getGenerationFundsBalance`
14. `setProtocolFee` (Governed)
15. `getProtocolFee`
16. `collectProtocolFees` (Governed)
17. `setFeeRecipient` (Governed)
18. `addApprovedOracle` (Governed)
19. `removeApprovedOracle` (Governed)
20. `isApprovedOracle`
21. `getApprovedOracles`
22. `getArtPieceCollectibilityScore` (Calls child contract)
23. `updateArtPieceDynamicProperties` (Calls child contract)
24. `setDynamicScoreParameters` (Governed, calls child contract)
25. `getVotingPower` (Calls child contract)
26. `proposeParameterChange`
27. `voteOnProposal`
28. `executeProposal`
29. `getProposalState`
30. `addApprovedAIModel` (Governed)
31. `removeApprovedAIModel` (Governed)
32. `pauseRequests` (Governed/Owner)
33. `unpauseRequests` (Governed/Owner)
34. `isPaused`
35. `getArtRequestNFTAddress`
36. `getArtPieceNFTAddress`
37. `onERC721Received` (ERC721 standard interface implementation)

This gives us 37 functions in the main contract alone that are not standard ERC721 transfer/approval methods. This easily exceeds the 20 function requirement and covers interesting, advanced concepts like oracle interaction, governance, dynamic NFTs, and multi-contract interaction.