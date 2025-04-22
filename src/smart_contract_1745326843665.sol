```solidity
/**
 * @title Dynamic and Governed NFT Ecosystem Contract - "Chameleon NFTs"
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT system where NFTs can evolve, and the ecosystem is governed by NFT holders through proposals and voting.
 *
 * **Contract Outline and Function Summary:**
 *
 * **Core NFT Functionality:**
 * 1. `mintNFT(address _to, string memory _baseMetadataURI)`: Mints a new Chameleon NFT to a specified address with an initial base metadata URI.
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers ownership of a Chameleon NFT.
 * 3. `approve(address _approved, uint256 _tokenId)`: Approves an address to operate on a single Chameleon NFT.
 * 4. `getApproved(uint256 _tokenId)`: Gets the approved address for a single Chameleon NFT.
 * 5. `setApprovalForAll(address _operator, bool _approved)`: Enables or disables approval for a third party to manage all of the caller's Chameleon NFTs.
 * 6. `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved to manage all NFTs of an owner.
 * 7. `balanceOf(address _owner)`: Returns the number of Chameleon NFTs owned by an address.
 * 8. `ownerOf(uint256 _tokenId)`: Returns the owner of a Chameleon NFT.
 * 9. `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a Chameleon NFT, dynamically generated based on its state.
 * 10. `supportsInterface(bytes4 interfaceId)`:  Standard ERC721 interface support check.
 *
 * **Dynamic NFT Evolution & Features:**
 * 11. `evolveNFT(uint256 _tokenId, uint8 _evolutionType)`: Allows NFT holders to trigger an evolution of their NFT based on predefined types.
 * 12. `getNFTStatus(uint256 _tokenId)`: Returns the current evolution status and traits of a Chameleon NFT.
 * 13. `setEvolutionRules(uint8 _evolutionType, string memory _ruleDescription)`: Contract owner function to define rules for different evolution types.
 * 14. `getBaseMetadataURI(uint256 _tokenId)`: Returns the base metadata URI set during minting (can be used for initial traits).
 * 15. `setBaseMetadataURIForNFT(uint256 _tokenId, string memory _newBaseMetadataURI)`: Owner function to update the base metadata URI of a specific NFT (for corrections or updates).
 *
 * **Governance and Community Features:**
 * 16. `proposeFeature(string memory _proposalTitle, string memory _proposalDescription)`: NFT holders can propose new features or changes to the NFT ecosystem.
 * 17. `voteOnProposal(uint256 _proposalId, bool _voteFor)`: NFT holders can vote on active proposals. Voting power is based on the number of NFTs owned.
 * 18. `executeProposal(uint256 _proposalId)`:  Owner function to execute a successful proposal after voting period ends.
 * 19. `getProposalDetails(uint256 _proposalId)`: View details of a specific proposal, including votes and status.
 * 20. `setVotingDuration(uint256 _durationInBlocks)`: Owner function to set the duration of voting periods for proposals.
 * 21. `pauseContract()`: Owner function to pause core contract functionalities in case of emergency.
 * 22. `unpauseContract()`: Owner function to resume contract functionalities after pausing.
 * 23. `withdrawContractBalance()`: Owner function to withdraw any ether accidentally sent to the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

contract ChameleonNFTs is ERC721, Ownable, IERC721Enumerable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner address to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Base metadata URI for initial NFT traits
    mapping(uint256 => string) private _baseMetadataURIs;

    // Dynamic NFT status and traits
    struct NFTStatus {
        uint8 evolutionLevel;
        uint8 evolutionType; // Type of evolution applied
        uint256 lastEvolvedTimestamp;
        // Add more dynamic traits as needed
    }
    mapping(uint256 => NFTStatus) public nftStatuses;

    // Evolution Rules
    mapping(uint8 => string) public evolutionRules;

    // Governance Proposals
    struct Proposal {
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool active;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public votingDurationInBlocks = 100; // Default voting duration

    // Contract Pausing
    bool public paused = false;

    // Events
    event NFTMinted(uint256 tokenId, address to, string baseMetadataURI);
    event NFTEvolved(uint256 tokenId, uint8 evolutionType);
    event ProposalCreated(uint256 proposalId, string title);
    event VoteCast(uint256 proposalId, address voter, bool voteFor);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyOwnerOrApproved(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        _;
    }

    modifier onlyNFTHolder(uint256 _tokenId) {
        require(_owners[_tokenId] == msg.sender, "Caller is not NFT holder");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].active, "Proposal is not active");
        require(block.number < proposals[_proposalId].endTime, "Voting period ended");
        _;
    }

    constructor() ERC721("ChameleonNFT", "CNFT") {
        // Initialize any contract setup here
    }

    /**
     * @dev Mints a new Chameleon NFT to a specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseMetadataURI The initial base metadata URI for the NFT.
     */
    function mintNFT(address _to, string memory _baseMetadataURI) public onlyOwner whenNotPaused returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(_to, tokenId);
        _baseMetadataURIs[tokenId] = _baseMetadataURI;
        nftStatuses[tokenId] = NFTStatus({
            evolutionLevel: 0,
            evolutionType: 0,
            lastEvolvedTimestamp: block.timestamp
        });

        emit NFTMinted(tokenId, _to, _baseMetadataURI);
        return tokenId;
    }

    /**
     * @dev Allows NFT holders to trigger an evolution of their NFT.
     * @param _tokenId The ID of the NFT to evolve.
     * @param _evolutionType The type of evolution to apply.
     */
    function evolveNFT(uint256 _tokenId, uint8 _evolutionType) public whenNotPaused onlyNFTHolder(_tokenId) {
        require(bytes(evolutionRules[_evolutionType]).length > 0, "Invalid evolution type");
        NFTStatus storage status = nftStatuses[_tokenId];
        // Implement evolution logic based on _evolutionType and current status
        // Example: Simple level increase
        status.evolutionLevel++;
        status.evolutionType = _evolutionType;
        status.lastEvolvedTimestamp = block.timestamp;
        // More complex logic can be added here, e.g., trait changes, resource consumption, etc.

        emit NFTEvolved(_tokenId, _evolutionType);
    }

    /**
     * @dev Returns the current evolution status and traits of a Chameleon NFT.
     * @param _tokenId The ID of the NFT.
     * @return NFTStatus struct containing the current status.
     */
    function getNFTStatus(uint256 _tokenId) public view returns (NFTStatus memory) {
        return nftStatuses[_tokenId];
    }

    /**
     * @dev Sets the rules for a specific evolution type (Owner only).
     * @param _evolutionType The type of evolution.
     * @param _ruleDescription A description of the evolution rules.
     */
    function setEvolutionRules(uint8 _evolutionType, string memory _ruleDescription) public onlyOwner whenNotPaused {
        evolutionRules[_evolutionType] = _ruleDescription;
    }

    /**
     * @dev Returns the base metadata URI set during minting.
     * @param _tokenId The ID of the NFT.
     * @return The base metadata URI.
     */
    function getBaseMetadataURI(uint256 _tokenId) public view returns (string memory) {
        return _baseMetadataURIs[_tokenId];
    }

    /**
     * @dev Allows the owner to update the base metadata URI of a specific NFT (for corrections or updates).
     * @param _tokenId The ID of the NFT to update.
     * @param _newBaseMetadataURI The new base metadata URI.
     */
    function setBaseMetadataURIForNFT(uint256 _tokenId, string memory _newBaseMetadataURI) public onlyOwner whenNotPaused {
        _baseMetadataURIs[_tokenId] = _newBaseMetadataURI;
    }

    /**
     * @dev Generates and returns the dynamic metadata URI for a Chameleon NFT.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory baseMetadataURI = getBaseMetadataURI(_tokenId);
        NFTStatus memory status = getNFTStatus(_tokenId);

        // Construct dynamic metadata URI based on base URI, base metadata URI, and NFT status
        string memory metadataURI = string(abi.encodePacked(
            baseURI,
            baseMetadataURI,
            "?tokenId=", _tokenId.toString(),
            "&evolutionLevel=", status.evolutionLevel.toString(),
            "&evolutionType=", status.evolutionType.toString(),
            "&lastEvolved=", status.lastEvolvedTimestamp.toString()
            // Add more dynamic parameters to the URI as needed based on NFTStatus
        ));

        return metadataURI;
    }

    /**
     * @dev Proposes a new feature or change to the NFT ecosystem.
     * @param _proposalTitle Title of the proposal.
     * @param _proposalDescription Detailed description of the proposal.
     */
    function proposeFeature(string memory _proposalTitle, string memory _proposalDescription) public whenNotPaused {
        require(balanceOf(msg.sender) > 0, "Must hold at least one NFT to propose");
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();
        proposals[proposalId] = Proposal({
            title: _proposalTitle,
            description: _proposalDescription,
            startTime: block.number,
            endTime: block.number + votingDurationInBlocks,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            active: true
        });
        emit ProposalCreated(proposalId, _proposalTitle);
    }

    /**
     * @dev Allows NFT holders to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _voteFor True to vote in favor, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _voteFor) public whenNotPaused proposalActive(_proposalId) {
        require(balanceOf(msg.sender) > 0, "Must hold at least one NFT to vote");
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");

        //Voting power is equal to the number of NFTs held by the voter
        uint256 votingPower = balanceOf(msg.sender);

        if (_voteFor) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        emit VoteCast(_proposalId, msg.sender, _voteFor);
    }

    /**
     * @dev Allows the contract owner to execute a successful proposal after the voting period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "Proposal is not active");
        require(!proposal.executed, "Proposal already executed");
        require(block.number >= proposal.endTime, "Voting period not ended");

        proposal.active = false;
        proposal.executed = true;

        // Determine if proposal passed (simple majority for now)
        if (proposal.votesFor > proposal.votesAgainst) {
            // Implement proposal execution logic here based on proposal details
            // Example:  Update a contract parameter, trigger a function, etc.
            // For now, just emit an event.
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal failed, no action taken (can emit a different event if needed)
        }
    }

    /**
     * @dev Returns details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Sets the duration of voting periods for proposals (Owner only).
     * @param _durationInBlocks The duration in blocks.
     */
    function setVotingDuration(uint256 _durationInBlocks) public onlyOwner whenNotPaused {
        votingDurationInBlocks = _durationInBlocks;
    }

    /**
     * @dev Pauses core contract functionalities (Owner only).
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Resumes contract functionalities after pausing (Owner only).
     */
    function unpauseContract() public onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Allows the contract owner to withdraw any ether accidentally sent to the contract.
     */
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }

    // --------------------------------------------------
    // ERC721 Standard Implementation Overrides & Additions
    // --------------------------------------------------

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *  Overridden to provide dynamic tokenURI (defined above).
     */
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://your_base_ipfs_cid/"; // Replace with your base IPFS CID or other base URI
    }


    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address approved, uint256 tokenId) public override whenNotPaused onlyOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "ERC721: approve of nonexistent token");
        _tokenApprovals[tokenId] = approved;
        emit Approval(ownerOf(tokenId), approved, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused onlyOwnerOrApproved(tokenId) {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused onlyOwnerOrApproved(tokenId) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override whenNotPaused onlyOwnerOrApproved(tokenId) {
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Internal function to safely transfer tokens.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev See {IERC721-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC721, IERC721Metadata, IERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        // In a real-world scenario with enumerable tokens, you would need to maintain an array
        // of token IDs to efficiently implement this function. For simplicity in this example,
        // we are skipping full enumeration implementation as it adds complexity beyond the core concept.
        // Consider using a library or implementing proper enumeration for production contracts.
        // This is a placeholder and might not be performant for large collections.
        return index; // Placeholder -  not a true enumeration
    }

    /**
     * @dev @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(owner != address(0), "ERC721Enumerable: owner query for the zero address");
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        // Similar to tokenByIndex, full enumeration requires maintaining owner-token lists.
        // This is a placeholder and not a true enumeration for owner tokens.
        // Consider using a library or implementing proper enumeration for production contracts.
        return index; // Placeholder - not a true enumeration
    }


    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) { // Minting
            _balances[to]++;
        } else if (to == address(0)) { // Burning (not implemented in this example, but included for completeness)
            _balances[from]--;
        } else { // Transfer
            _balances[from]--;
            _balances[to]++;
        }

        if (from != address(0) && from != ownerOf(tokenId) ) {
            delete _tokenApprovals[tokenId]; // Clear approvals when token is transferred
        }
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * Does not check if the token is burned; _burn(tokenId) is private so we cannot call from outside.
     * Override _burn to add custom logic before burning if needed.
     */
    function _burn(uint256 tokenId) internal virtual override {
        address owner = ownerOf(tokenId);

        delete _tokenApprovals[tokenId]; // Clear approvals

        super._burn(tokenId);

        _balances[owner]--;
        delete _owners[tokenId];
    }


    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this function is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }


    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {safeTransferFrom}, {transferFrom} does not perform additional checks, instead
     *  it just executes a straight token transfer.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        delete _tokenApprovals[tokenId]; // Clear approvals from the token being transferred

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }


    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - when `from` is zero, `tokenId` was minted for `to`.
     * - when `to` is zero, `tokenId` was burned by `from`.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
    }


    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }


    /**
     * @dev Always returns true since this is a non-payable contract.
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        private
        returns (bool)
    {
        if (to.code.length > 0) {
            return IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) == IERC721Receiver.onERC721Received.selector;
        } else {
            return true;
        }
    }
}
```