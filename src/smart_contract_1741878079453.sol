```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Evolving Metadata and Community Governance
 * @author Bard (Example Smart Contract - Educational Purposes)
 *
 * @dev This smart contract implements a dynamic NFT marketplace where NFT metadata can evolve based on community votes.
 * It includes features for NFT creation, listing, buying, staking for governance participation,
 * proposing and voting on metadata updates, implementing royalties, and more.
 *
 * Function Summary:
 * -----------------
 * **NFT Core Functions:**
 * - mintNFT(address _to, string memory _baseURI): Mints a new NFT to the specified address with an initial base URI.
 * - setBaseMetadataURI(uint256 _tokenId, string memory _baseURI): Sets the base metadata URI for a specific NFT.
 * - tokenURI(uint256 _tokenId): Returns the dynamic token URI for a given NFT ID, considering metadata updates.
 * - ownerOf(uint256 _tokenId): Returns the owner of an NFT.
 * - balanceOf(address _owner): Returns the number of NFTs owned by an address.
 * - totalSupply(): Returns the total number of NFTs minted.
 * - transferNFT(address _from, address _to, uint256 _tokenId): Transfers an NFT from one address to another.
 * - approve(address _approved, uint256 _tokenId): Approves an address to operate on a specific NFT.
 * - getApproved(uint256 _tokenId): Gets the approved address for a specific NFT.
 * - setApprovalForAll(address _operator, bool _approved): Enables or disables approval for all NFTs for an operator.
 * - isApprovedForAll(address _owner, address _operator): Checks if an operator is approved for all NFTs of an owner.
 *
 * **Marketplace Functions:**
 * - listNFT(uint256 _tokenId, uint256 _price): Lists an NFT for sale at a specified price.
 * - buyNFT(uint256 _tokenId): Allows buying a listed NFT.
 * - cancelListing(uint256 _tokenId): Cancels the listing of an NFT.
 * - updateListingPrice(uint256 _tokenId, uint256 _newPrice): Updates the listing price of an NFT.
 * - getListingPrice(uint256 _tokenId): Retrieves the current listing price of an NFT.
 * - isListed(uint256 _tokenId): Checks if an NFT is currently listed for sale.
 *
 * **Dynamic Metadata & Governance Functions:**
 * - stakeNFTForGovernance(uint256 _tokenId): Stakes an NFT to participate in metadata update proposals and voting.
 * - unstakeNFTForGovernance(uint256 _tokenId): Unstakes an NFT, removing it from governance participation.
 * - proposeMetadataUpdate(uint256 _tokenId, string memory _newMetadataHash, string memory _reason): Proposes a metadata update for an NFT.
 * - voteOnMetadataUpdate(uint256 _proposalId, bool _vote): Allows staked NFT holders to vote on metadata update proposals.
 * - executeMetadataUpdate(uint256 _proposalId): Executes a metadata update proposal if it passes the voting threshold.
 * - getCurrentMetadataHash(uint256 _tokenId): Returns the currently active metadata hash for an NFT.
 * - getProposalDetails(uint256 _proposalId): Retrieves details of a metadata update proposal.
 * - getStakedNFTsForAddress(address _owner): Returns a list of NFT IDs staked by an address for governance.
 *
 * **Royalty & Platform Fee Functions:**
 * - setRoyaltyRecipient(uint256 _tokenId, address _recipient): Sets the royalty recipient address for an NFT.
 * - setRoyaltyPercentage(uint256 _tokenId, uint256 _percentage): Sets the royalty percentage for an NFT (in basis points, e.g., 100 = 1%).
 * - withdrawRoyalties(uint256 _tokenId): Allows royalty recipients to withdraw accumulated royalties.
 * - setPlatformFeePercentage(uint256 _percentage): Sets the platform fee percentage for marketplace sales.
 * - withdrawPlatformFees(): Allows the contract owner to withdraw accumulated platform fees.
 *
 * **Admin & Utility Functions:**
 * - setContractURI(string memory _contractURI): Sets the contract-level metadata URI.
 * - getContractURI(): Returns the contract-level metadata URI.
 * - pauseContract(): Pauses most contract functionalities.
 * - unpauseContract(): Resumes contract functionalities.
 * - isContractPaused(): Checks if the contract is currently paused.
 * - supportsInterface(bytes4 interfaceId): Implements ERC165 interface detection.
 */

contract DynamicNFTMarketplace {
    // --- State Variables ---

    string public name = "Dynamic Evolving NFTs";
    string public symbol = "DENFT";
    string public contractURI; // Contract-level metadata URI

    mapping(uint256 => address) public ownerOfNFT; // NFT ID => Owner address
    mapping(address => uint256) public balanceOfAddress; // Owner address => NFT count
    mapping(uint256 => address) private _tokenApprovals; // NFT ID => Approved address for single transfer
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner => Operator => Approval status for all transfers
    uint256 public totalSupplyNFT; // Total number of NFTs minted

    mapping(uint256 => string) public baseMetadataURI; // NFT ID => Base Metadata URI (initial)
    mapping(uint256 => string) public currentMetadataHash; // NFT ID => Current Metadata Hash (dynamic)

    mapping(uint256 => uint256) public nftListingPrice; // NFT ID => Listing Price (in wei)
    mapping(uint256 => bool) public isNFTListed; // NFT ID => Is Listed for Sale
    mapping(uint256 => address) public nftLister; // NFT ID => Lister address

    mapping(uint256 => bool) public isNFTStakedForGovernance; // NFT ID => Is Staked for Governance
    mapping(address => uint256[]) public stakedNFTsByAddress; // Address => Array of staked NFT IDs

    struct MetadataUpdateProposal {
        uint256 tokenId;
        string newMetadataHash;
        string reason;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) voters; // Address => Has voted
        bool executed;
        bool passed;
    }
    mapping(uint256 => MetadataUpdateProposal) public metadataProposals; // Proposal ID => Proposal Details
    uint256 public proposalCounter; // Counter for Proposal IDs
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public votingThresholdPercentage = 50; // Percentage of staked NFTs required to pass a proposal

    mapping(uint256 => address) public royaltyRecipient; // NFT ID => Royalty Recipient address
    mapping(uint256 => uint256) public royaltyPercentage; // NFT ID => Royalty Percentage (basis points)
    mapping(uint256 => uint256) public accumulatedRoyalties; // NFT ID => Accumulated Royalties (in wei)

    uint256 public platformFeePercentage = 250; // Platform fee percentage (basis points, default 2.5%)
    uint256 public accumulatedPlatformFees; // Accumulated Platform Fees (in wei)
    address payable public contractOwner;

    bool public contractPaused = false;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to, string baseURI);
    event NFTListed(uint256 tokenId, uint256 price, address lister);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTListingCancelled(uint256 tokenId);
    event NFTPriceUpdated(uint256 tokenId, uint256 newPrice);
    event NFTStakedForGovernance(uint256 tokenId, address staker);
    event NFTUnstakedFromGovernance(uint256 tokenId, address unstaker);
    event MetadataUpdateProposed(uint256 proposalId, uint256 tokenId, string newMetadataHash, string reason, uint256 endTime);
    event MetadataUpdateVoted(uint256 proposalId, address voter, bool vote);
    event MetadataUpdateExecuted(uint256 proposalId, uint256 tokenId, string newMetadataHash);
    event RoyaltyRecipientSet(uint256 tokenId, address recipient);
    event RoyaltyPercentageSet(uint256 tokenId, uint256 percentage);
    event RoyaltiesWithdrawn(uint256 tokenId, address recipient, uint256 amount);
    event PlatformFeePercentageSet(uint256 percentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused();
    event ContractUnpaused();
    event ContractURISet(string uri);
    event BaseMetadataURISet(uint256 tokenId, string baseURI);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(ownerOfNFT[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier onlyListedNFTOwner(uint256 _tokenId) {
        require(isNFTListed[_tokenId] && nftLister[_tokenId] == msg.sender, "You are not the lister of this NFT.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(metadataProposals[_proposalId].tokenId != 0, "Invalid proposal ID.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!metadataProposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.timestamp >= metadataProposals[_proposalId].startTime && block.timestamp <= metadataProposals[_proposalId].endTime, "Voting period is not active.");
        _;
    }

    modifier notVotedYet(uint256 _proposalId) {
        require(!metadataProposals[_proposalId].voters[msg.sender], "You have already voted on this proposal.");
        _;
    }

    modifier nftNotStaked(uint256 _tokenId) {
        require(!isNFTStakedForGovernance[_tokenId], "NFT is already staked for governance.");
        _;
    }

    modifier nftStaked(uint256 _tokenId) {
        require(isNFTStakedForGovernance[_tokenId], "NFT is not staked for governance.");
        _;
    }


    // --- Constructor ---
    constructor() payable {
        contractOwner = payable(msg.sender);
    }

    // --- NFT Core Functions ---
    function mintNFT(address _to, string memory _baseURI) public onlyOwner whenNotPaused {
        totalSupplyNFT++;
        uint256 tokenId = totalSupplyNFT;
        ownerOfNFT[tokenId] = _to;
        balanceOfAddress[_to]++;
        baseMetadataURI[tokenId] = _baseURI;
        currentMetadataHash[tokenId] = _baseURI; // Initial metadata is the base URI
        emit NFTMinted(tokenId, _to, _baseURI);
    }

    function setBaseMetadataURI(uint256 _tokenId, string memory _baseURI) public onlyOwner whenNotPaused {
        require(ownerOfNFT[_tokenId] != address(0), "NFT does not exist.");
        baseMetadataURI[_tokenId] = _baseURI;
        emit BaseMetadataURISet(_tokenId, _baseURI);
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(ownerOfNFT[_tokenId] != address(0), "NFT does not exist.");
        return currentMetadataHash[_tokenId]; // Dynamic URI based on current metadata hash
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return ownerOfNFT[_tokenId];
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balanceOfAddress[_owner];
    }

    function totalSupply() public view returns (uint256) {
        return totalSupplyNFT;
    }

    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved.");
        require(ownerOfNFT[_tokenId] == _from, "Incorrect 'from' address.");
        require(_to != address(0), "Transfer to the zero address.");

        _beforeTokenTransfer(_from, _to, _tokenId);

        _clearApproval(_tokenId);

        balanceOfAddress[_from]--;
        balanceOfAddress[_to]++;
        ownerOfNFT[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOfNFT[_tokenId], _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(ownerOfNFT[_tokenId] != address(0), "NFT does not exist.");
        return _tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }


    // --- Marketplace Functions ---
    function listNFT(uint256 _tokenId, uint256 _price) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(!isNFTListed[_tokenId], "NFT is already listed.");
        require(_price > 0, "Price must be greater than zero.");
        isNFTListed[_tokenId] = true;
        nftListingPrice[_tokenId] = _price;
        nftLister[_tokenId] = msg.sender;
        emit NFTListed(_tokenId, _price, msg.sender);
    }

    function buyNFT(uint256 _tokenId) public payable whenNotPaused {
        require(isNFTListed[_tokenId], "NFT is not listed for sale.");
        uint256 price = nftListingPrice[_tokenId];
        require(msg.value >= price, "Insufficient funds sent.");

        address seller = nftLister[_tokenId];
        require(seller != msg.sender, "Cannot buy your own NFT.");

        isNFTListed[_tokenId] = false;
        delete nftListingPrice[_tokenId];
        delete nftLister[_tokenId];

        // Transfer funds and calculate royalties/platform fees
        uint256 platformFee = (price * platformFeePercentage) / 10000; // Basis points
        uint256 royaltyAmount = (price * royaltyPercentage[_tokenId]) / 10000;
        uint256 sellerProceeds = price - platformFee - royaltyAmount;

        accumulatedPlatformFees += platformFee;
        accumulatedRoyalties[_tokenId] += royaltyAmount;

        payable(seller).transfer(sellerProceeds);
        transferNFT(seller, msg.sender, _tokenId); // Internal transfer

        emit NFTBought(_tokenId, msg.sender, seller, price);

        // Return any excess ETH sent
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function cancelListing(uint256 _tokenId) public whenNotPaused onlyListedNFTOwner(_tokenId) {
        require(isNFTListed[_tokenId], "NFT is not listed.");
        isNFTListed[_tokenId] = false;
        delete nftListingPrice[_tokenId];
        delete nftLister[_tokenId];
        emit NFTListingCancelled(_tokenId);
    }

    function updateListingPrice(uint256 _tokenId, uint256 _newPrice) public whenNotPaused onlyListedNFTOwner(_tokenId) {
        require(isNFTListed[_tokenId], "NFT is not listed.");
        require(_newPrice > 0, "New price must be greater than zero.");
        nftListingPrice[_tokenId] = _newPrice;
        emit NFTPriceUpdated(_tokenId, _newPrice);
    }

    function getListingPrice(uint256 _tokenId) public view returns (uint256) {
        return nftListingPrice[_tokenId];
    }

    function isListed(uint256 _tokenId) public view returns (bool) {
        return isNFTListed[_tokenId];
    }


    // --- Dynamic Metadata & Governance Functions ---
    function stakeNFTForGovernance(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) nftNotStaked(_tokenId) {
        isNFTStakedForGovernance[_tokenId] = true;
        stakedNFTsByAddress[msg.sender].push(_tokenId);
        emit NFTStakedForGovernance(_tokenId, msg.sender);
    }

    function unstakeNFTForGovernance(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) nftStaked(_tokenId) {
        isNFTStakedForGovernance[_tokenId] = false;
        // Remove from stakedNFTsByAddress array (more gas efficient way needed for large arrays in production)
        uint256[] storage stakedNFTs = stakedNFTsByAddress[msg.sender];
        for (uint256 i = 0; i < stakedNFTs.length; i++) {
            if (stakedNFTs[i] == _tokenId) {
                stakedNFTs[i] = stakedNFTs[stakedNFTs.length - 1];
                stakedNFTs.pop();
                break;
            }
        }
        emit NFTUnstakedFromGovernance(_tokenId, msg.sender);
    }

    function proposeMetadataUpdate(uint256 _tokenId, string memory _newMetadataHash, string memory _reason) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(bytes(_newMetadataHash).length > 0, "New metadata hash cannot be empty.");
        proposalCounter++;
        metadataProposals[proposalCounter] = MetadataUpdateProposal({
            tokenId: _tokenId,
            newMetadataHash: _newMetadataHash,
            reason: _reason,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false
        });
        emit MetadataUpdateProposed(proposalCounter, _tokenId, _newMetadataHash, _reason, metadataProposals[proposalCounter].endTime);
    }

    function voteOnMetadataUpdate(uint256 _proposalId, bool _vote) public whenNotPaused validProposal(_proposalId) proposalNotExecuted(_proposalId) votingPeriodActive(_proposalId) notVotedYet(_proposalId) {
        require(isNFTStakedForGovernance[metadataProposals[_proposalId].tokenId], "NFT must be staked to vote.");
        metadataProposals[_proposalId].voters[msg.sender] = true;
        if (_vote) {
            metadataProposals[_proposalId].yesVotes++;
        } else {
            metadataProposals[_proposalId].noVotes++;
        }
        emit MetadataUpdateVoted(_proposalId, msg.sender, _vote);
    }

    function executeMetadataUpdate(uint256 _proposalId) public whenNotPaused validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp > metadataProposals[_proposalId].endTime, "Voting period is still active.");

        uint256 totalStakedSupply = 0;
        for (uint256 i = 1; i <= totalSupplyNFT; i++) { // Iterate through all NFTs to count staked ones (inefficient for large scale, optimize in real world)
            if (isNFTStakedForGovernance[i]) {
                totalStakedSupply++;
            }
        }
        require(totalStakedSupply > 0, "No NFTs are staked, cannot execute proposal.");

        uint256 requiredYesVotes = (totalStakedSupply * votingThresholdPercentage) / 100;
        if (metadataProposals[_proposalId].yesVotes >= requiredYesVotes) {
            metadataProposals[_proposalId].passed = true;
            currentMetadataHash[metadataProposals[_proposalId].tokenId] = metadataProposals[_proposalId].newMetadataHash;
            metadataProposals[_proposalId].executed = true;
            emit MetadataUpdateExecuted(_proposalId, metadataProposals[_proposalId].tokenId, metadataProposals[_proposalId].newMetadataHash);
        } else {
            metadataProposals[_proposalId].passed = false;
            metadataProposals[_proposalId].executed = true; // Mark as executed even if failed
        }
    }

    function getCurrentMetadataHash(uint256 _tokenId) public view returns (string memory) {
        return currentMetadataHash[_tokenId];
    }

    function getProposalDetails(uint256 _proposalId) public view validProposal(_proposalId) returns (MetadataUpdateProposal memory) {
        return metadataProposals[_proposalId];
    }

    function getStakedNFTsForAddress(address _owner) public view returns (uint256[] memory) {
        return stakedNFTsByAddress[_owner];
    }


    // --- Royalty & Platform Fee Functions ---
    function setRoyaltyRecipient(uint256 _tokenId, address _recipient) public onlyOwner whenNotPaused {
        royaltyRecipient[_tokenId] = _recipient;
        emit RoyaltyRecipientSet(_tokenId, _recipient);
    }

    function setRoyaltyPercentage(uint256 _tokenId, uint256 _percentage) public onlyOwner whenNotPaused {
        require(_percentage <= 10000, "Royalty percentage cannot exceed 100%."); // Max 100%
        royaltyPercentage[_tokenId] = _percentage;
        emit RoyaltyPercentageSet(_tokenId, _percentage);
    }

    function withdrawRoyalties(uint256 _tokenId) public whenNotPaused {
        require(royaltyRecipient[_tokenId] == msg.sender, "You are not the royalty recipient.");
        uint256 amount = accumulatedRoyalties[_tokenId];
        require(amount > 0, "No royalties to withdraw.");
        accumulatedRoyalties[_tokenId] = 0; // Reset accumulated royalties after withdrawal
        payable(msg.sender).transfer(amount);
        emit RoyaltiesWithdrawn(_tokenId, msg.sender, amount);
    }

    function setPlatformFeePercentage(uint256 _percentage) public onlyOwner whenNotPaused {
        require(_percentage <= 10000, "Platform fee percentage cannot exceed 100%."); // Max 100%
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageSet(_percentage);
    }

    function withdrawPlatformFees() public onlyOwner whenNotPaused {
        uint256 amount = accumulatedPlatformFees;
        require(amount > 0, "No platform fees to withdraw.");
        accumulatedPlatformFees = 0;
        payable(contractOwner).transfer(amount);
        emit PlatformFeesWithdrawn(amount, contractOwner);
    }


    // --- Admin & Utility Functions ---
    function setContractURI(string memory _contractURI) public onlyOwner whenNotPaused {
        contractURI = _contractURI;
        emit ContractURISet(_contractURI);
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function pauseContract() public onlyOwner whenNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner whenPaused {
        contractPaused = false;
        emit ContractUnpaused();
    }

    function isContractPaused() public view returns (bool) {
        return contractPaused;
    }

    // --- ERC165 Interface Support ---
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }


    // --- Internal helper functions (copied from OpenZeppelin ERC721, adapted) ---

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOfNFT[_tokenId];
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // Placeholder for extensions (like hooks before transfer)
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            delete _tokenApprovals[tokenId];
        }
    }

    // --- ERC721 Interface ---
    interface IERC721 {
        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

        function balanceOf(address owner) external view returns (uint256 balance);
        function ownerOf(uint256 tokenId) external view returns (address owner);
        function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
        function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
        function transferFrom(address from, address to, uint256 tokenId) external payable;
        function approve(address approved, uint256 tokenId) external payable;
        function getApproved(uint256 tokenId) external view returns (address operator);
        function setApprovalForAll(address operator, bool approved) external payable;
        function isApprovedForAll(address owner, address operator) external view returns (bool);
    }

    // --- ERC721 Metadata Interface ---
    interface IERC721Metadata is IERC721 {
        function name() external view returns (string memory);
        function symbol() external view returns (string memory);
        function tokenURI(uint256 tokenId) external view returns (string memory);
    }

    // --- ERC165 Interface ---
    interface IERC165 {
        function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }
}
```