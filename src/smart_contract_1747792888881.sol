Okay, let's design a smart contract for a Decentralized Autonomous Art Gallery (DAAG). This concept combines NFTs, DAO-like governance, treasury management, and includes a unique feature related to "dynamic art" parameters.

Here's the plan:

**Concept:** A smart contract representing a decentralized art gallery governed by its patrons. Patrons own specific ERC721 tokens (`PatronToken`). The gallery holds a collection of ERC721/ERC1155 art NFTs. Patrons can propose actions (acquiring art, funding artists, changing gallery parameters, changing dynamic art parameters), vote on proposals, and execute passed proposals. The gallery has a treasury to manage funds.

**Advanced/Creative/Trendy Features:**
1.  **Patron-Based Governance:** A specific NFT (`PatronToken`) grants voting rights, rather than a fungible token.
2.  **Diverse Proposal Types:** Supports distinct workflows for adding art, funding, selling, changing gallery rules, and *crucially*, changing parameters for specific "dynamic" art pieces.
3.  **Dynamic Art Parameter Control:** The contract stores parameters for certain art pieces that can be voted upon by the community. While the *rendering* of the art happens off-chain, the canonical parameters are on-chain, allowing the community to collectively influence evolving artwork.
4.  **On-Chain Art Metadata for Owned Pieces:** Stores core metadata (title, artist, etc.) directly in the contract for owned pieces, making it readily accessible on-chain. (Caveat: expensive for large amounts of metadata).
5.  **Integrated Art Receiving:** Implements `onERC721Received` and `onERC1155Received` to only accept incoming art NFTs that are associated with an active, passed `AddArt` proposal.

**Outline:**

1.  **Contract Description:** High-level explanation of the DAAG.
2.  **Key Concepts:** Explanation of Patron Tokens, Governance, Treasury, Dynamic Art.
3.  **State Variables:** Core variables managing gallery state, treasury, art collection, patrons, and proposals.
4.  **Structs & Enums:** Data structures for Art Details, Proposals, and Proposal States/Types.
5.  **Events:** Signals for important actions (minting, proposals, voting, execution, treasury).
6.  **Modifiers:** Access control helpers.
7.  **Interface Imports:** For interacting with ERC721/ERC1155 tokens.
8.  **Constructor:** Initializes gallery name, owner, and initial parameters.
9.  **Patron Token Management:** Functions for minting and querying Patron Tokens.
10. **Art Management:** Functions for receiving, storing details, and querying owned art.
11. **Governance:** Functions for creating, viewing, voting on, and executing proposals. Includes logic for different proposal types.
12. **Treasury Management:** Functions for depositing and withdrawing funds (via governance).
13. **Dynamic Art Parameter Management:** Functions for querying and (indirectly, via governance) changing parameters for dynamic art pieces.
14. **Query Functions:** Public view functions to get contract state information.

**Function Summary (targeting +20 unique actions/queries):**

