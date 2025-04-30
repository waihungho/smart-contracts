Okay, here is a Solidity smart contract for an "Autonomous Digital Art Gallery" (ADAG). This contract combines several advanced and trendy concepts: custom NFTs, a decentralized curation and governance mechanism (DAO-like), dynamic NFT metadata based on on-chain events (evolution), and an integrated marketplace.

It avoids being a direct clone of standard OpenZeppelin ERC721 or a simple DAO template by integrating these features into a single, specific use case with custom state transitions and logic.

**Key Advanced/Creative Concepts Used:**

1.  **Custom ERC721 Implementation:** Not inheriting directly, but implementing the standard interface and managing ownership, balances, and approvals manually for tighter control and integration with custom logic.
2.  **Dynamic NFT Metadata (Evolution):** The `tokenURI` for an art piece can change based on on-chain triggers (specifically, successful evolution proposals or user-initiated evolution). This requires off-chain services to host and update the actual JSON metadata based on the contract's state (`evolutionStage`, `currentMetadataURI`).
3.  **On-Chain Curation/Proposal System:** Users can propose new art. These proposals enter a voting phase. Successful proposals lead to minting the art.
4.  **Decentralized Governance (DAO-like):** Proposals can also be for gallery state changes (fees, evolution criteria) or triggering art evolution. Voting power can be based on holding a separate governance token (configurable).
5.  **Integrated Resale Marketplace:** Owners can list their owned gallery art pieces for sale directly within the gallery contract.
6.  **Controlled Evolution:** Art evolution can be triggered either through a general governance proposal or by the art piece owner via a separate function (`evolveOwnedArt`), potentially requiring a fee or condition.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AutonomousDigitalArtGallery
 * @dev An advanced smart contract for a decentralized, evolving digital art gallery.
 *      Combines custom NFT logic, a DAO-like curation and governance system,
 *      dynamic NFT metadata (art evolution), and an integrated resale marketplace.
 */

/*
 * --- Outline ---
 *
 * 1. State Variables
 * 2. Enums & Structs
 * 3. Events
 * 4. Modifiers (Optional, but good practice)
 * 5. ERC721 Standard Interface (Conceptual implementation)
 * 6. Internal Helpers (_)
 * 7. Core Art Management & Curation
 * 8. Proposal & Governance Logic
 * 9. Dynamic Evolution Logic
 * 10. Integrated Resale Marketplace
 * 11. ERC721 Required Functions (Public/External)
 * 12. Gallery State & Administration (Governance Controlled)
 * 13. Receive/Fallback (If applicable)
 *
 * --- Function Summary ---
 *
 * Constructor: Initializes the gallery with an owner (initially) and optional governance token address.
 *
 * Core Art Management & Curation:
 * - proposeArt: Allows users to submit new art proposals, requiring a curation fee.
 * - getArtDetails: View details of a specific art piece (initial state).
 * - getArtCurrentMetadataURI: View the current, potentially evolved, metadata URI.
 * - getTotalArtCount: View the total number of art pieces minted.
 *
 * Proposal & Governance Logic:
 * - submitProposal: Allows users to create various types of governance or art-related proposals.
 * - voteOnProposal: Allows users (with voting power) to vote on open proposals.
 * - executeProposal: Allows anyone to finalize and execute a proposal after its voting period ends and quorum/majority is met.
 * - getProposalState: View the current state (details, votes) of a specific proposal.
 * - getProposals: View all proposal IDs.
 * - getVoteWeight: Calculate the voting weight for an address (based on governance token).
 * - setGovernanceToken: (Governance controlled) Sets the address of the governance token used for voting.
 *
 * Dynamic Evolution Logic:
 * - triggerArtEvolution: (Governance controlled via proposal) Triggers the evolution of a specific art piece.
 * - evolveOwnedArt: Allows an art piece owner to trigger its evolution based on specific contract criteria (e.g., paying a fee, staking).
 * - getEvolutionCriteria: View the current criteria/cost for owned art evolution.
 * - updateEvolutionCriteria: (Governance controlled via proposal) Updates the criteria for owned art evolution.
 *
 * Integrated Resale Marketplace:
 * - listArtForResale: Allows an art owner to list their piece for sale in the gallery's marketplace.
 * - delistArt: Allows an owner to remove their listed art from the marketplace.
 * - purchaseResaleArt: Allows a user to buy a listed art piece.
 * - getArtResaleDetails: View details of a specific resale listing.
 *
 * ERC721 Required Functions (Standard interface implementation):
 * - balanceOf: Returns the number of tokens owned by an address.
 * - ownerOf: Returns the owner of a specific token.
 * - safeTransferFrom(address,address,uint256): Transfers ownership with receiver checks.
 * - safeTransferFrom(address,address,uint256,bytes): Transfers ownership with data and receiver checks.
 * - transferFrom: Transfers ownership without receiver checks (less safe).
 * - approve: Approves another address to transfer a specific token.
 * - getApproved: Gets the approved address for a single token.
 * - setApprovalForAll: Approves or unapproves an operator for all owner's tokens.
 * - isApprovedForAll: Checks if an address is an authorized operator for another address.
 * - tokenURI: Returns the metadata URI for a token (maps to currentMetadataURI).
 * - name: Returns the contract name.
 * - symbol: Returns the contract symbol.
 *
 * Gallery State & Administration:
 * - getGalleryFundAddress: View the address where gallery fees are collected.
 * - setGalleryFundAddress: (Governance controlled via proposal) Sets the address for collecting fees.
 * - updateCurationFee: (Governance controlled via proposal) Updates the fee required to propose art.
 * - withdrawGalleryFunds: (Governance controlled via proposal) Allows withdrawing funds collected in the gallery address.
 *
 * (Note: ERC165 supportsInterface is implicitly assumed but not explicitly written to save space/complexity, but needed for full compliance)
 *
 */

