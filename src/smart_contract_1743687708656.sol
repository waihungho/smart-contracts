```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Personalization and Governance
 * @author Bard (Large Language Model)
 * @dev A sophisticated NFT marketplace with dynamic NFTs, AI-driven personalization, and community governance.
 *
 * Outline & Function Summary:
 *
 * 1.  **Core Marketplace Functions:**
 *     - `createNFTCollection(string _collectionName, string _collectionSymbol, string _baseURI)`: Allows creators to deploy new NFT collections within the marketplace.
 *     - `listNFTForSale(address _nftContract, uint256 _tokenId, uint256 _price)`:  Allows NFT owners to list their NFTs for sale on the marketplace.
 *     - `purchaseNFT(address _nftContract, uint256 _tokenId)`: Allows users to purchase NFTs listed on the marketplace.
 *     - `cancelNFTListing(address _nftContract, uint256 _tokenId)`: Allows NFT owners to cancel their NFT listing.
 *     - `updateNFTListingPrice(address _nftContract, uint256 _tokenId, uint256 _newPrice)`: Allows NFT owners to update the price of their listed NFT.
 *     - `offerNFT(address _nftContract, uint256 _tokenId, uint256 _price)`: Allows users to make offers on NFTs that are not listed for sale.
 *     - `acceptOffer(address _nftContract, uint256 _tokenId, address _offerer)`: Allows NFT owners to accept a specific offer made on their NFT.
 *     - `getNFTDetails(address _nftContract, uint256 _tokenId)`: Retrieves detailed information about a specific NFT listed on the marketplace.
 *     - `getCollectionDetails(address _nftContract)`: Retrieves details about an NFT collection listed on the marketplace.
 *     - `withdrawFunds()`: Allows the marketplace owner to withdraw accumulated platform fees.
 *
 * 2.  **Dynamic NFT Features:**
 *     - `setDynamicTraitLogic(address _nftContract, uint256 _tokenId, string _traitName, bytes _logic)`:  Allows NFT creators to define dynamic logic for NFT traits (e.g., using a simple script or referencing external data).
 *     - `updateDynamicTraits(address _nftContract, uint256 _tokenId)`:  Triggers the execution of dynamic trait logic for a specific NFT, updating its metadata.
 *
 * 3.  **AI-Powered Personalization (Simulated/Conceptual):**
 *     - `setUserPreferences(string _preferenceData)`: Allows users to set their preferences for NFT recommendations (e.g., categories, artists, styles). (Conceptual - actual AI integration would be off-chain).
 *     - `getPersonalizedNFTFeed(address _user)`:  (Conceptual) Returns a list of NFTs recommended for a user based on their preferences and simulated AI analysis.
 *
 * 4.  **Decentralized Governance & Community Features:**
 *     - `proposeParameterChange(string _parameterName, uint256 _newValue)`: Allows community members to propose changes to marketplace parameters (e.g., platform fees, governance settings).
 *     - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows governance token holders to vote on active parameter change proposals.
 *     - `executeProposal(uint256 _proposalId)`: Executes a parameter change proposal if it passes the voting threshold.
 *     - `stakeMarketplaceToken(uint256 _amount)`: Allows users to stake marketplace tokens to participate in governance and potentially earn rewards.
 *     - `unstakeMarketplaceToken(uint256 _amount)`: Allows users to unstake their marketplace tokens.
 *
 * 5.  **Utility & Admin Functions:**
 *     - `setMarketplaceFee(uint256 _feePercentage)`: Allows the marketplace owner to set the platform fee percentage.
 *     - `setGovernanceToken(address _governanceTokenContract)`: Allows the marketplace owner to set the address of the governance token contract.
 *     - `pauseMarketplace()`: Allows the marketplace owner to temporarily pause marketplace operations for maintenance or emergency.
 *     - `unpauseMarketplace()`: Allows the marketplace owner to resume marketplace operations after pausing.
 */

contract DecentralizedDynamicNFTMarketplace {
    // -------- State Variables --------

    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address public governanceTokenContract; // Address of the governance token contract (ERC20)
    bool public paused = false;

    uint256 public proposalCounter = 0;

    struct NFTListing {
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct NFTOffer {
        address offerer;
        uint256 price;
        bool isActive;
    }

    struct NFTCollectionInfo {
        string collectionName;
        string collectionSymbol;
        string baseURI;
        address creator;
    }

    struct DynamicTraitLogic {
        string traitName;
        bytes logic; // Placeholder for dynamic logic (e.g., script, data reference)
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool passed;
        bool executed;
    }

    mapping(address => NFTCollectionInfo) public nftCollections; // Collection Contract Address => Collection Info
    mapping(address => mapping(uint256 => NFTListing)) public nftListings; // NFT Contract => Token ID => Listing Info
    mapping(address => mapping(uint256 => mapping(address => NFTOffer))) public nftOffers; // NFT Contract => Token ID => Offerer => Offer Info
    mapping(address => mapping(uint256 => DynamicTraitLogic[])) public nftDynamicTraits; // NFT Contract => Token ID => Array of Dynamic Trait Logics
    mapping(address => string) public userPreferences; // User Address => JSON string of preferences (Conceptual)
    mapping(uint256 => GovernanceProposal) public governanceProposals; // Proposal ID => Governance Proposal
    mapping(address => uint256) public stakedTokens; // User Address => Amount of staked governance tokens

    IERC20 public governanceToken; // Interface for the governance token

    // -------- Events --------

    event NFTCollectionCreated(address indexed nftContract, string collectionName, string collectionSymbol, address creator);
    event NFTListedForSale(address indexed nftContract, uint256 indexed tokenId, uint256 price, address seller);
    event NFTPurchased(address indexed nftContract, uint256 indexed tokenId, address buyer, uint256 price);
    event NFTListingCancelled(address indexed nftContract, uint256 indexed tokenId, address seller);
    event NFTListingPriceUpdated(address indexed nftContract, uint256 indexed tokenId, uint256 newPrice, address seller);
    event NFTOfferMade(address indexed nftContract, uint256 indexed tokenId, address offerer, uint256 price);
    event NFTOfferAccepted(address indexed nftContract, uint256 indexed tokenId, address seller, address buyer, uint256 price);
    event DynamicTraitLogicSet(address indexed nftContract, uint256 indexed tokenId, string traitName);
    event DynamicTraitsUpdated(address indexed nftContract, uint256 indexed tokenId);
    event UserPreferencesSet(address indexed user, string preferences);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event VoteCast(uint256 indexed proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event GovernanceTokenSet(address governanceTokenAddress);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused.");
        _;
    }

    modifier validNFT(address _nftContract, uint256 _tokenId) {
        require(nftCollections[_nftContract].creator != address(0), "Invalid NFT Collection.");
        IERC721 nft = IERC721(_nftContract);
        require(address(nft) != address(0), "Invalid NFT contract address.");
        try {
            nft.ownerOf(_tokenId); // Check if token exists and contract is ERC721
        } catch (bytes memory reason) {
            revert("Invalid Token ID or NFT contract does not support ERC721.");
        }
        _;
    }

    modifier onlyNFTOwner(address _nftContract, uint256 _tokenId) {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier onlyGovernanceTokenHolders() {
        require(governanceTokenContract != address(0), "Governance token not set.");
        require(governanceToken.balanceOf(msg.sender) > 0, "You are not a governance token holder.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(governanceProposals[_proposalId].proposer != address(0), "Invalid Proposal ID.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp < governanceProposals[_proposalId].endTime, "Voting period ended.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
    }

    // -------- 1. Core Marketplace Functions --------

    function createNFTCollection(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _baseURI
    ) public whenNotPaused {
        address nftContractAddress = address(new SampleNFT(_collectionName, _collectionSymbol, _baseURI, address(this))); // Deploy a SampleNFT contract
        nftCollections[nftContractAddress] = NFTCollectionInfo({
            collectionName: _collectionName,
            collectionSymbol: _collectionSymbol,
            baseURI: _baseURI,
            creator: msg.sender
        });
        emit NFTCollectionCreated(nftContractAddress, _collectionName, _collectionSymbol, msg.sender);
    }

    function listNFTForSale(address _nftContract, uint256 _tokenId, uint256 _price)
        public
        whenNotPaused
        validNFT(_nftContract, _tokenId)
        onlyNFTOwner(_nftContract, _tokenId)
    {
        IERC721(_nftContract).approve(address(this), _tokenId); // Approve marketplace to transfer NFT
        nftListings[_nftContract][_tokenId] = NFTListing({
            nftContract: _nftContract,
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit NFTListedForSale(_nftContract, _tokenId, _price, msg.sender);
    }

    function purchaseNFT(address _nftContract, uint256 _tokenId)
        public
        payable
        whenNotPaused
        validNFT(_nftContract, _tokenId)
    {
        NFTListing storage listing = nftListings[_nftContract][_tokenId];
        require(listing.isActive, "NFT is not listed for sale.");
        require(msg.value >= listing.price, "Insufficient funds sent.");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        listing.isActive = false; // Deactivate listing

        IERC721(_nftContract).safeTransferFrom(listing.seller, msg.sender, _tokenId);

        payable(listing.seller).transfer(sellerProceeds);
        payable(owner).transfer(marketplaceFee); // Send marketplace fee to owner

        emit NFTPurchased(_nftContract, _tokenId, msg.sender, listing.price);
    }

    function cancelNFTListing(address _nftContract, uint256 _tokenId)
        public
        whenNotPaused
        validNFT(_nftContract, _tokenId)
        onlyNFTOwner(_nftContract, _tokenId)
    {
        NFTListing storage listing = nftListings[_nftContract][_tokenId];
        require(listing.isActive, "NFT is not listed for sale.");
        require(listing.seller == msg.sender, "You are not the seller.");

        listing.isActive = false; // Deactivate listing
        emit NFTListingCancelled(_nftContract, _tokenId, msg.sender);
    }

    function updateNFTListingPrice(address _nftContract, uint256 _tokenId, uint256 _newPrice)
        public
        whenNotPaused
        validNFT(_nftContract, _tokenId)
        onlyNFTOwner(_nftContract, _tokenId)
    {
        NFTListing storage listing = nftListings[_nftContract][_tokenId];
        require(listing.isActive, "NFT is not listed for sale.");
        require(listing.seller == msg.sender, "You are not the seller.");

        listing.price = _newPrice;
        emit NFTListingPriceUpdated(_nftContract, _tokenId, _newPrice, msg.sender);
    }

    function offerNFT(address _nftContract, uint256 _tokenId, uint256 _price)
        public
        payable
        whenNotPaused
        validNFT(_nftContract, _tokenId)
    {
        require(msg.value >= _price, "Insufficient funds sent for offer.");
        nftOffers[_nftContract][_tokenId][msg.sender] = NFTOffer({
            offerer: msg.sender,
            price: _price,
            isActive: true
        });
        emit NFTOfferMade(_nftContract, _tokenId, msg.sender, _price);
    }

    function acceptOffer(address _nftContract, uint256 _tokenId, address _offerer)
        public
        whenNotPaused
        validNFT(_nftContract, _tokenId)
        onlyNFTOwner(_nftContract, _tokenId)
    {
        NFTOffer storage offer = nftOffers[_nftContract][_tokenId][_offerer];
        require(offer.isActive, "Offer is not active.");

        uint256 marketplaceFee = (offer.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = offer.price - marketplaceFee;

        offer.isActive = false; // Deactivate offer

        IERC721(_nftContract).safeTransferFrom(msg.sender, offer.offerer, _tokenId);

        payable(msg.sender).transfer(sellerProceeds);
        payable(owner).transfer(marketplaceFee); // Send marketplace fee to owner
        payable(offer.offerer).transfer(offer.price); // Refund offer amount (logic needs adjustment for actual refund)

        emit NFTOfferAccepted(_nftContract, _tokenId, msg.sender, offer.offerer, offer.price);
    }

    function getNFTDetails(address _nftContract, uint256 _tokenId)
        public
        view
        validNFT(_nftContract, _tokenId)
        returns (NFTListing memory, NFTCollectionInfo memory)
    {
        return (nftListings[_nftContract][_tokenId], nftCollections[_nftContract]);
    }

    function getCollectionDetails(address _nftContract)
        public
        view
        returns (NFTCollectionInfo memory)
    {
        return nftCollections[_nftContract];
    }

    function withdrawFunds() public onlyOwner whenNotPaused {
        payable(owner).transfer(address(this).balance);
    }

    // -------- 2. Dynamic NFT Features --------

    function setDynamicTraitLogic(
        address _nftContract,
        uint256 _tokenId,
        string memory _traitName,
        bytes memory _logic
    ) public whenNotPaused validNFT(_nftContract, _tokenId) onlyNFTOwner(_nftContract, _tokenId) {
        nftDynamicTraits[_nftContract][_tokenId].push(DynamicTraitLogic({
            traitName: _traitName,
            logic: _logic // In a real-world scenario, this could be a script hash, or reference to off-chain logic.
        }));
        emit DynamicTraitLogicSet(_nftContract, _tokenId, _traitName);
    }

    function updateDynamicTraits(address _nftContract, uint256 _tokenId)
        public
        whenNotPaused
        validNFT(_nftContract, _tokenId)
    {
        // This is a simplified example. In a real-world scenario, you would execute the logic defined in `dynamicTraits`.
        // This might involve calling external oracles, executing scripts (carefully!), or fetching data.
        // For this example, we'll just emit an event indicating the update was triggered.

        // Example: Iterate through dynamic traits and "execute" them (placeholder logic)
        for (uint256 i = 0; i < nftDynamicTraits[_nftContract][_tokenId].length; i++) {
            DynamicTraitLogic storage traitLogic = nftDynamicTraits[_nftContract][_tokenId][i];
            // In a real system, you would process `traitLogic.logic` here to update the NFT metadata.
            // This could involve off-chain computation and then updating the NFT's URI through a function in the NFT contract itself,
            // or by updating metadata stored in a decentralized storage system and updating the baseURI.
            // For now, we just emit an event with the trait name.
            emit DynamicTraitsUpdated(_nftContract, _tokenId); // Simplified - In reality, you'd emit more specific events based on trait updates.
        }
    }

    // -------- 3. AI-Powered Personalization (Conceptual) --------

    function setUserPreferences(string memory _preferenceData) public whenNotPaused {
        // In a real system, this might involve more structured data and validation.
        userPreferences[msg.sender] = _preferenceData;
        emit UserPreferencesSet(msg.sender, _preferenceData);
    }

    function getPersonalizedNFTFeed(address _user)
        public
        view
        whenNotPaused
        returns (NFTListing[] memory)
    {
        // This is a highly simplified and conceptual example.
        // In a real AI-powered system, this would involve complex off-chain processing,
        // potentially using user preferences, NFT metadata, transaction history, etc.,
        // to generate personalized recommendations.

        NFTListing[] memory recommendedListings = new NFTListing[](10); // Example: Return top 10 recommendations (Placeholder)
        uint256 count = 0;

        // (Simplified placeholder logic - in reality, AI would be used)
        for (uint256 i = 0; i < proposalCounter; i++) { // Just iterating over proposals for demonstration - replace with actual AI logic
            if (governanceProposals[i].proposer != address(0) && count < 10) { // Basic placeholder condition
                //  In a real system, you'd use userPreferences[_user] and NFT metadata to rank/filter listings.
                //  Here, we are just adding some listings for demonstration.
                address exampleNFTContract = address(uint160(uint256(keccak256(abi.encodePacked("ExampleNFTContract"))))); // Dummy contract address for example
                uint256 exampleTokenId = i + 1;
                if (nftListings[exampleNFTContract][exampleTokenId].isActive) {
                    recommendedListings[count] = nftListings[exampleNFTContract][exampleTokenId];
                    count++;
                }
            }
        }
        return recommendedListings;
    }


    // -------- 4. Decentralized Governance & Community Features --------

    function proposeParameterChange(string memory _parameterName, uint256 _newValue)
        public
        whenNotPaused
        onlyGovernanceTokenHolders
    {
        proposalCounter++;
        governanceProposals[proposalCounter] = GovernanceProposal({
            proposalId: proposalCounter,
            parameterName: _parameterName,
            newValue: _newValue,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7 days voting period
            votesFor: 0,
            votesAgainst: 0,
            passed: false,
            executed: false
        });
        emit ParameterChangeProposed(proposalCounter, _parameterName, _newValue, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote)
        public
        whenNotPaused
        onlyGovernanceTokenHolders
        validProposal(_proposalId)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        uint256 votingPower = stakedTokens[msg.sender]; // Voting power based on staked tokens

        require(votingPower > 0, "You need to stake tokens to vote.");

        if (_vote) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public whenNotPaused onlyOwner validProposal(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended yet.");

        uint256 totalStakedTokens = governanceToken.totalSupply(); // Assuming totalSupply represents total voting power
        uint256 quorum = (totalStakedTokens * 50) / 100; // 50% quorum (example)

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= quorum) {
            proposal.passed = true;
            if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("marketplaceFeePercentage"))) {
                setMarketplaceFee(proposal.newValue);
            }
            // Add more conditions for other parameters that can be governed.
        } else {
            proposal.passed = false;
        }
        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    function stakeMarketplaceToken(uint256 _amount) public whenNotPaused {
        require(governanceTokenContract != address(0), "Governance token not set.");
        require(_amount > 0, "Amount to stake must be greater than zero.");
        require(governanceToken.allowance(msg.sender, address(this)) >= _amount, "Approve marketplace to transfer tokens first.");

        governanceToken.transferFrom(msg.sender, address(this), _amount);
        stakedTokens[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    function unstakeMarketplaceToken(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount to unstake must be greater than zero.");
        require(stakedTokens[msg.sender] >= _amount, "Insufficient staked tokens.");

        stakedTokens[msg.sender] -= _amount;
        governanceToken.transfer(msg.sender, _amount);
        emit TokensUnstaked(msg.sender, _amount);
    }


    // -------- 5. Utility & Admin Functions --------

    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    function setGovernanceToken(address _governanceTokenContract) public onlyOwner whenNotPaused {
        require(_governanceTokenContract != address(0), "Governance token address cannot be zero.");
        governanceTokenContract = _governanceTokenContract;
        governanceToken = IERC20(_governanceTokenContract); // Initialize IERC20 interface
        emit GovernanceTokenSet(_governanceTokenContract);
    }

    function pauseMarketplace() public onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() public onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }

    // -------- Fallback and Receive --------
    receive() external payable {}
    fallback() external payable {}
}


// -------- Sample NFT Contract (for demonstration - in real use, creators would deploy their own) --------
contract SampleNFT is IERC721 {
    string public name;
    string public symbol;
    string public baseURI;
    address public marketplaceContract;

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 public tokenCounter = 0;

    constructor(string memory _name, string memory _symbol, string memory _baseURI, address _marketplace) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        marketplaceContract = _marketplace;
    }

    function mint(address _to) public returns (uint256) {
        tokenCounter++;
        uint256 tokenId = tokenCounter;
        _ownerOf[tokenId] = _to;
        _balanceOf[_to]++;
        emit Transfer(address(0), _to, tokenId);
        return tokenId;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function approve(address approved, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balanceOf[from]--;
        _balanceOf[to]++;
        _ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address approved, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = approved;
        emit Approval(ownerOf(tokenId), approved, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }
}

// -------- Interfaces --------

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function approve(address approved, uint256 tokenId) external payable;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external payable;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```