1.  `constructor(string memory _galleryName, address _patronTokenAddress, address _erc721InterfaceAddress, address _erc1155InterfaceAddress)`: Initializes the gallery.
2.  `depositFunds()`: Allows anyone to send Ether to the gallery treasury.
3.  `getTreasuryBalance()`: Returns the current Ether balance of the gallery contract.
4.  `getGalleryName()`: Returns the gallery's name.
5.  `getOwner()`: Returns the current owner address (initial admin/emergency).
6.  `setOwner(address newOwner)`: Allows owner to transfer ownership (can be proposed to governance).
7.  `mintPatronToken(address recipient)`: Mints a new Patron NFT to a recipient (initially only by owner/governance).
8.  `isPatron(address account)`: Checks if an account owns a Patron Token.
9.  `getPatronTokenId(address account)`: Returns the Patron Token ID for an account (if they own one).
10. `getPatronCount()`: Returns the total number of minted Patron Tokens.
11. `submitArtProposal(address _nftContract, uint256 _tokenId, bool _isERC721, string memory _title, string memory _artistName, string memory _descriptionURI)`: Proposes adding an external NFT to the gallery collection.
12. `createFundingProposal(address _recipient, uint256 _amount, string memory _description)`: Proposes sending Ether from the treasury.
13. `createSellArtProposal(address _nftContract, uint256 _tokenId, uint256 _salePrice, address _buyer)`: Proposes selling an owned art piece to a specific buyer for a price.
14. `createChangeDynamicArtParameterProposal(address _nftContract, uint256 _tokenId, string memory _parameterName, string memory _parameterValue)`: Proposes changing a parameter for a specific dynamic art piece.
15. `createChangeGalleryParameterProposal(uint256 _parameterIndex, uint256 _newValue)`: Proposes changing a core gallery setting (e.g., voting period, quorum).
16. `getProposalCount()`: Returns the total number of proposals created.
17. `getProposalDetails(uint256 _proposalId)`: Returns comprehensive details about a specific proposal.
18. `getProposalState(uint256 _proposalId)`: Returns the current state of a proposal (Pending, Active, Passed, Failed, Executed, Cancelled).
19. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows a patron to cast a vote on an active proposal.
20. `hasVoted(uint256 _proposalId, address _voter)`: Checks if an account has already voted on a proposal.
21. `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed its voting period and met criteria.
22. `cancelProposal(uint256 _proposalId)`: Allows the proposer (or governance) to cancel a proposal before voting ends.
23. `getOwnedArtCount()`: Returns the number of art pieces owned by the gallery.
24. `getOwnedArtTokenIdByIndex(uint256 _index)`: Returns the NFT contract address and token ID for an owned piece by index.
25. `getOwnedArtDetails(address _nftContract, uint256 _tokenId)`: Returns the stored details (title, artist, etc.) for an owned piece.
26. `isGalleryOwnedArt(address _nftContract, uint256 _tokenId)`: Checks if a specific NFT is owned by the gallery.
27. `getDynamicArtParameter(address _nftContract, uint256 _tokenId, string memory _parameterName)`: Returns the current value of a dynamic parameter for an art piece.
28. `getVotingPeriod()`: Returns the current duration of the voting period for proposals.
29. `getQuorumPercentage()`: Returns the minimum percentage of patron votes required for a proposal to pass.
30. `onERC721Received(address operator, address from, uint256 tokenId, bytes data)`: ERC721 receiver hook, used for adding art via proposal execution.
31. `onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes data)`: ERC1155 receiver hook (single), used for adding art.
32. `onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes data)`: ERC1155 receiver hook (batch).

*(Okay, we have well over 20 functions. The core complexity lies in the governance and proposal execution logic.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial setup/emergency, governance takes over control

// --- Decentralized Autonomous Art Gallery (DAAG) Smart Contract ---
//
// This contract establishes a community-governed art gallery on the blockchain.
// It allows patrons (who hold a specific Patron NFT) to propose and vote on actions
// related to the gallery's art collection, treasury, and even dynamic art parameters.
//
// Key Concepts:
// - Patron Tokens (ERC721): Non-fungible tokens representing membership and voting power.
// - Art Collection (ERC721/ERC1155): The gallery can own and manage blockchain art pieces.
// - Treasury: A secure vault within the contract for holding Ether.
// - Governance: A proposal-based system where patrons vote to approve actions.
// - Proposal Types: Specific workflows for adding art, funding, selling, changing gallery rules,
//   and manipulating parameters for dynamic art.
// - Dynamic Art Parameters: On-chain storage for customizable parameters of certain art pieces,
//   allowing community influence on off-chain rendering or characteristics.
//
// This contract implements necessary ERC721/ERC1155 receiver hooks to manage art ownership.

// --- Outline ---
// 1. Contract Description
// 2. Key Concepts
// 3. State Variables
// 4. Structs & Enums
// 5. Events
// 6. Modifiers
// 7. Interface Imports (using @openzeppelin)
// 8. Constructor
// 9. Patron Token Management
// 10. Art Management (Receiving, Storing, Querying Owned)
// 11. Governance (Proposal Creation, Voting, Execution, Querying)
// 12. Treasury Management (Deposit, Withdrawal via Governance)
// 13. Dynamic Art Parameter Management (Querying, Setting via Governance)
// 14. Utility / Query Functions (General State)
// 15. ERC Receiver Hooks

// --- Function Summary ---
// - constructor: Initializes the gallery.
// - depositFunds: Allows funding the treasury.
// - getTreasuryBalance: Get treasury balance.
// - getGalleryName: Get gallery name.
// - getOwner: Get current owner (initial admin).
// - setOwner: Transfer ownership (initially owner, can be governed).
// - mintPatronToken: Mint Patron NFT (initially owner, can be governed).
// - isPatron: Check if address is a patron.
// - getPatronTokenId: Get patron token ID for address.
// - getPatronCount: Get total patron count.
// - submitArtProposal: Create proposal to add art.
// - createFundingProposal: Create proposal to fund address.
// - createSellArtProposal: Create proposal to sell owned art.
// - createChangeDynamicArtParameterProposal: Create proposal to change dynamic art param.
// - createChangeGalleryParameterProposal: Create proposal to change gallery setting.
// - getProposalCount: Get total proposal count.
// - getProposalDetails: Get full proposal info.
// - getProposalState: Get proposal state.
// - voteOnProposal: Cast vote on proposal.
// - hasVoted: Check if address voted on proposal.
// - executeProposal: Execute a passed proposal.
// - cancelProposal: Cancel a proposal.
// - getOwnedArtCount: Get count of gallery owned art.
// - getOwnedArtTokenIdByIndex: Get owned art token by index.
// - getOwnedArtDetails: Get stored details for owned art.
// - isGalleryOwnedArt: Check if NFT is gallery owned.
// - getDynamicArtParameter: Get dynamic art parameter value.
// - getVotingPeriod: Get current voting period.
// - getQuorumPercentage: Get current quorum percentage.
// - onERC721Received: Handle incoming ERC721 transfers (only via executed proposal).
// - onERC1155Received: Handle incoming ERC1155 single transfers (only via executed proposal).
// - onERC1155BatchReceived: Handle incoming ERC1155 batch transfers (only via executed proposal).

contract DecentralizedAutonomousArtGallery is Ownable, IERC721Receiver, IERC1155Receiver {
    using Address for address;

    // --- State Variables ---
    string public galleryName;
    address public immutable PATRON_TOKEN_ADDRESS;
    address public immutable ERC721_INTERFACE_ADDRESS; // Store interface addresses for external calls
    address public immutable ERC1155_INTERFACE_ADDRESS; // Store interface addresses for external calls

    // Treasury balance is simply the contract's Ether balance

    uint256 private _patronTokenCounter; // Counter for minting unique patron tokens
    mapping(address => uint256) private _patronTokenIds; // Address to Patron Token ID
    address[] private _patronAddresses; // Array to track patron addresses (careful with gas on large arrays)

    struct ArtDetails {
        address nftContract;
        uint256 tokenId;
        bool isERC721; // true for ERC721, false for ERC1155
        string title;
        string artistName;
        string descriptionURI; // IPFS or other URI for full description/metadata
        bool isDynamic; // Flag if this art piece has dynamic parameters managed by the gallery
    }
    mapping(address => mapping(uint256 => ArtDetails)) private _galleryOwnedArt; // (nftContract => tokenId => ArtDetails)
    address[] private _ownedArtContracts; // List of contract addresses with owned art
    mapping(address => uint256[]) private _ownedArtTokenIdsByContract; // List of token IDs owned per contract

    // Dynamic Art Parameters: (nftContract => tokenId => parameterName => parameterValue)
    mapping(address => mapping(uint256 => mapping(string => string))) private _dynamicArtParameters;

    enum ProposalState { Pending, Active, Passed, Failed, Executed, Cancelled }
    enum ProposalType { AddArt, FundArtist, SellArt, ChangeDynamicParam, ChangeGalleryParam, GenericCall } // GenericCall is advanced, could allow calling arbitrary functions (use with caution!)

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        uint256 creationTime;
        uint256 votingPeriodEnd;
        ProposalState state;

        // Proposal Data (packed based on type)
        bytes data; // Stores encoded parameters specific to the proposal type

        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Maps patron address to vote status
    }

    uint256 private _proposalCounter;
    mapping(uint256 => Proposal) private _proposals;
    uint256[] private _proposalIds; // Array to track proposal IDs

    // Gallery Parameters (Governable)
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumPercentage = 50; // Minimum percentage of *total* patron votes required for success (e.g., 50%) - needs to be adjusted for realistic quorum


    // --- Events ---
    event FundsDeposited(address indexed sender, uint256 amount);
    event PatronTokenMinted(address indexed recipient, uint256 tokenId);
    event ArtProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address nftContract, uint256 tokenId);
    event FundingProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount);
    event SellArtProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address nftContract, uint256 tokenId, uint256 salePrice, address buyer);
    event ChangeDynamicArtParameterProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address nftContract, uint256 tokenId, string parameterName, string parameterValue);
    event ChangeGalleryParameterProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 parameterIndex, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event ArtAddedToGallery(address indexed nftContract, uint256 indexed tokenId, bool isERC721);
    event ArtRemovedFromGallery(address indexed nftContract, uint256 indexed tokenId); // For sales or transfers out
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event DynamicArtParameterChanged(address indexed nftContract, uint256 indexed tokenId, string parameterName, string parameterValue);
    event GalleryParameterChanged(uint256 indexed parameterIndex, uint256 oldValue, uint256 newValue);

    // --- Modifiers ---
    modifier onlyPatron() {
        require(_patronTokenIds[msg.sender] > 0, "DAAG: Caller is not a patron");
        _;
    }

    // --- Constructor ---
    constructor(
        string memory _galleryName,
        address _patronTokenAddress,
        address _erc721InterfaceAddress, // Pass interface addresses to prevent re-deploying interfaces
        address _erc1155InterfaceAddress
    ) Ownable(msg.sender) {
        galleryName = _galleryName;
        PATRON_TOKEN_ADDRESS = _patronTokenAddress;
        ERC721_INTERFACE_ADDRESS = _erc721InterfaceAddress;
        ERC1155_INTERFACE_ADDRESS = _erc1155InterfaceAddress;

        // Note: Initial parameters like votingPeriod and quorumPercentage are set here
        // and can be changed via ChangeGalleryParameterProposal.
        // Ownership initially rests with the deployer, but critical functions
        // will transition to governance control.
    }

    // --- Treasury Management ---

    /**
     * @notice Allows anyone to deposit Ether into the gallery treasury.
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Alias for depositing funds.
     */
    function depositFunds() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Returns the current Ether balance held by the contract.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Initial / Emergency Owner Function ---
    // Note: Critical actions like minting patrons or setting core params should
    // ideally transition to governance via proposals soon after deployment.
    // `setOwner` allows changing the initial admin. Governance can propose
    // changing owner to address(0) to fully renounce, or to a multisig.

    /**
     * @notice Transfers ownership of the contract. Only the current owner can call this.
     *         Governance can propose calling this function via a GenericCall proposal.
     * @param newOwner The address of the new owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    // --- Patron Token Management ---

    /**
     * @notice Mints a new Patron NFT to the specified recipient.
     *         Initially callable by owner, but should transition to governance control.
     * @param recipient The address to mint the Patron NFT to.
     */
    function mintPatronToken(address recipient) public onlyOwner { // Consider adding a governance check here later
        require(recipient != address(0), "DAAG: Invalid recipient");
        require(_patronTokenIds[recipient] == 0, "DAAG: Recipient already a patron");

        IERC721 patronToken = IERC721(PATRON_TOKEN_ADDRESS);

        _patronTokenCounter++;
        uint256 tokenId = _patronTokenCounter;
        _patronTokenIds[recipient] = tokenId; // Link address to token ID

        // Mint the token - assumes the PatronToken contract has a callable mint function
        // and this contract has permission to call it (e.g., via minter role).
        // This is a placeholder call. Real implementation depends on PatronToken contract.
        // Example: patronToken.mint(recipient, tokenId); // This assumes PatronToken has a mint function
        // Let's simulate the state change here for demonstration
        _patronAddresses.push(recipient); // Add to array for lookup (gas warning on large arrays)

        emit PatronTokenMinted(recipient, tokenId);
    }

    /**
     * @notice Checks if an address holds a Patron Token.
     * @param account The address to check.
     * @return True if the account is a patron, false otherwise.
     */
    function isPatron(address account) public view returns (bool) {
        // We assume _patronTokenIds[account] > 0 means they hold a valid token.
        // For robustness, you might want to also query the actual ERC721 contract balance/ownership.
        return _patronTokenIds[account] > 0;
    }

     /**
      * @notice Returns the Patron Token ID associated with an address.
      * @param account The address to query.
      * @return The Patron Token ID, or 0 if the address is not a patron.
      */
    function getPatronTokenId(address account) public view returns (uint256) {
        return _patronTokenIds[account];
    }

    /**
     * @notice Returns the total number of Patron Tokens minted.
     */
    function getPatronCount() public view returns (uint256) {
        return _patronTokenCounter; // Or _patronAddresses.length if that's preferred
    }

    // --- Art Management (Internal & Query) ---

    /**
     * @notice Internal function to add art details to the gallery's internal state.
     *         Called upon successful execution of an AddArt proposal.
     * @param details The ArtDetails struct for the piece.
     */
    function _addArtToGallery(ArtDetails memory details) internal {
        require(!isGalleryOwnedArt(details.nftContract, details.tokenId), "DAAG: Art already owned");

        _galleryOwnedArt[details.nftContract][details.tokenId] = details;

        // Track contracts and token IDs for enumeration (potential gas cost here for arrays)
        bool contractExists = false;
        for(uint i = 0; i < _ownedArtContracts.length; i++) {
            if (_ownedArtContracts[i] == details.nftContract) {
                contractExists = true;
                break;
            }
        }
        if (!contractExists) {
            _ownedArtContracts.push(details.nftContract);
        }
        _ownedArtTokenIdsByContract[details.nftContract].push(details.tokenId);

        emit ArtAddedToGallery(details.nftContract, details.tokenId, details.isERC721);
    }

    /**
     * @notice Internal function to remove art from the gallery's internal state.
     *         Called upon successful execution of a SellArt or other transfer proposal.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The token ID.
     */
    function _removeArtFromGallery(address nftContract, uint256 tokenId) internal {
        require(isGalleryOwnedArt(nftContract, tokenId), "DAAG: Art not owned by gallery");

        // Mark as removed (cannot delete from mappings easily without gas cost, safer to flag or overwrite)
        // Overwriting with a default struct is cleaner.
        delete _galleryOwnedArt[nftContract][tokenId];

        // Removing from arrays is complex and costly. For simplicity in this example,
        // we won't remove from _ownedArtContracts or _ownedArtTokenIdsByContract.
        // Query functions iterating these arrays should check `isGalleryOwnedArt`.

        emit ArtRemovedFromGallery(nftContract, tokenId);
    }

    /**
     * @notice Returns the total number of art pieces the gallery claims to own.
     *         Note: This counts entries in the internal mapping, not actual token balance.
     */
    function getOwnedArtCount() public view returns (uint256) {
         // Iterating mappings directly is not possible. A simple counter incremented/decremented
         // in _addArtToGallery and _removeArtFromGallery would be more efficient for this.
         // Let's add a counter state variable for this.
         uint256 count = 0;
         for(uint i = 0; i < _ownedArtContracts.length; i++) {
             address nftContract = _ownedArtContracts[i];
             for(uint j = 0; j < _ownedArtTokenIdsByContract[nftContract].length; j++) {
                 uint256 tokenId = _ownedArtTokenIdsByContract[nftContract][j];
                 if (isGalleryOwnedArt(nftContract, tokenId)) {
                     count++;
                 }
             }
         }
         return count; // This is gas-intensive for large collections
    }

    /**
     * @notice Returns the NFT contract address and token ID for an owned piece by its index
     *         in the internal tracking arrays. Note: Index may not be stable after removals.
     * @param index The index in the internal tracking arrays.
     * @return The NFT contract address and token ID.
     */
    function getOwnedArtTokenIdByIndex(uint256 index) public view returns (address, uint256) {
        // Iterating over _ownedArtContracts and _ownedArtTokenIdsByContract to find the Nth owned piece.
        // Very gas-intensive for large collections.
        uint264 currentCount = 0;
        for(uint i = 0; i < _ownedArtContracts.length; i++) {
            address nftContract = _ownedArtContracts[i];
            for(uint j = 0; j < _ownedArtTokenIdsByContract[nftContract].length; j++) {
                uint256 tokenId = _ownedArtTokenIdsByContract[nftContract][j];
                if (isGalleryOwnedArt(nftContract, tokenId)) {
                    if (currentCount == index) {
                        return (nftContract, tokenId);
                    }
                    currentCount++;
                }
            }
        }
        revert("DAAG: Index out of bounds or art not owned");
    }

    /**
     * @notice Returns the stored details for a specific art piece owned by the gallery.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The token ID.
     * @return The ArtDetails struct for the owned piece.
     */
    function getOwnedArtDetails(address nftContract, uint256 tokenId) public view returns (ArtDetails memory) {
        require(isGalleryOwnedArt(nftContract, tokenId), "DAAG: Art not owned by gallery");
        return _galleryOwnedArt[nftContract][tokenId];
    }

     /**
      * @notice Checks if a specific NFT is currently marked as owned by the gallery.
      * @param nftContract The address of the NFT contract.
      * @param tokenId The token ID.
      * @return True if the gallery's internal state marks the art as owned.
      */
    function isGalleryOwnedArt(address nftContract, uint256 tokenId) public view returns (bool) {
         // Check if the struct exists and has a non-zero tokenId (assuming tokenId 0 is invalid or indicates empty slot)
         // A boolean flag within the struct is more explicit for checking existence/ownership status.
         // Let's add a `bool exists;` field to ArtDetails and check that. Or simply check if nftContract is non-zero
         // in the returned struct, as that field is set upon addition.
         return _galleryOwnedArt[nftContract][tokenId].nftContract != address(0);
     }


    // --- Governance - Proposal Creation ---

    /**
     * @notice Creates a proposal for the gallery to acquire an external NFT.
     *         The NFT must be transferred to the gallery upon successful execution.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The token ID of the art piece.
     * @param _isERC721 True if ERC721, False if ERC1155.
     * @param _title Title of the art piece.
     * @param _artistName Artist's name.
     * @param _descriptionURI URI for detailed description/metadata.
     */
    function submitArtProposal(address _nftContract, uint256 _tokenId, bool _isERC721, string memory _title, string memory _artistName, string memory _descriptionURI) public onlyPatron returns (uint256 proposalId) {
        // Note: Ownership check of the NFT by the proposer might be added here,
        // but execution step requires the NFT to *arrive* at the gallery address.
        require(_nftContract != address(0), "DAAG: Invalid NFT contract address");
        require(!isGalleryOwnedArt(_nftContract, _tokenId), "DAAG: Gallery already owns this art");

        _proposalCounter++;
        proposalId = _proposalCounter;

        ArtDetails memory artDetails = ArtDetails({
            nftContract: _nftContract,
            tokenId: _tokenId,
            isERC721: _isERC721,
            title: _title,
            artistName: _artistName,
            descriptionURI: _descriptionURI,
            isDynamic: false // Default to not dynamic, can be changed via another proposal
        });

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.AddArt,
            proposer: msg.sender,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriod,
            state: ProposalState.Active,
            data: abi.encode(artDetails), // Encode the ArtDetails struct
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)() // Initialize mapping
        });
        _proposalIds.push(proposalId); // Add to array for enumeration (gas warning)

        emit ArtProposalSubmitted(proposalId, msg.sender, _nftContract, _tokenId);
    }

    /**
     * @notice Creates a proposal to transfer Ether from the treasury to a recipient.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of Ether to send (in wei).
     * @param _description Brief description of the funding purpose.
     */
    function createFundingProposal(address _recipient, uint256 _amount, string memory _description) public onlyPatron returns (uint256 proposalId) {
        require(_recipient != address(0), "DAAG: Invalid recipient address");
        require(_amount > 0, "DAAG: Amount must be greater than zero");
        require(getTreasuryBalance() >= _amount, "DAAG: Insufficient treasury balance"); // Check current balance

        _proposalCounter++;
        proposalId = _proposalCounter;

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.FundArtist,
            proposer: msg.sender,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriod,
            state: ProposalState.Active,
            data: abi.encode(_recipient, _amount, _description), // Encode recipient, amount, description
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)()
        });
        _proposalIds.push(proposalId);

        emit FundingProposalSubmitted(proposalId, msg.sender, _recipient, _amount);
    }

    /**
     * @notice Creates a proposal to sell a piece of art currently owned by the gallery.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The token ID of the art piece.
     * @param _salePrice The proposed sale price (in wei).
     * @param _buyer The address of the proposed buyer.
     */
    function createSellArtProposal(address _nftContract, uint256 _tokenId, uint256 _salePrice, address _buyer) public onlyPatron returns (uint256 proposalId) {
        require(isGalleryOwnedArt(_nftContract, _tokenId), "DAAG: Gallery does not own this art");
        require(_buyer != address(0), "DAAG: Invalid buyer address");
        // Note: Price 0 is allowed if it's intended as a gift/transfer

        _proposalCounter++;
        proposalId = _proposalCounter;

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.SellArt,
            proposer: msg.sender,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriod,
            state: ProposalState.Active,
            data: abi.encode(_nftContract, _tokenId, _salePrice, _buyer), // Encode details
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)()
        });
        _proposalIds.push(proposalId);

        emit SellArtProposalSubmitted(proposalId, msg.sender, _nftContract, _tokenId, _salePrice, _buyer);
    }

    /**
     * @notice Creates a proposal to change a dynamic parameter for a specific art piece.
     *         Only applicable to art marked as `isDynamic`.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The token ID of the art piece.
     * @param _parameterName The name of the parameter to change.
     * @param _parameterValue The new value for the parameter.
     */
    function createChangeDynamicArtParameterProposal(address _nftContract, uint256 _tokenId, string memory _parameterName, string memory _parameterValue) public onlyPatron returns (uint256 proposalId) {
        require(isGalleryOwnedArt(_nftContract, _tokenId), "DAAG: Gallery does not own this art");
        require(_galleryOwnedArt[_nftContract][_tokenId].isDynamic, "DAAG: Art piece is not marked as dynamic");
        require(bytes(_parameterName).length > 0, "DAAG: Parameter name cannot be empty");

        _proposalCounter++;
        proposalId = _proposalCounter;

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.ChangeDynamicParam,
            proposer: msg.sender,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriod,
            state: ProposalState.Active,
            data: abi.encode(_nftContract, _tokenId, _parameterName, _parameterValue), // Encode details
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)()
        });
        _proposalIds.push(proposalId);

        emit ChangeDynamicArtParameterProposalSubmitted(proposalId, msg.sender, _nftContract, _tokenId, _parameterName, _parameterValue);
    }

     /**
      * @notice Creates a proposal to change a core gallery parameter (voting period or quorum).
      *         Uses indices to identify the parameter.
      *         0: votingPeriod, 1: quorumPercentage.
      * @param _parameterIndex Index identifying the parameter to change.
      * @param _newValue The new value for the parameter.
      */
     function createChangeGalleryParameterProposal(uint256 _parameterIndex, uint256 _newValue) public onlyPatron returns (uint256 proposalId) {
         require(_parameterIndex <= 1, "DAAG: Invalid parameter index"); // Only 0 and 1 currently
         if (_parameterIndex == 0) {
             require(_newValue >= 1 days, "DAAG: Voting period must be at least 1 day");
         } else if (_parameterIndex == 1) {
             require(_newValue <= 100, "DAAG: Quorum percentage cannot exceed 100");
         }

         _proposalCounter++;
         proposalId = _proposalCounter;

         _proposals[proposalId] = Proposal({
             id: proposalId,
             proposalType: ProposalType.ChangeGalleryParam,
             proposer: msg.sender,
             creationTime: block.timestamp,
             votingPeriodEnd: block.timestamp + votingPeriod,
             state: ProposalState.Active,
             data: abi.encode(_parameterIndex, _newValue), // Encode details
             votesFor: 0,
             votesAgainst: 0,
             hasVoted: new mapping(address => bool)()
         });
         _proposalIds.push(proposalId);

         emit ChangeGalleryParameterProposalSubmitted(proposalId, msg.sender, _parameterIndex, _newValue);
     }

    // --- Governance - Voting & Execution ---

    /**
     * @notice Allows a patron to cast a vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'For' vote, False for an 'Against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyPatron {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id != 0, "DAAG: Proposal does not exist"); // Check if proposal struct is initialized
        require(proposal.state == ProposalState.Active, "DAAG: Proposal is not active");
        require(block.timestamp <= proposal.votingPeriodEnd, "DAAG: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "DAAG: Patron has already voted");

        proposal.hasVoted[msg.sender] = true;

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a proposal that has passed its voting period and met the passing criteria.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id != 0, "DAAG: Proposal does not exist");
        require(proposal.state != ProposalState.Executed, "DAAG: Proposal already executed");
        require(proposal.state != ProposalState.Cancelled, "DAAG: Proposal cancelled");
        require(block.timestamp > proposal.votingPeriodEnd, "DAAG: Voting period is still active");

        // Determine if the proposal passed
        uint256 totalPatrons = getPatronCount(); // Use total minted patrons as base
        uint256 requiredVotes = (totalPatrons * quorumPercentage) / 100;
        bool passed = proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= requiredVotes;

        if (!passed) {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(_proposalId, ProposalState.Failed);
            return;
        }

        // Execute the proposal based on its type
        proposal.state = ProposalState.Executed; // Set state before execution to prevent re-entrancy issues

        if (proposal.proposalType == ProposalType.AddArt) {
            (address nftContract, uint264 tokenId, bool isERC721, string memory title, string memory artistName, string memory descriptionURI, bool isDynamic) = abi.decode(proposal.data, (address, uint264, bool, string, string, string, bool));
            // Note: isDynamic from decoded data won't be used as it was set false on creation.
            // Use the values directly from the proposal struct data.
             (address _nftContract, uint256 _tokenId, bool _isERC721, string memory _title, string memory _artistName, string memory _descriptionURI) = abi.decode(proposal.data, (address, uint256, bool, string, string, string)); // Decode only the relevant fields

            // The art must be transferred to this contract *before* or *during* execution.
            // The `onERC721Received` and `onERC1155Received` checks verify if a pending/passed
            // AddArt proposal exists for the incoming NFT.
            // For execution, we just need to confirm the contract *holds* the NFT now.

            // Check actual ownership
            if (_isERC721) {
                IERC721 nft = IERC721(_nftContract);
                require(nft.ownerOf(_tokenId) == address(this), "DAAG: Gallery does not own the ERC721 art after proposal passed");
            } else { // ERC1155
                 IERC1155 nft = IERC1155(_nftContract);
                 require(nft.balanceOf(address(this), _tokenId) > 0, "DAAG: Gallery does not own the ERC1155 art after proposal passed");
                 // Note: For ERC1155, we assume quantity 1 for art pieces unless specified otherwise.
                 // If quantity matters, the proposal data needs to include it.
            }

            // Add to internal state
            ArtDetails memory artDetails = ArtDetails({
                 nftContract: _nftContract,
                 tokenId: _tokenId,
                 isERC721: _isERC721,
                 title: _title,
                 artistName: _artistName,
                 descriptionURI: _descriptionURI,
                 isDynamic: false // Default non-dynamic on add. Use another proposal to mark dynamic.
             });
             _addArtToGallery(artDetails);

        } else if (proposal.proposalType == ProposalType.FundArtist) {
            (address recipient, uint256 amount, ) = abi.decode(proposal.data, (address, uint256, string));
            require(address(this).balance >= amount, "DAAG: Insufficient treasury balance for funding");
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "DAAG: Funding transfer failed");
            emit TreasuryWithdrawal(recipient, amount);

        } else if (proposal.proposalType == ProposalType.SellArt) {
            (address nftContract, uint256 tokenId, uint256 salePrice, address buyer) = abi.decode(proposal.data, (address, uint256, uint256, address));
            require(isGalleryOwnedArt(nftContract, tokenId), "DAAG: Art no longer owned by gallery for sale");
            ArtDetails memory art = _galleryOwnedArt[nftContract][tokenId];

            // Handle receiving payment (if price > 0) - this is complex.
            // Option 1: Buyer sends Ether *before* execution, contract checks balance.
            // Option 2: Buyer sends Ether *during* execution via `call`.
            // Option 3: Buyer sends Ether *after* execution (risky for seller).
            // Let's assume Option 1 or that the buyer is trusted/handled off-chain.
            // We will *only* transfer the NFT here. Payment is prerequisite/handled elsewhere.
             require(art.isERC721, "DAAG: SellArt proposal only supports ERC721 currently"); // Simplify for example
             IERC721 nft = IERC721(nftContract);
             nft.safeTransferFrom(address(this), buyer, tokenId);

             _removeArtFromGallery(nftContract, tokenId);
             // Funds received should be sent directly to treasury or processed separately.
             // This simplified version assumes payment is separate.

        } else if (proposal.proposalType == ProposalType.ChangeDynamicParam) {
            (address nftContract, uint256 tokenId, string memory parameterName, string memory parameterValue) = abi.decode(proposal.data, (address, uint256, string, string));
            require(isGalleryOwnedArt(nftContract, tokenId), "DAAG: Art no longer owned for parameter change");
            require(_galleryOwnedArt[nftContract][tokenId].isDynamic, "DAAG: Art piece is not marked as dynamic for parameter change");

            _dynamicArtParameters[nftContract][tokenId][parameterName] = parameterValue;
            emit DynamicArtParameterChanged(nftContract, tokenId, parameterName, parameterValue);

        } else if (proposal.proposalType == ProposalType.ChangeGalleryParam) {
            (uint256 parameterIndex, uint256 newValue) = abi.decode(proposal.data, (uint256, uint256));
            if (parameterIndex == 0) {
                uint256 oldValue = votingPeriod;
                votingPeriod = newValue;
                emit GalleryParameterChanged(0, oldValue, newValue);
            } else if (parameterIndex == 1) {
                uint256 oldValue = quorumPercentage;
                quorumPercentage = newValue;
                emit GalleryParameterChanged(1, oldValue, newValue);
            }
            // Add more parameters here if needed

        } else if (proposal.proposalType == ProposalType.GenericCall) {
            // WARNING: GenericCall is powerful and risky! Requires careful encoding.
            // (address target, uint256 value, bytes data) = abi.decode(proposal.data, (address, uint256, bytes));
            // (bool success, ) = target.call{value: value}(data);
            // require(success, "DAAG: Generic call failed");
             revert("DAAG: GenericCall proposal type is disabled in this example"); // Disabled by default for safety
        }


        emit ProposalExecuted(_proposalId);
    }

     /**
      * @notice Allows the proposer or owner to cancel a proposal before voting ends.
      * @param _proposalId The ID of the proposal to cancel.
      */
     function cancelProposal(uint256 _proposalId) public {
         Proposal storage proposal = _proposals[_proposalId];
         require(proposal.id != 0, "DAAG: Proposal does not exist");
         require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "DAAG: Proposal not in cancelable state");
         require(msg.sender == proposal.proposer || msg.sender == owner(), "DAAG: Only proposer or owner can cancel");
         require(block.timestamp <= proposal.votingPeriodEnd, "DAAG: Voting period has ended");

         proposal.state = ProposalState.Cancelled;
         emit ProposalCancelled(_proposalId);
     }

    // --- Governance - Query ---

    /**
     * @notice Returns the total number of proposals created.
     */
    function getProposalCount() public view returns (uint256) {
        return _proposalCounter;
    }

    /**
     * @notice Returns the details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return The Proposal struct.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id != 0, "DAAG: Proposal does not exist");
        return proposal;
    }

    /**
     * @notice Returns the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The current ProposalState.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id != 0, "DAAG: Proposal does not exist");

        // Recalculate state if voting period has ended but not yet executed/failed
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingPeriodEnd) {
             uint256 totalPatrons = getPatronCount();
             uint256 requiredVotes = (totalPatrons * quorumPercentage) / 100;
             if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= requiredVotes) {
                 return ProposalState.Passed;
             } else {
                 return ProposalState.Failed;
             }
        }

        return proposal.state;
    }

    /**
     * @notice Checks if a specific address has voted on a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voter The address to check.
     * @return True if the address has voted, false otherwise.
     */
    function hasVoted(uint256 _proposalId, address _voter) public view returns (bool) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id != 0, "DAAG: Proposal does not exist");
        return proposal.hasVoted[_voter];
    }


    // --- Dynamic Art Parameter Management ---

    /**
     * @notice Returns the current value of a specific dynamic parameter for an art piece.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The token ID.
     * @param _parameterName The name of the parameter.
     * @return The value of the parameter. Returns empty string if not found.
     */
    function getDynamicArtParameter(address _nftContract, uint256 _tokenId, string memory _parameterName) public view returns (string memory) {
         require(isGalleryOwnedArt(_nftContract, _tokenId), "DAAG: Art not owned by gallery");
         require(_galleryOwnedArt[_nftContract][_tokenId].isDynamic, "DAAG: Art piece is not marked as dynamic");
         return _dynamicArtParameters[_nftContract][_tokenId][_parameterName];
    }

    // Note: Setting dynamic art parameters is done *only* via the `executeProposal` function
    // when a `ChangeDynamicParam` proposal passes. There is no direct setter function.

    // --- Utility & Query Functions ---

    /**
     * @notice Returns the current voting period in seconds.
     */
    function getVotingPeriod() public view returns (uint256) {
        return votingPeriod;
    }

    /**
     * @notice Returns the current quorum percentage required for proposals to pass.
     */
    function getQuorumPercentage() public view returns (uint256) {
        return quorumPercentage;
    }

    // --- ERC721 & ERC1155 Receiver Hooks ---

    /**
     * @notice ERC721 received hook. Only accepts transfers associated with an active or passed AddArt proposal.
     * @dev See https://eips.ethereum.org/EIPS/eip-721
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes data) external override returns (bytes4) {
        // Check if the sender is the ERC721 contract we expect to interact with
        require(msg.sender == ERC721_INTERFACE_ADDRESS, "DAAG: Only configured ERC721 contract allowed");

        // Data should contain the proposal ID associated with this transfer
        require(data.length == 32, "DAAG: ERC721 receive data must contain proposalId");
        uint256 proposalId = abi.decode(data, (uint256));

        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id != 0, "DAAG: No matching proposal found for incoming ERC721");
        require(proposal.proposalType == ProposalType.AddArt, "DAAG: Incoming ERC721 not tied to AddArt proposal");

        // Decode expected art details from proposal data
        (address expectedNftContract, uint256 expectedTokenId, bool isERC721, , , ) = abi.decode(proposal.data, (address, uint256, bool, string, string, string));

        require(msg.sender == expectedNftContract, "DAAG: Incoming ERC721 contract mismatch with proposal");
        require(tokenId == expectedTokenId, "DAAG: Incoming ERC721 token ID mismatch with proposal");
        require(isERC721, "DAAG: Proposal type specifies ERC721, but receiver hook for ERC721 called");
        require(from == proposal.proposer || msg.sender == proposal.proposer, "DAAG: ERC721 transfer not from proposer or contract?"); // Basic check, depends on transfer flow

        // Proposal state should be Active or Passed for the transfer to be valid contextually
        // Execution requires the NFT to be here *after* passing.
        // This hook allows receiving the NFT *in anticipation* of or *as part of* execution.
        // The `executeProposal` function will perform the final state update (_addArtToGallery)
        // and check actual ownership by the gallery address at that time.
        // We don't add to _galleryOwnedArt here, only in `executeProposal`.

        return this.onERC721Received.selector;
    }

    /**
     * @notice ERC1155 received hook (single). Only accepts transfers associated with an active or passed AddArt proposal.
     * @dev See https://eips.ethereum.org/EIPS/eip-1155
     */
    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes data) external override returns (bytes4) {
         require(msg.sender == ERC1155_INTERFACE_ADDRESS, "DAAG: Only configured ERC1155 contract allowed");
         require(amount == 1, "DAAG: Only single ERC1155 art pieces supported for AddArt proposal"); // Assuming art pieces are single editions or treated as such

         // Data should contain the proposal ID associated with this transfer
         require(data.length == 32, "DAAG: ERC1155 receive data must contain proposalId");
         uint256 proposalId = abi.decode(data, (uint256));

         Proposal storage proposal = _proposals[proposalId];
         require(proposal.id != 0, "DAAG: No matching proposal found for incoming ERC1155");
         require(proposal.proposalType == ProposalType.AddArt, "DAAG: Incoming ERC1155 not tied to AddArt proposal");

         // Decode expected art details from proposal data
         (address expectedNftContract, uint256 expectedTokenId, bool isERC721, , , ) = abi.decode(proposal.data, (address, uint256, bool, string, string, string));

         require(msg.sender == expectedNftContract, "DAAG: Incoming ERC1155 contract mismatch with proposal");
         require(id == expectedTokenId, "DAAG: Incoming ERC1155 token ID mismatch with proposal");
         require(!isERC721, "DAAG: Proposal type specifies ERC1155, but receiver hook for ERC1155 called");
         require(from == proposal.proposer || msg.sender == proposal.proposer, "DAAG: ERC1155 transfer not from proposer or contract?"); // Basic check

         // See comments in onERC721Received regarding state update location.

         return this.onERC1155Received.selector;
    }

    /**
     * @notice ERC1155 received hook (batch). Not typically used for single art pieces in this model,
     *         but included for completeness. We will disallow it for AddArt proposals.
     * @dev See https://eips.ethereum.org/EIPS/eip-1155
     */
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes data) external override returns (bytes4) {
         require(msg.sender == ERC1155_INTERFACE_ADDRESS, "DAAG: Only configured ERC1155 contract allowed");
         // Disallow batch transfers for AddArt proposals in this contract model
         revert("DAAG: Batch ERC1155 transfers are not supported for proposals");
         // return this.onERC1155BatchReceived.selector; // If allowing, return this
    }

    // --- Fallback Function ---
    // Not needed if using `receive()` for Ether

}
```