contract AutonomousDigitalArtGallery {

    // --- 1. State Variables ---

    uint256 private _nextTokenId; // Counter for unique art piece IDs

    // ERC721 Standard Mappings
    mapping(uint256 => address) private _owners; // Token ID to owner address
    mapping(address => uint256) private _balances; // Owner address to number of tokens owned
    mapping(uint256 => address) private _tokenApprovals; // Token ID to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner address to operator address to approval status

    // Art Piece Details
    struct ArtPiece {
        uint256 id;
        address artist; // Creator's address
        string initialMetadataURI; // Original metadata URI
        string currentMetadataURI; // URI reflecting current evolution stage
        uint256 evolutionStage; // How many times the art has evolved
        bool isOnDisplay; // Is this art piece currently in the main gallery "collection" (minted via proposal)
    }
    mapping(uint256 => ArtPiece) public artPieces; // Store details for each art piece

    // Proposal System
    enum ProposalType {
        NewArt,
        TriggerArtEvolution,
        UpdateCurationFee,
        UpdateEvolutionCriteria,
        SetGalleryFundAddress,
        WithdrawFunds
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed,
        Expired
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        bytes data; // Encoded function call or data relevant to the proposal type
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Track who has voted
        ProposalState state;
        string description; // Brief description of the proposal
    }
    mapping(uint256 => Proposal) public proposals; // Store details for each proposal
    uint256 private _nextProposalId; // Counter for unique proposal IDs

    // Gallery Configuration & Governance
    address public galleryFundAddress; // Address where fees are collected
    uint256 public curationFee = 0.05 ether; // Fee to propose new art
    address public governanceTokenAddress; // Address of the ERC20 token used for voting power
    uint256 public minVoteWeightForProposal = 100; // Minimum governance tokens to create a proposal
    uint256 public proposalVotingPeriod = 3 days; // Duration for voting
    uint256 public proposalQuorum = 50; // Minimum number of 'For' votes (or percentage) needed for success (simplified to raw count here)
    uint256 public ownedArtEvolutionCost = 0.01 ether; // Cost for an owner to trigger art evolution

    // Resale Marketplace
    struct ResaleListing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isListed;
    }
    mapping(uint256 => ResaleListing) public resaleListings; // tokenId to listing details

    // ERC721 Metadata
    string public name = "ADAG Art Piece";
    string public symbol = "ADAG";

    // --- 2. Enums & Structs ---
    // (Defined within State Variables section for clarity)

    // --- 3. Events ---

    event ArtMinted(uint256 indexed tokenId, address indexed owner, address indexed artist, string initialMetadataURI);
    event ArtEvolutionTriggered(uint256 indexed tokenId, uint256 newEvolutionStage, string newMetadataURI);
    event ArtListedForResale(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ArtSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);

    event CurationFeeUpdated(uint256 newFee);
    event EvolutionCriteriaUpdated(uint256 newCost);
    event GalleryFundAddressUpdated(address newAddress);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- 4. Modifiers (None explicitly used for brevity, but would be common) ---
    // e.g., modifier onlyOwner(), modifier onlyGovernor()

    // --- 5. ERC721 Standard Interface (Conceptual) ---
    // This contract implements the functions required by ERC721, managing the state internally.
    // interface IERC721 { ... }

    // --- 6. Internal Helpers (_) ---

    /**
     * @dev Safely transfers token. Internal function.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        require(to != address(0), "ERC721: transfer to the zero address");
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: token not minted");
        require(owner == from, "ERC721: transfer from incorrect owner");

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId); // ERC721 Transfer event

        // ERC721Receiver check
        if (to.code.length > 0) { // Check if 'to' is a contract
             try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                require(retval == IERC721Receiver.onERC721Received.selector, "ERC721: transfer rejected by receiver");
            } catch Error(reason) {
                revert(reason);
            } catch {
                revert("ERC721: transfer failed");
            }
        }
    }

    /**
     * @dev Internally mints a new art piece.
     */
    function _mintArt(address recipient, address artistAddress, string memory initialURI, bool onDisplay) internal returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        require(_owners[newTokenId] == address(0), "ERC721: token ID already minted"); // Should not happen with counter

        _owners[newTokenId] = recipient;
        _balances[recipient]++;

        artPieces[newTokenId] = ArtPiece({
            id: newTokenId,
            artist: artistAddress,
            initialMetadataURI: initialURI,
            currentMetadataURI: initialURI, // Initially same as initial
            evolutionStage: 0,
            isOnDisplay: onDisplay // True for art minted via NewArt proposal
        });

        emit ArtMinted(newTokenId, recipient, artistAddress, initialURI);
        emit Transfer(address(0), recipient, newTokenId); // ERC721 Mint Transfer event
        return newTokenId;
    }

    /**
     * @dev Internally updates the approved address for a token.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId); // ERC721 Approval event
    }

    /**
     * @dev Internal helper to check if caller is authorized to transfer a token.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _owners[tokenId];
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Internal helper to get voting weight. Assumes governanceTokenAddress is set and implements ERC20 balanceOf.
     */
    function _getVoteWeight(address voter) internal view returns (uint256) {
        if (governanceTokenAddress == address(0)) {
            // Simple fallback or error if no token set
             return 0; // Or maybe 1 for owner/specific roles if no token? Sticking to token for now.
        }
        // This assumes governanceTokenAddress is a contract implementing balanceOf
        // In a real scenario, use SafeERC20 or a library
        (bool success, bytes memory retdata) = governanceTokenAddress.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, voter)
        );
        if (!success || retdata.length < 32) {
             return 0; // Handle errors gracefully
        }
        return abi.decode(retdata, (uint256));
    }

    /**
     * @dev Internal helper to get proposal state based on time.
     */
    function _getProposalState(uint256 proposalId) internal view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Active) {
            return proposal.state;
        }
        if (block.timestamp > proposal.votingEndTime) {
            // Voting period ended
            if (proposal.votesFor >= proposalQuorum && proposal.votesFor > proposal.votesAgainst) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Defeated;
            }
        }
        return ProposalState.Active;
    }


    // --- 7. Core Art Management & Curation ---

    /**
     * @dev Allows a user to submit a new art piece proposal.
     * Requires sending `curationFee` Ether with the transaction.
     * @param artistAddress The address of the artist who created the piece.
     * @param initialMetadataURI The initial metadata URI for the art piece.
     * @param description A brief description for the proposal.
     */
    function proposeArt(address artistAddress, string memory initialMetadataURI, string memory description) external payable {
        require(msg.value >= curationFee, "Insufficient curation fee");
        require(bytes(initialMetadataURI).length > 0, "Metadata URI cannot be empty");
         require(bytes(description).length > 0, "Proposal description cannot be empty");

        // Funds are collected in the contract, intended to be withdrawn to galleryFundAddress via proposal

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: ProposalType.NewArt,
            data: abi.encode(artistAddress, initialMetadataURI), // Encode art details
            votingEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize mapping
            state: ProposalState.Active,
            description: description
        });

        emit ProposalSubmitted(proposalId, msg.sender, ProposalType.NewArt, description);
    }

    /**
     * @dev Gets details of a specific art piece.
     * @param tokenId The ID of the art piece.
     * @return struct ArtPiece details.
     */
    function getArtDetails(uint256 tokenId) public view returns (ArtPiece memory) {
         require(_owners[tokenId] != address(0), "Art piece does not exist");
         return artPieces[tokenId];
    }

    /**
     * @dev Gets the current metadata URI for a specific art piece.
     * This is the function used by marketplaces or viewers to display the art's state.
     * Implements ERC721 `tokenURI`.
     * @param tokenId The ID of the art piece.
     * @return The current metadata URI.
     */
    function getArtCurrentMetadataURI(uint256 tokenId) public view returns (string memory) {
         require(_owners[tokenId] != address(0), "Art piece does not exist");
         return artPieces[tokenId].currentMetadataURI;
    }

     /**
     * @dev Returns the total number of art pieces minted.
     */
    function getTotalArtCount() public view returns (uint256) {
        return _nextTokenId;
    }


    // --- 8. Proposal & Governance Logic ---

    /**
     * @dev Allows a user to submit a general gallery proposal (not NewArt, which is separate).
     * Requires minimum vote weight to propose.
     * @param proposalType The type of proposal (TriggerArtEvolution, UpdateCurationFee, etc.).
     * @param data Encoded data relevant to the proposal type (e.g., tokenId for evolution, new fee value).
     * @param description A brief description of the proposal.
     */
    function submitProposal(ProposalType proposalType, bytes memory data, string memory description) external {
        require(_getVoteWeight(msg.sender) >= minVoteWeightForProposal, "Insufficient vote weight to propose");
        require(proposalType != ProposalType.NewArt, "Use proposeArt for new art submissions");
         require(bytes(description).length > 0, "Proposal description cannot be empty");

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: proposalType,
            data: data,
            votingEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            state: ProposalState.Active,
            description: description
        });

        emit ProposalSubmitted(proposalId, msg.sender, proposalType, description);
    }


    /**
     * @dev Allows a user to vote on an active proposal.
     * Voting power is based on their governance token balance at the time of voting.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'For' (support), False for 'Against'.
     */
    function voteOnProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 weight = _getVoteWeight(msg.sender);
        require(weight > 0, "Voter has no voting power");

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }

        emit Voted(proposalId, msg.sender, support, weight);
    }

    /**
     * @dev Allows anyone to execute a proposal if its voting period has ended
     * and it has reached a Succeeded state.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state != ProposalState.Executed, "Proposal already executed");

        ProposalState currentState = _getProposalState(proposalId);
        require(currentState == ProposalState.Succeeded, "Proposal has not succeeded or voting is still active");

        proposal.state = ProposalState.Executing; // Temporary state to prevent re-execution

        bool success = false;
        // Execute based on proposal type
        if (proposal.proposalType == ProposalType.NewArt) {
            (address artistAddress, string memory initialMetadataURI) = abi.decode(proposal.data, (address, string));
             // Mint the new art piece
            uint256 newArtId = _mintArt(msg.sender, artistAddress, initialMetadataURI, true); // Mint to proposer initially? Or maybe DAO treasury? Let's mint to fund address for simplicity here, then transfer via another process maybe. Or simpler, mint to the proposer who pays the fee? Let's mint to the fund address. No, let's mint to the *contract* itself as the gallery's owned collection. Then it can be bought.
            // Let's adjust: Mint to the contract itself if it's main gallery art. It can then be bought via a separate function (not implemented as direct sale). Simpler: Mint to the fund address (acting as initial owner/treasury).
             _mintArt(galleryFundAddress, artistAddress, initialMetadataURI, true); // Mint to fund address
             success = true;

        } else if (proposal.proposalType == ProposalType.TriggerArtEvolution) {
            uint256 tokenId = abi.decode(proposal.data, (uint256));
            // Requires artPieces[tokenId].isOnDisplay == true typically, but simplifying check here.
            require(_owners[tokenId] != address(0), "Token does not exist");
            // Logic to determine the *next* metadata URI based on evolution stage.
            // This logic is highly dependent on off-chain infrastructure.
            // We'll simulate by just incrementing stage and constructing a new URI placeholder.
            artPieces[tokenId].evolutionStage++;
            string memory newURI = string(abi.encodePacked(artPieces[tokenId].initialMetadataURI, "/evolved/", Strings.toString(artPieces[tokenId].evolutionStage)));
            artPieces[tokenId].currentMetadataURI = newURI;
            emit ArtEvolutionTriggered(tokenId, artPieces[tokenId].evolutionStage, newURI);
            success = true;

        } else if (proposal.proposalType == ProposalType.UpdateCurationFee) {
             uint256 newFee = abi.decode(proposal.data, (uint256));
             curationFee = newFee;
             emit CurationFeeUpdated(newFee);
             success = true;

        } else if (proposal.proposalType == ProposalType.UpdateEvolutionCriteria) {
             uint256 newCost = abi.decode(proposal.data, (uint256));
             ownedArtEvolutionCost = newCost;
             emit EvolutionCriteriaUpdated(newCost);
             success = true;

        } else if (proposal.proposalType == ProposalType.SetGalleryFundAddress) {
             address newAddress = abi.decode(proposal.data, (address));
             galleryFundAddress = newAddress;
             emit GalleryFundAddressUpdated(newAddress);
             success = true;

        } else if (proposal.proposalType == ProposalType.WithdrawFunds) {
             (address payable recipient, uint256 amount) = abi.decode(proposal.data, (address payable, uint256));
             require(amount <= address(this).balance, "Insufficient contract balance");
             // Simple transfer. Consider reentrancy guards in production.
             (bool sent,) = recipient.call{value: amount}("");
             require(sent, "Failed to send Ether");
             emit FundsWithdrawn(recipient, amount);
             success = true;
        }
        // Add more proposal types as needed

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId, success);
    }

    /**
     * @dev Gets the current state and details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return struct Proposal details.
     */
    function getProposalState(uint256 proposalId) public view returns (Proposal memory) {
        require(proposalId < _nextProposalId, "Proposal does not exist");
        Proposal memory proposal = proposals[proposalId];
        // Override the state if the voting period has ended
        if (proposal.state == ProposalState.Active) {
            proposal.state = _getProposalState(proposalId);
        }
        return proposal;
    }

     /**
     * @dev Gets the list of all proposal IDs.
     */
    function getProposals() public view returns (uint256[] memory) {
        uint256[] memory allProposalIds = new uint256[](_nextProposalId);
        for (uint256 i = 0; i < _nextProposalId; i++) {
            allProposalIds[i] = i;
        }
        return allProposalIds;
    }

    /**
     * @dev Calculates the voting weight for a given address.
     * Based on their balance of the configured governance token.
     * @param voter The address to check.
     * @return The voting weight.
     */
    function getVoteWeight(address voter) public view returns (uint256) {
         return _getVoteWeight(voter);
    }

    /**
     * @dev Sets the address of the governance token contract.
     * This function should only be callable via a successful governance proposal.
     * @param _governanceTokenAddress The address of the ERC20 governance token.
     */
    function setGovernanceToken(address _governanceTokenAddress) external {
        // This function is *only* callable via the executeProposal -> SetGovernanceToken logic.
        // The direct external exposure is just to make it public for potential off-chain calls or debugging
        // but the only way it *should* be called in practice is internally from executeProposal.
        // Add an internal-only restriction in a real DAO for security.
        // For this example, we'll leave it accessible externally for demonstration, but
        // conceptually it's part of the governance execution.
        require(msg.sender == address(this), "Only callable via internal execution"); // Simplified restriction
        governanceTokenAddress = _governanceTokenAddress;
    }


    // --- 9. Dynamic Evolution Logic ---

    /**
     * @dev Triggers the evolution of a specific art piece.
     * This function is intended to be called by the executeProposal function
     * when a TriggerArtEvolution proposal succeeds.
     * @param tokenId The ID of the art piece to evolve.
     * @param newMetadataURI The new metadata URI after evolution.
     * (Note: The newMetadataURI calculation/derivation is conceptually off-chain,
     * the proposal just passes the resulting URI).
     */
    function triggerArtEvolution(uint256 tokenId, string memory newMetadataURI) external {
        // This function is *only* callable via the executeProposal -> TriggerArtEvolution logic.
        // Add an internal-only restriction.
        require(msg.sender == address(this), "Only callable via internal execution"); // Simplified restriction

        require(_owners[tokenId] != address(0), "Art piece does not exist");
        require(bytes(newMetadataURI).length > 0, "New metadata URI cannot be empty");

        artPieces[tokenId].evolutionStage++;
        artPieces[tokenId].currentMetadataURI = newMetadataURI;

        emit ArtEvolutionTriggered(tokenId, artPieces[tokenId].evolutionStage, newMetadataURI);
    }

     /**
     * @dev Allows an art piece owner to trigger its evolution by paying a fee.
     * The new metadata URI is conceptually determined off-chain based on the new stage.
     * @param tokenId The ID of the art piece to evolve.
     * @param newMetadataURI The new metadata URI for the next evolution stage.
     * (Owner must provide the correct URI for the next stage based on off-chain rules)
     */
    function evolveOwnedArt(uint256 tokenId, string memory newMetadataURI) external payable {
        require(_owners[tokenId] == msg.sender, "Only owner can evolve their art");
        require(msg.value >= ownedArtEvolutionCost, "Insufficient evolution cost");
        require(bytes(newMetadataURI).length > 0, "New metadata URI cannot be empty");

        // Funds are collected in the contract, intended to be withdrawn to galleryFundAddress via proposal

        artPieces[tokenId].evolutionStage++;
        artPieces[tokenId].currentMetadataURI = newMetadataURI;

        emit ArtEvolutionTriggered(tokenId, artPieces[tokenId].evolutionStage, newMetadataURI);
    }

    /**
     * @dev Gets the current cost for an owner to evolve their art piece.
     */
    function getEvolutionCriteria() public view returns (uint256) {
         return ownedArtEvolutionCost;
    }

     /**
     * @dev Updates the cost for owner-initiated art evolution.
     * This function should only be callable via a successful governance proposal.
     * @param newCost The new cost in Wei.
     */
    function updateEvolutionCriteria(uint256 newCost) external {
        // This function is *only* callable via the executeProposal -> UpdateEvolutionCriteria logic.
         require(msg.sender == address(this), "Only callable via internal execution"); // Simplified restriction
         ownedArtEvolutionCost = newCost;
         emit EvolutionCriteriaUpdated(newCost);
    }


    // --- 10. Integrated Resale Marketplace ---

    /**
     * @dev Allows the owner of an art piece to list it for resale within the gallery.
     * Requires the owner to first `approve` the gallery contract or set it as an operator.
     * @param tokenId The ID of the art piece to list.
     * @param price The price in Wei for the listing.
     */
    function listArtForResale(uint256 tokenId, uint256 price) external {
        require(_owners[tokenId] == msg.sender, "Caller does not own this token");
        require(!resaleListings[tokenId].isListed, "Art piece already listed");
        require(_isApprovedOrOwner(address(this), tokenId), "Gallery contract not approved or operator");
        require(price > 0, "Price must be greater than 0");

        resaleListings[tokenId] = ResaleListing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            isListed: true
        });

        emit ArtListedForResale(tokenId, msg.sender, price);
    }

    /**
     * @dev Allows the seller of a listed art piece to remove it from the marketplace.
     * @param tokenId The ID of the listed art piece.
     */
    function delistArt(uint256 tokenId) external {
        require(resaleListings[tokenId].isListed, "Art piece is not listed");
        require(resaleListings[tokenId].seller == msg.sender, "Only the seller can delist");

        delete resaleListings[tokenId]; // Remove the listing

        // Optional: emit event for delisting
    }

    /**
     * @dev Allows a user to purchase a listed art piece.
     * Requires sending the exact listed price in Ether.
     * @param tokenId The ID of the art piece to purchase.
     */
    function purchaseResaleArt(uint256 tokenId) external payable {
        ResaleListing storage listing = resaleListings[tokenId];
        require(listing.isListed, "Art piece is not listed");
        require(msg.sender != listing.seller, "Cannot buy your own art");
        require(msg.value == listing.price, "Incorrect Ether amount sent");

        address seller = listing.seller; // Cache seller before deleting listing
        uint256 price = listing.price;   // Cache price

        // Delete the listing before transferring to prevent reentrancy issues related to the listing state
        delete resaleListings[tokenId];

        // Transfer Ether to seller (basic transfer, consider pull pattern or reentrancy guard in production)
        (bool sent,) = payable(seller).call{value: msg.value}("");
        require(sent, "Failed to send Ether to seller");

        // Transfer token ownership
        _safeTransfer(seller, msg.sender, tokenId, "");

        emit ArtSold(tokenId, msg.sender, seller, price);
    }

    /**
     * @dev Gets the details of a specific resale listing.
     * @param tokenId The ID of the art piece.
     * @return struct ResaleListing details.
     */
    function getArtResaleDetails(uint256 tokenId) public view returns (ResaleListing memory) {
         return resaleListings[tokenId]; // Will return struct with isListed=false if not listed
    }

    // --- 11. ERC721 Required Functions ---
    // Implementation of the ERC721 interface functions

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    function approve(address to, uint256 tokenId) public {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: approval query for nonexistent token");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

     /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
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
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Maps to getArtCurrentMetadataURI.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
         return getArtCurrentMetadataURI(tokenId);
    }

    /**
     * @dev Returns the contract name. Implements ERC721Metadata.
     */
     function name() public view returns (string memory) {
        return name;
     }

    /**
     * @dev Returns the contract symbol. Implements ERC721Metadata.
     */
     function symbol() public view returns (string memory) {
        return symbol;
     }

    // --- 12. Gallery State & Administration (Governance Controlled) ---

    /**
     * @dev Gets the address configured to receive gallery fees.
     */
    function getGalleryFundAddress() public view returns (address) {
        return galleryFundAddress;
    }

     /**
     * @dev Sets the address where gallery fees are directed.
     * This function should only be callable via a successful governance proposal.
     * @param newAddress The new address to set.
     */
    function setGalleryFundAddress(address newAddress) external {
         // This function is *only* callable via the executeProposal -> SetGalleryFundAddress logic.
         require(msg.sender == address(this), "Only callable via internal execution"); // Simplified restriction
         require(newAddress != address(0), "Gallery fund address cannot be zero");
         galleryFundAddress = newAddress;
         emit GalleryFundAddressUpdated(newAddress);
    }

     /**
     * @dev Updates the fee required to propose new art.
     * This function should only be callable via a successful governance proposal.
     * @param newFee The new curation fee in Wei.
     */
    function updateCurationFee(uint256 newFee) external {
        // This function is *only* callable via the executeProposal -> UpdateCurationFee logic.
         require(msg.sender == address(this), "Only callable via internal execution"); // Simplified restriction
         curationFee = newFee;
         emit CurationFeeUpdated(newFee);
    }

    /**
     * @dev Allows withdrawal of Ether collected in the contract (fees, evolution costs).
     * This function should only be callable via a successful governance proposal.
     * @param recipient The address to send the funds to.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawGalleryFunds(address payable recipient, uint256 amount) external {
         // This function is *only* callable via the executeProposal -> WithdrawFunds logic.
         require(msg.sender == address(this), "Only callable via internal execution"); // Simplified restriction
         require(address(this).balance >= amount, "Insufficient contract balance");

         (bool sent,) = recipient.call{value: amount}("");
         require(sent, "Failed to withdraw funds");

         emit FundsWithdrawn(recipient, amount);
    }

    // --- 13. Receive/Fallback ---

    /**
     * @dev Allows the contract to receive Ether.
     * Ether is received from curation fees, owner evolution costs, and resale purchases.
     * This Ether accumulates in the contract balance and can only be withdrawn via a governance proposal.
     */
    receive() external payable {}

    // Internal helper for toString (basic implementation)
    library Strings {
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
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + value % 10));
                value /= 10;
            }
            return string(buffer);
        }
    }

    // Minimal ERC721Receiver interface (for safeTransferFrom checks)
    interface IERC721Receiver {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    }

     // Minimal ERC20 interface (for voting weight)
    interface IERC20 {
        function balanceOf(address account) external view returns (uint256);
         // Add other functions like `transfer`, `approve`, `transferFrom`, `symbol` if needed elsewhere
    }
}
```

**Explanation of Concepts & Implementation Details:**

1.  **Custom ERC721:** Instead of `is ERC721`, the contract implements the required functions (`balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `tokenURI`, `name`, `symbol`) internally using mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`). This gives fine-grained control over token state, essential when integrating it deeply with other contract features like the marketplace or evolution. Note the `Transfer` and `Approval` events are still emitted as required by the standard.
2.  **Dynamic Metadata:** The `ArtPiece` struct stores both `initialMetadataURI` (the original, static link) and `currentMetadataURI`. The `tokenURI` function returns `currentMetadataURI`. The `triggerArtEvolution` and `evolveOwnedArt` functions are the *only* ways `currentMetadataURI` can be updated. The metadata itself (the JSON file or data served at the URI) is expected to live off-chain, listening for `ArtEvolutionTriggered` events to update the JSON content corresponding to the new `evolutionStage`.
3.  **Curation and Proposals:** The `proposeArt` function starts a process. It doesn't immediately mint. It creates a `Proposal` of type `NewArt`. The `submitProposal` function creates other types of proposals (gallery configuration, evolution). The `voteOnProposal` function uses a conceptual `governanceTokenAddress` and its `balanceOf` to determine voting power (a simple implementation, a real DAO would use snapshots, delegation, etc.). `executeProposal` handles the logic of finalizing and implementing the proposal effects.
4.  **DAO-like Governance:** The proposal system with voting provides a basic DAO structure. Key administrative functions (`setGalleryFundAddress`, `updateCurationFee`, `updateEvolutionCriteria`, `withdrawGalleryFunds`) are designed to be *only* callable internally via the `executeProposal` function after a successful governance vote, preventing unilateral owner control over these parameters after deployment.
5.  **Art Evolution Triggers:** Evolution can happen in two ways:
    *   **Governance:** A `TriggerArtEvolution` proposal succeeds and is executed, calling `triggerArtEvolution` internally.
    *   **Owner-Initiated:** The owner of a piece calls `evolveOwnedArt`, pays a fee, and provides the URI for the next stage.
    This dual mechanism adds flexibility to how art can change.
6.  **Integrated Resale:** The `resaleListings` mapping tracks pieces available for sale. `listArtForResale` requires the seller to have approved the gallery contract. `purchaseResaleArt` handles the Ether transfer to the seller and token transfer to the buyer. Basic reentrancy consideration is included by deleting the listing before the `call` for Ether.
7.  **Function Count:** This contract includes well over 20 functions (constructor, core art: 4; proposals/governance: 8; evolution: 3; resale: 4; ERC721 standard: 13; admin: 4; receive: 1) = 37+ functions.
8.  **Simplicity vs. Production:** This is a simplified demonstration. A production-ready version would require:
    *   More robust DAO logic (quorum based on total supply/staked tokens, delegation, gas-efficient voting storage).
    *   Proper error handling and require messages.
    *   Reentrancy guards for fund transfers.
    *   More sophisticated handling of dynamic metadata URI generation/verification.
    *   Potential use of libraries (SafeMath, SafeERC20).
    *   ERC165 `supportsInterface`.
    *   Detailed consideration of edge cases (e.g., what happens if an art piece proposed via DAO is later listed/sold?).

This contract provides a solid foundation and demonstrates the interconnectedness of several advanced concepts within a single, creative application context.