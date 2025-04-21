```solidity
/**
 * @title Decentralized Dynamic Art Marketplace - "Chameleon Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace where art pieces can evolve and change based on various on-chain and off-chain factors,
 *      incorporating governance, oracle integration, and advanced marketplace features.

 * **Outline and Function Summary:**

 * **Core Functionality (NFT & Marketplace):**
 * 1. `createDynamicNFT(string _name, string _description, string _initialMetadataURI, uint256[] _allowedDynamicTriggers)`: Allows artists to create dynamic NFTs with initial metadata and triggers for dynamic updates.
 * 2. `setDynamicRule(uint256 _tokenId, uint256 _triggerId, string _ruleDescription, bytes _ruleLogic)`: Artists define rules and logic for specific dynamic triggers for their NFTs.
 * 3. `updateNFTMetadata(uint256 _tokenId, string _newMetadataURI)`: Artists can manually update the base metadata URI of their NFT.
 * 4. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Owners list their NFTs for sale on the marketplace.
 * 5. `unlistNFT(uint256 _tokenId)`: Owners remove their NFTs from sale.
 * 6. `buyNFT(uint256 _tokenId)`: Buyers purchase NFTs listed on the marketplace.
 * 7. `offerNFT(uint256 _tokenId, uint256 _price)`: Buyers can make offers on NFTs not currently listed for sale.
 * 8. `acceptOffer(uint256 _offerId)`: NFT owners can accept specific offers made on their NFTs.
 * 9. `cancelOffer(uint256 _offerId)`: Buyers or sellers can cancel pending offers.

 * **Dynamic Trigger & Oracle Integration:**
 * 10. `registerDynamicTrigger(string _triggerName, string _triggerDescription)`: Marketplace admin registers new types of dynamic triggers (e.g., weather, stock price).
 * 11. `activateDynamicTrigger(uint256 _tokenId, uint256 _triggerId)`: Artists enable specific dynamic triggers for their NFTs.
 * 12. `deactivateDynamicTrigger(uint256 _tokenId, uint256 _triggerId)`: Artists disable dynamic triggers for their NFTs.
 * 13. `requestDynamicUpdate(uint256 _tokenId, uint256 _triggerId)`: (Oracle or external service) Requests a dynamic update for a specific NFT based on a trigger.
 * 14. `fulfillDynamicUpdate(uint256 _tokenId, uint256 _triggerId, string _newMetadataURI)`: (Oracle callback) Updates the NFT metadata URI based on the dynamic trigger result.

 * **Governance & Community Features:**
 * 15. `createGovernanceProposal(string _title, string _description, bytes _proposalData)`: Community members can create governance proposals.
 * 16. `voteOnProposal(uint256 _proposalId, bool _support)`: Token holders can vote on governance proposals.
 * 17. `executeProposal(uint256 _proposalId)`:  Admin (or timelock mechanism) executes approved governance proposals.
 * 18. `stakeTokensForGovernance(uint256 _amount)`: Users can stake platform tokens to participate in governance.
 * 19. `unstakeTokensForGovernance(uint256 _amount)`: Users can unstake their platform tokens.

 * **Utility & Admin Functions:**
 * 20. `setMarketplaceFee(uint256 _feePercentage)`: Marketplace admin can set the marketplace fee percentage.
 * 21. `withdrawMarketplaceFees()`: Marketplace admin can withdraw accumulated marketplace fees.
 * 22. `pauseMarketplace()`:  Marketplace admin can pause core marketplace functions in case of emergency.
 * 23. `unpauseMarketplace()`: Marketplace admin can resume marketplace functions.
 * 24. `setOracleAddress(address _oracleAddress)`: Marketplace admin sets the address of the trusted oracle contract.

 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ChameleonCanvas is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _offerIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _triggerIdCounter;

    // Marketplace fee percentage (e.g., 2% = 200)
    uint256 public marketplaceFeePercentage = 200;
    address payable public marketplaceFeeRecipient;

    // Mapping from token ID to current metadata URI
    mapping(uint256 => string) public tokenMetadataURIs;

    // Struct to define dynamic triggers
    struct DynamicTrigger {
        string name;
        string description;
        bool isActive; // Global trigger activation (admin controlled)
    }
    mapping(uint256 => DynamicTrigger) public dynamicTriggers;
    uint256[] public activeTriggerIds; // List of globally active trigger IDs

    // Struct to define dynamic rules for each NFT and trigger
    struct DynamicRule {
        string description;
        bytes ruleLogic; // Placeholder for more complex rule logic in the future
        bool isActive; // Artist controlled trigger activation for specific NFT
    }
    mapping(uint256 => mapping(uint256 => DynamicRule)) public nftDynamicRules; // tokenId => triggerId => Rule

    // Struct for marketplace listings
    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }
    mapping(uint256 => Listing) public nftListings;

    // Struct for offers
    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        uint256 price;
        address buyer;
        address seller; // Owner of the NFT when offer was made
        bool isActive;
    }
    mapping(uint256 => Offer) public nftOffers;
    mapping(uint256 => uint256[]) public tokenIdToOfferIds; // TokenId to list of active offer IDs

    // Governance Proposal Struct
    struct GovernanceProposal {
        uint256 proposalId;
        string title;
        string description;
        bytes proposalData; // Data related to the proposal (e.g., function call data)
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(address => bool) voters; // Keep track of who voted
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public proposalVoteDuration = 7 days; // Default proposal voting duration

    // Staking for governance
    mapping(address => uint256) public governanceStakes;
    IERC20 public governanceToken; // Address of the governance token contract

    address public oracleAddress; // Address of the trusted oracle contract

    event DynamicNFTCreated(uint256 tokenId, address artist, string name, string description, string initialMetadataURI);
    event DynamicRuleSet(uint256 tokenId, uint256 triggerId, string ruleDescription);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTUnlisted(uint256 tokenId, uint256 price, address seller);
    event NFTSold(uint256 tokenId, uint256 price, address seller, address buyer);
    event OfferMade(uint256 offerId, uint256 tokenId, uint256 price, address buyer, address seller);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address seller, address buyer);
    event OfferCancelled(uint256 offerId, uint256 tokenId, address canceller);
    event DynamicTriggerRegistered(uint256 triggerId, string triggerName, string triggerDescription);
    event DynamicTriggerActivatedForNFT(uint256 tokenId, uint256 triggerId);
    event DynamicTriggerDeactivatedForNFT(uint256 tokenId, uint256 triggerId);
    event DynamicUpdateRequestRequested(uint256 tokenId, uint256 triggerId, address requester);
    event DynamicUpdateFulfilled(uint256 tokenId, uint256 triggerId, string newMetadataURI);
    event GovernanceProposalCreated(uint256 proposalId, string title, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event TokensStakedForGovernance(address staker, uint256 amount);
    event TokensUnstakedForGovernance(address unstaker, uint256 amount);
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address recipient);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event OracleAddressSet(address oracle);

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle contract can call this function");
        _;
    }

    modifier onlyArtist(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved artist");
        _;
    }

    modifier onlyListed(uint256 _tokenId) {
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        _;
    }

    modifier onlyNotListed(uint256 _tokenId) {
        require(!nftListings[_tokenId].isListed, "NFT is already listed for sale");
        _;
    }

    modifier onlyActiveOffer(uint256 _offerId) {
        require(nftOffers[_offerId].isActive, "Offer is not active");
        _;
    }

    modifier onlyValidProposal(uint256 _proposalId) {
        require(governanceProposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID");
        require(block.timestamp < governanceProposals[_proposalId].endTime, "Voting period ended");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier onlyNotVoted(uint256 _proposalId) {
        require(!governanceProposals[_proposalId].voters[msg.sender], "Already voted on this proposal");
        _;
    }

    constructor(string memory _name, string memory _symbol, address _governanceTokenAddress, address payable _feeRecipient) ERC721(_name, _symbol) {
        marketplaceFeeRecipient = _feeRecipient;
        governanceToken = IERC20(_governanceTokenAddress);
    }

    /**
     * @dev Creates a new dynamic NFT.
     * @param _name The name of the NFT.
     * @param _description The description of the NFT.
     * @param _initialMetadataURI The initial metadata URI for the NFT.
     * @param _allowedDynamicTriggers Array of trigger IDs that can be used for this NFT.
     */
    function createDynamicNFT(
        string memory _name,
        string memory _description,
        string memory _initialMetadataURI,
        uint256[] memory _allowedDynamicTriggers
    ) public whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        tokenMetadataURIs[tokenId] = _initialMetadataURI;

        // Initialize allowed dynamic triggers (initially deactivated)
        for (uint256 i = 0; i < _allowedDynamicTriggers.length; i++) {
            uint256 triggerId = _allowedDynamicTriggers[i];
            require(dynamicTriggers[triggerId].isActive, "Trigger ID is not active or registered");
            nftDynamicRules[tokenId][triggerId].isActive = false; // Initially deactivated
        }

        emit DynamicNFTCreated(tokenId, msg.sender, _name, _description, _initialMetadataURI);
        return tokenId;
    }

    /**
     * @dev Sets a dynamic rule for a specific trigger for an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _triggerId The ID of the dynamic trigger.
     * @param _ruleDescription A description of the rule.
     * @param _ruleLogic Placeholder for rule logic (can be expanded in future versions).
     */
    function setDynamicRule(
        uint256 _tokenId,
        uint256 _triggerId,
        string memory _ruleDescription,
        bytes memory _ruleLogic
    ) public onlyArtist(_tokenId) whenNotPaused {
        require(dynamicTriggers[_triggerId].isActive, "Trigger ID is not active or registered");
        require(nftDynamicRules[_tokenId][_triggerId].isActive != true || nftDynamicRules[_tokenId][_triggerId].description == "", "Dynamic rule already set for this trigger, deactivate first."); // Prevent overwrite
        nftDynamicRules[_tokenId][_triggerId] = DynamicRule({
            description: _ruleDescription,
            ruleLogic: _ruleLogic,
            isActive: false // Initially inactive, artist needs to activate
        });
        emit DynamicRuleSet(_tokenId, _triggerId, _ruleDescription);
    }

    /**
     * @dev Updates the base metadata URI of an NFT manually.
     * @param _tokenId The ID of the NFT.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) public onlyArtist(_tokenId) whenNotPaused {
        tokenMetadataURIs[_tokenId] = _newMetadataURI;
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Returns the current token URI. Overrides ERC721 tokenURI to use dynamic metadata.
     * @param _tokenId The ID of the NFT.
     * @return The token URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenMetadataURIs[_tokenId];
    }

    /**
     * @dev Registers a new type of dynamic trigger. Only callable by marketplace admin.
     * @param _triggerName The name of the trigger.
     * @param _triggerDescription A description of the trigger.
     */
    function registerDynamicTrigger(string memory _triggerName, string memory _triggerDescription) public onlyOwner whenNotPaused {
        _triggerIdCounter.increment();
        uint256 triggerId = _triggerIdCounter.current();
        dynamicTriggers[triggerId] = DynamicTrigger({
            name: _triggerName,
            description: _triggerDescription,
            isActive: true // Newly registered triggers are active by default
        });
        activeTriggerIds.push(triggerId);
        emit DynamicTriggerRegistered(triggerId, _triggerName, _triggerDescription);
    }

    /**
     * @dev Activates a dynamic trigger for a specific NFT. Artist controlled.
     * @param _tokenId The ID of the NFT.
     * @param _triggerId The ID of the dynamic trigger to activate.
     */
    function activateDynamicTrigger(uint256 _tokenId, uint256 _triggerId) public onlyArtist(_tokenId) whenNotPaused {
        require(dynamicTriggers[_triggerId].isActive, "Trigger ID is not active or registered");
        require(nftDynamicRules[_tokenId][_triggerId].description != "", "Dynamic rule must be set before activating");
        nftDynamicRules[_tokenId][_triggerId].isActive = true;
        emit DynamicTriggerActivatedForNFT(_tokenId, _triggerId);
    }

    /**
     * @dev Deactivates a dynamic trigger for a specific NFT. Artist controlled.
     * @param _tokenId The ID of the NFT.
     * @param _triggerId The ID of the dynamic trigger to deactivate.
     */
    function deactivateDynamicTrigger(uint256 _tokenId, uint256 _triggerId) public onlyArtist(_tokenId) whenNotPaused {
        nftDynamicRules[_tokenId][_triggerId].isActive = false;
        emit DynamicTriggerDeactivatedForNFT(_tokenId, _triggerId);
    }

    /**
     * @dev Requests a dynamic update for a specific NFT and trigger. Callable by oracle or external service.
     * @param _tokenId The ID of the NFT to update.
     * @param _triggerId The ID of the dynamic trigger.
     */
    function requestDynamicUpdate(uint256 _tokenId, uint256 _triggerId) public onlyOracle whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(dynamicTriggers[_triggerId].isActive, "Trigger ID is not active or registered");
        require(nftDynamicRules[_tokenId][_triggerId].isActive, "Dynamic trigger is not activated for this NFT");
        emit DynamicUpdateRequestRequested(_tokenId, _triggerId, msg.sender);
        // In a real-world scenario, the oracle would perform off-chain logic based on _triggerId and call `fulfillDynamicUpdate`.
    }

    /**
     * @dev Fulfills a dynamic update by updating the NFT metadata URI. Callable by oracle only.
     * @param _tokenId The ID of the NFT.
     * @param _triggerId The ID of the dynamic trigger.
     * @param _newMetadataURI The new metadata URI to set for the NFT.
     */
    function fulfillDynamicUpdate(uint256 _tokenId, uint256 _triggerId, string memory _newMetadataURI) public onlyOracle whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(dynamicTriggers[_triggerId].isActive, "Trigger ID is not active or registered");
        require(nftDynamicRules[_tokenId][_triggerId].isActive, "Dynamic trigger is not activated for this NFT");
        tokenMetadataURIs[_tokenId] = _newMetadataURI;
        emit DynamicUpdateFulfilled(_tokenId, _triggerId, _newMetadataURI);
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI); // Emit generic metadata update event as well
    }

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in native currency (e.g., ETH).
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public onlyArtist(_tokenId) onlyNotListed(_tokenId) whenNotPaused {
        require(_price > 0, "Price must be greater than zero");
        nftListings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });
        emit NFTListed(_tokenId, _price, msg.sender);
    }

    /**
     * @dev Unlists an NFT from sale on the marketplace.
     * @param _tokenId The ID of the NFT to unlist.
     */
    function unlistNFT(uint256 _tokenId) public onlyArtist(_tokenId) onlyListed(_tokenId) whenNotPaused {
        nftListings[_tokenId].isListed = false;
        emit NFTUnlisted(_tokenId, nftListings[_tokenId].price, msg.sender);
    }

    /**
     * @dev Buys an NFT listed on the marketplace.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyNFT(uint256 _tokenId) public payable onlyListed(_tokenId) whenNotPaused {
        Listing memory listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds sent");

        uint256 feeAmount = listing.price.mul(marketplaceFeePercentage).div(10000); // Calculate fee
        uint256 sellerAmount = listing.price.sub(feeAmount);

        // Transfer funds
        payable(listing.seller).transfer(sellerAmount);
        marketplaceFeeRecipient.transfer(feeAmount);

        // Transfer NFT
        _transfer(listing.seller, msg.sender, _tokenId);

        // Clear listing
        nftListings[_tokenId].isListed = false;

        emit NFTSold(_tokenId, listing.price, listing.seller, msg.sender);
    }

    /**
     * @dev Allows a buyer to make an offer on an NFT that is not listed for sale.
     * @param _tokenId The ID of the NFT.
     * @param _price The offer price in native currency (e.g., ETH).
     */
    function offerNFT(uint256 _tokenId, uint256 _price) public payable whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(msg.value >= _price, "Insufficient funds sent for offer");
        require(_price > 0, "Offer price must be greater than zero");

        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();

        nftOffers[offerId] = Offer({
            offerId: offerId,
            tokenId: _tokenId,
            price: _price,
            buyer: msg.sender,
            seller: ownerOf(_tokenId),
            isActive: true
        });
        tokenIdToOfferIds[_tokenId].push(offerId);

        emit OfferMade(offerId, _tokenId, _price, msg.sender, ownerOf(_tokenId));
    }

    /**
     * @dev Allows the NFT owner to accept a specific offer.
     * @param _offerId The ID of the offer to accept.
     */
    function acceptOffer(uint256 _offerId) public onlyActiveOffer(_offerId) whenNotPaused {
        Offer storage offer = nftOffers[_offerId];
        require(ownerOf(offer.tokenId) == msg.sender, "Only NFT owner can accept offers");

        uint256 feeAmount = offer.price.mul(marketplaceFeePercentage).div(10000); // Calculate fee
        uint256 sellerAmount = offer.price.sub(feeAmount);

        // Transfer funds
        payable(offer.seller).transfer(sellerAmount);
        marketplaceFeeRecipient.transfer(feeAmount);

        // Transfer NFT
        _transfer(offer.seller, offer.buyer, offer.tokenId);

        // Deactivate offer
        offer.isActive = false;

        emit OfferAccepted(_offerId, offer.tokenId, offer.seller, offer.buyer);
    }

    /**
     * @dev Allows the buyer or seller to cancel an active offer.
     * @param _offerId The ID of the offer to cancel.
     */
    function cancelOffer(uint256 _offerId) public onlyActiveOffer(_offerId) whenNotPaused {
        Offer storage offer = nftOffers[_offerId];
        require(msg.sender == offer.buyer || ownerOf(offer.tokenId) == msg.sender, "Only buyer or seller can cancel offer");

        offer.isActive = false;
        emit OfferCancelled(_offerId, offer.tokenId, msg.sender);
    }


    /**
     * @dev Creates a new governance proposal.
     * @param _title Title of the proposal.
     * @param _description Description of the proposal.
     * @param _proposalData Data associated with the proposal (e.g., function call data).
     */
    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _proposalData) public whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            title: _title,
            description: _description,
            proposalData: _proposalData,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVoteDuration,
            executed: false
        });
        emit GovernanceProposalCreated(proposalId, _title, _description, msg.sender);
    }

    /**
     * @dev Allows token holders to vote on a governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "For" vote, false for "Against".
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyValidProposal(_proposalId) onlyNotVoted(_proposalId) whenNotPaused {
        require(governanceStakes[msg.sender] > 0, "Must stake governance tokens to vote"); // Require staking to vote

        governanceProposals[_proposalId].voters[msg.sender] = true; // Mark voter as voted
        if (_support) {
            governanceProposals[_proposalId].votesFor += governanceStakes[msg.sender];
        } else {
            governanceProposals[_proposalId].votesAgainst += governanceStakes[msg.sender];
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a governance proposal if it passes. Only callable after voting period ends and by admin (or timelock).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused {
        require(governanceProposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID");
        require(block.timestamp >= governanceProposals[_proposalId].endTime, "Voting period not ended");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed");

        uint256 totalStakedTokens = governanceToken.totalSupply(); // Assuming total supply represents total voting power for simplicity
        uint256 quorum = totalStakedTokens.mul(51).div(100); // 51% quorum for simplicity

        require(governanceProposals[_proposalId].votesFor > governanceProposals[_proposalId].votesAgainst && governanceProposals[_proposalId].votesFor >= quorum, "Proposal not approved");

        (bool success, ) = address(this).call(governanceProposals[_proposalId].proposalData); // Execute proposal data
        require(success, "Proposal execution failed");

        governanceProposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows users to stake governance tokens to participate in governance.
     * @param _amount The amount of governance tokens to stake.
     */
    function stakeTokensForGovernance(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Stake amount must be greater than zero");
        governanceToken.transferFrom(msg.sender, address(this), _amount);
        governanceStakes[msg.sender] += _amount;
        emit TokensStakedForGovernance(msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake governance tokens.
     * @param _amount The amount of governance tokens to unstake.
     */
    function unstakeTokensForGovernance(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(governanceStakes[msg.sender] >= _amount, "Insufficient staked tokens");
        governanceStakes[msg.sender] -= _amount;
        governanceToken.transfer(msg.sender, _amount);
        emit TokensUnstakedForGovernance(msg.sender, _amount);
    }

    /**
     * @dev Sets the marketplace fee percentage. Only callable by marketplace admin.
     * @param _feePercentage The fee percentage (e.g., 200 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%"); // Max 100% fee
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @dev Allows the marketplace admin to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 contractGovernanceTokenBalance = governanceToken.balanceOf(address(this)); // Prevent accidental governance token withdrawal
        uint256 withdrawableBalance = balance.sub(contractGovernanceTokenBalance); // Withdraw only ETH balance

        require(withdrawableBalance > 0, "No marketplace fees to withdraw");
        marketplaceFeeRecipient.transfer(withdrawableBalance);
        emit MarketplaceFeesWithdrawn(withdrawableBalance, marketplaceFeeRecipient);
    }

    /**
     * @dev Pauses the marketplace, preventing core marketplace functions. Only callable by marketplace admin.
     */
    function pauseMarketplace() public onlyOwner whenNotPaused {
        _pause();
        emit MarketplacePaused();
    }

    /**
     * @dev Unpauses the marketplace, resuming core marketplace functions. Only callable by marketplace admin.
     */
    function unpauseMarketplace() public onlyOwner whenPaused {
        _unpause();
        emit MarketplaceUnpaused();
    }

    /**
     * @dev Sets the address of the trusted oracle contract. Only callable by marketplace admin.
     * @param _oracleAddress The address of the oracle contract.
     */
    function setOracleAddress(address _oracleAddress) public onlyOwner whenNotPaused {
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /**
     * @dev Function to receive native currency (ETH) for buying NFTs and making offers.
     */
    receive() external payable {}

    /**
     * @dev Fallback function to reject direct ETH sends to the contract (unless for buying/offering).
     */
    fallback() external payable {
        revert("Direct ETH sends not allowed. Use buyNFT or offerNFT functions.");
    }
}
```