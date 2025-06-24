Okay, here is a Solidity smart contract concept called "CryptoEstate" that combines elements of NFTs, fractional ownership (via dynamically deployed ERC20 tokens), governance, and yield distribution, representing tokenized real-world or virtual properties.

This contract aims to be creative by integrating:
1.  **NFTs (ERC721):** Each unique property is an NFT.
2.  **Fractional Ownership (Dynamic ERC20s):** For each property NFT, a *new* dedicated ERC20 token is deployed, representing shares in that specific property. This is a key advanced concept, as contracts typically don't deploy other contracts *per instance* like this. (Note: Directly deploying dynamic contracts in Solidity is possible using `new ContractName()`, but the deployed contract code must be available at compile time or via a factory. For this example, we'll include a simplified internal ERC20 contract).
3.  **Yield Distribution (Pull Pattern):** Owners of fractional tokens can claim their share of deposited rent.
4.  **Governance:** Fractional owners can vote on property-specific proposals (e.g., improvements, rent changes).
5.  **Dynamic State:** Properties can have mutable values, rent amounts, and maintenance logs.
6.  **Internal Marketplace (Simple):** Basic functions to list and buy fractional shares.

It avoids duplicating a single standard template (like just an ERC721, ERC20, or a generic DAO) by weaving these concepts together into a domain-specific application.

**Disclaimer:** This is a complex concept for a single contract and is provided for illustrative purposes. A production system would require extensive auditing, gas optimization, more robust error handling, and potentially a factory pattern for ERC20 deployment instead of embedding the code. Interacting with deployed ERC20s dynamically adds complexity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Used as base for the internal fractional token
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// --- OUTLINE ---
// 1. Core ERC721 for Properties
// 2. Internal ERC20 for Fractional Shares (deployed dynamically per property)
// 3. Property Data Storage & Management
// 4. Fractionalization Logic (Deploying ERC20, Issuing Shares)
// 5. Rent/Yield Distribution Logic (Deposit & Claim)
// 6. Dynamic Property State Updates (Value, Maintenance)
// 7. Governance System (Proposals, Voting, Execution for Fractional Owners)
// 8. Simple Internal Fractional Share Marketplace
// 9. Platform Fee Collection
// 10. Utility Functions (Getters for data)
// 11. Access Control & Security (Ownable, ReentrancyGuard, Modifiers)

// --- FUNCTION SUMMARY ---
// Core ERC721 Functions (inherited/standard, but counted):
// - balanceOf(address owner): Get number of properties owned by an address.
// - ownerOf(uint256 tokenId): Get owner of a specific property NFT.
// - safeTransferFrom(address from, address to, uint256 tokenId): Safely transfer property NFT.
// - transferFrom(address from, address to, uint256 tokenId): Transfer property NFT.
// - approve(address to, uint256 tokenId): Approve address to manage property NFT.
// - setApprovalForAll(address operator, bool approved): Approve operator for all properties.
// - getApproved(uint256 tokenId): Get approved address for a property NFT.
// - isApprovedForAll(address owner, address operator): Check if operator is approved for all.

// Custom CryptoEstate Functions:
// 1. constructor(string memory name, string memory symbol): Deploys the contract, sets NFT name/symbol.
// 2. mintProperty(string memory location, uint256 initialValue, uint256 initialRentPerPeriod, address initialManager): Mints a new property NFT.
// 3. deactivateProperty(uint256 propertyId): Deactivates a property NFT (e.g., if real-world asset is sold off-chain). Cannot be fractionalized/managed further.
// 4. setPropertyManager(uint256 propertyId, address manager): Sets the address responsible for managing a property (can log costs, update value, etc.).
// 5. updatePropertyValue(uint256 propertyId, uint256 newValue): Updates the simulated value of a property.
// 6. logMaintenanceCost(uint256 propertyId, uint256 cost): Records a maintenance cost against a property.
// 7. fractionalizeProperty(uint256 propertyId, uint256 totalShares, string memory tokenName, string memory tokenSymbol): Deploys a new ERC20 contract for the property and marks it as fractionalized. (Requires property NFT to be held by this contract).
// 8. issueInitialFractionalShares(uint256 propertyId, address recipient): Issues the initial total supply of fractional shares to the specified recipient (typically the minter/owner).
// 9. getFractionalTokenAddress(uint256 propertyId): Get the address of the deployed fractional ERC20 token for a property.
// 10. depositRent(uint256 propertyId) payable: Allows depositing rent funds for a specific property.
// 11. claimRent(uint256 propertyId): Allows fractional token holders to claim their proportional share of deposited rent.
// 12. getClaimableRent(uint256 propertyId, address holder): Calculate the amount of rent a holder can claim for a property.
// 13. listFractionalShares(uint256 propertyId, uint256 amount, uint256 pricePerShare): Lists a specific amount of fractional shares of a property for sale internally.
// 14. buyFractionalShares(uint256 propertyId, address seller, uint256 amount) payable: Allows buying listed fractional shares.
// 15. cancelFractionalListing(uint256 propertyId, uint256 amount): Cancels a previously listed amount of fractional shares.
// 16. getFractionalListing(uint256 propertyId, address seller): Gets the details of a seller's active fractional share listing for a property.
// 17. createImprovementProposal(uint256 propertyId, string memory description, uint256 cost, uint256 votingDurationBlocks, uint256 requiredMajorityBps): Creates a proposal for a property improvement.
// 18. createRentChangeProposal(uint256 propertyId, string memory description, uint256 newRentPerPeriod, uint256 votingDurationBlocks, uint256 requiredMajorityBps): Creates a proposal to change a property's rent.
// 19. voteOnProposal(uint256 propertyId, uint256 proposalId, bool support): Allows fractional token holders to vote on a proposal. Vote weight based on fractional token balance.
// 20. executeImprovementProposal(uint256 propertyId, uint256 proposalId): Executes an approved improvement proposal (requires funds to be available).
// 21. executeRentChangeProposal(uint256 propertyId, uint256 proposalId): Executes an approved rent change proposal.
// 22. getProposalDetails(uint256 propertyId, uint256 proposalId): Get details of a specific proposal.
// 23. getActiveProposals(uint256 propertyId): Get a list of active proposal IDs for a property.
// 24. setPlatformFee(uint256 feeBps): Sets the platform fee percentage (in basis points) on rent distribution and fractional share sales.
// 25. withdrawFees(): Allows the contract owner to withdraw accumulated platform fees.
// 26. getPropertyDetails(uint256 propertyId): Get comprehensive details of a property.
// 27. getPropertyRentInfo(uint256 propertyId): Get rent-specific information for a property.


contract CryptoEstate is ERC721, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- Events ---
    event PropertyMinted(uint256 indexed propertyId, address indexed minter, string location, uint256 initialValue);
    event PropertyDeactivated(uint256 indexed propertyId);
    event PropertyManagerUpdated(uint256 indexed propertyId, address indexed newManager);
    event PropertyValueUpdated(uint256 indexed propertyId, uint256 newValue);
    event MaintenanceCostLogged(uint256 indexed propertyId, uint256 cost);
    event PropertyFractionalized(uint256 indexed propertyId, address indexed fractionalTokenAddress, uint256 totalShares);
    event RentDeposited(uint256 indexed propertyId, address indexed depositor, uint256 amount);
    event RentClaimed(uint256 indexed propertyId, address indexed claimant, uint256 amount);
    event FractionalSharesListed(uint256 indexed propertyId, address indexed seller, uint256 amount, uint256 pricePerShare);
    event FractionalSharesBought(uint256 indexed propertyId, address indexed buyer, address indexed seller, uint256 amount, uint256 totalPrice);
    event FractionalListingCancelled(uint256 indexed propertyId, address indexed seller, uint256 cancelledAmount);
    event ProposalCreated(uint256 indexed propertyId, uint256 indexed proposalId, uint256 indexed proposer, ProposalType proposalType, string description, uint256 votingDeadline);
    event Voted(uint256 indexed propertyId, uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed propertyId, uint256 indexed proposalId);
    event PlatformFeeUpdated(uint256 newFeeBps);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Structs & Enums ---

    struct Property {
        string location;
        uint256 initialValue;
        uint256 currentValue; // Can be updated
        uint256 rentPerPeriod; // Rent amount for a defined period (e.g., month)
        address propertyManager; // Address authorized to manage updates/logs
        bool isFractionalized;
        address fractionalToken; // Address of the dedicated ERC20 token for this property
        bool isActive; // Can be deactivated (e.g., off-chain sale)
        uint256 maintenanceCostLogged; // Accumulated maintenance costs
    }

    struct FractionalListing {
        uint256 amount; // Amount of shares listed
        uint256 pricePerShare; // Price per share in wei
    }

    enum ProposalType {
        Improvement,
        RentChange
    }

    struct Proposal {
        address proposer;
        ProposalType proposalType;
        string description;
        uint256 creationBlock; // Block number when created for snapshot voting
        uint256 votingDeadlineBlock;
        uint256 requiredMajorityBps; // Basis points (e.g., 5000 for 50%)
        mapping(address => bool) hasVoted; // Track who voted
        uint256 yayVotes; // Total vote weight (based on fractional tokens)
        uint256 nayVotes; // Total vote weight
        bool executed;
        bool cancelled;
        // Proposal-specific data
        uint256 improvementCost; // For Improvement proposals
        uint256 newRentPerPeriod; // For RentChange proposals
    }

    // --- State Variables ---

    uint256 private _propertyCounter;
    uint256 private _proposalCounter;
    uint256 public platformFeeBps; // Platform fee in basis points (e.g., 100 = 1%)

    mapping(uint256 => Property) public properties;
    mapping(uint256 => mapping(address => uint256)) private _claimedRent; // propertyId => holder => amountClaimed

    // Fractional Share Listings: propertyId => seller => listing
    mapping(uint256 => mapping(address => FractionalListing)) public fractionalListings;

    // Governance: propertyId => proposalId => Proposal
    mapping(uint256 => mapping(uint256 => Proposal)) public proposals;
    mapping(uint256 => EnumerableSet.UintSet) private _activeProposals; // propertyId => set of active proposal IDs

    // Collected fees from sales/rent
    uint256 public totalCollectedFees;

    // --- Modifiers ---

    modifier onlyPropertyActive(uint256 propertyId) {
        require(properties[propertyId].isActive, "Property is not active");
        _;
    }

    modifier onlyPropertyManager(uint256 propertyId) {
        require(msg.sender == properties[propertyId].propertyManager || msg.sender == ownerOf(propertyId), "Caller is not the property manager or owner");
        _;
    }

    modifier onlyFractionalTokenHolder(uint256 propertyId) {
        require(properties[propertyId].isFractionalized, "Property is not fractionalized");
        IERC20 fractionalToken = IERC20(properties[propertyId].fractionalToken);
        require(fractionalToken.balanceOf(msg.sender) > 0, "Caller is not a fractional token holder");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        platformFeeBps = 100; // Default 1% fee
    }

    // --- Core Property Management (NFT) ---

    /// @notice Mints a new unique property NFT.
    /// @param location Descriptive location/identifier for the property.
    /// @param initialValue The initial estimated value of the property in wei.
    /// @param initialRentPerPeriod The initial rent amount expected per defined period (e.g., month) in wei.
    /// @param initialManager The address responsible for initial management updates.
    /// @return The ID of the newly minted property NFT.
    function mintProperty(
        string memory location,
        uint256 initialValue,
        uint256 initialRentPerPeriod,
        address initialManager
    ) public onlyOwner returns (uint256) {
        _propertyCounter++;
        uint256 newItemId = _propertyCounter;

        _safeMint(msg.sender, newItemId);

        properties[newItemId] = Property({
            location: location,
            initialValue: initialValue,
            currentValue: initialValue,
            rentPerPeriod: initialRentPerPeriod,
            propertyManager: initialManager,
            isFractionalized: false,
            fractionalToken: address(0),
            isActive: true,
            maintenanceCostLogged: 0
        });

        emit PropertyMinted(newItemId, msg.sender, location, initialValue);
        return newItemId;
    }

    /// @notice Deactivates a property NFT. Used if the corresponding real-world asset is sold off-chain, for example.
    /// @param propertyId The ID of the property to deactivate.
    function deactivateProperty(uint256 propertyId) public onlyPropertyActive(propertyId) onlyPropertyManager(propertyId) {
        properties[propertyId].isActive = false;
        // Potential logic: Handle outstanding rent, close proposals, etc. (Simplified for this example)
        // If fractionalized, maybe prevent further transfers of fractional tokens? Or burn them?
        // Burning the NFT would also be an option: _burn(propertyId);
        emit PropertyDeactivated(propertyId);
    }

    /// @notice Sets or updates the property manager for a property.
    /// @param propertyId The ID of the property.
    /// @param manager The new property manager address.
    function setPropertyManager(uint256 propertyId, address manager) public onlyPropertyActive(propertyId) nonReentrant {
         require(msg.sender == properties[propertyId].propertyManager || msg.sender == ownerOf(propertyId), "Only current manager or owner can set new manager");
        properties[propertyId].propertyManager = manager;
        emit PropertyManagerUpdated(propertyId, manager);
    }

    /// @notice Updates the simulated current value of a property.
    /// @param propertyId The ID of the property.
    /// @param newValue The new simulated value in wei.
    function updatePropertyValue(uint256 propertyId, uint256 newValue) public onlyPropertyActive(propertyId) onlyPropertyManager(propertyId) {
        properties[propertyId].currentValue = newValue;
        emit PropertyValueUpdated(propertyId, newValue);
    }

    /// @notice Logs a maintenance cost incurred for a property.
    /// @param propertyId The ID of the property.
    /// @param cost The cost incurred in wei.
    function logMaintenanceCost(uint256 propertyId, uint256 cost) public onlyPropertyActive(propertyId) onlyPropertyManager(propertyId) {
        properties[propertyId].maintenanceCostLogged += cost;
        emit MaintenanceCostLogged(propertyId, cost);
    }

    // --- Fractionalization ---

    /// @notice Fractionalizes a property by deploying a new dedicated ERC20 token for it.
    /// Requires the property NFT to be sent to *this* contract's address first (`safeTransferFrom`).
    /// @param propertyId The ID of the property to fractionalize.
    /// @param totalShares The total supply of fractional shares for this property.
    /// @param tokenName Name for the fractional ERC20 token (e.g., "Property 1 Shares").
    /// @param tokenSymbol Symbol for the fractional ERC20 token (e.g., "PROP1").
    function fractionalizeProperty(
        uint256 propertyId,
        uint256 totalShares,
        string memory tokenName,
        string memory tokenSymbol
    ) public nonReentrant {
        Property storage property = properties[propertyId];
        require(property.isActive, "Property is not active");
        require(!property.isFractionalized, "Property is already fractionalized");
        require(ownerOf(propertyId) == address(this), "Contract must own the property NFT to fractionalize it");
        require(totalShares > 0, "Total shares must be positive");

        // Deploy the dedicated ERC20 contract for this property
        // NOTE: This requires the CryptoEstateFractionalToken contract code to be available.
        // In a real scenario, you might use a factory or pre-deploy templates.
        // For simplicity, let's define it internally or assume it's callable.
        // We'll embed a minimal version for this example.
        CryptoEstateFractionalToken fractionalToken = new CryptoEstateFractionalToken(
            tokenName,
            tokenSymbol,
            totalShares,
            address(this), // The CryptoEstate contract
            propertyId
        );

        property.isFractionalized = true;
        property.fractionalToken = address(fractionalToken);

        emit PropertyFractionalized(propertyId, address(fractionalToken), totalShares);
    }

     /// @notice Issues the initial total supply of fractional shares to a recipient after fractionalization.
     /// @param propertyId The ID of the fractionalized property.
     /// @param recipient The address to receive the initial shares.
    function issueInitialFractionalShares(uint256 propertyId, address recipient) public nonReentrant {
        Property storage property = properties[propertyId];
        require(property.isFractionalized, "Property is not fractionalized");
        require(ownerOf(propertyId) == address(this), "Contract must own the property NFT"); // Should be true if fractionalized
        require(recipient != address(0), "Recipient cannot be zero address");

        IERC20 fractionalToken = IERC20(property.fractionalToken);
        // The fractional token contract should have a minting function callable only by this contract
        // In CryptoEstateFractionalToken constructor, initial supply is minted to THIS contract.
        // We need to transfer it FROM this contract TO the recipient.
        require(fractionalToken.balanceOf(address(this)) > 0, "Initial shares not available in contract");

        uint256 initialSupply = fractionalToken.balanceOf(address(this));
        fractionalToken.safeTransfer(recipient, initialSupply);
    }


    /// @notice Gets the address of the deployed fractional ERC20 token for a property.
    /// @param propertyId The ID of the property.
    /// @return The address of the fractional token contract, or address(0) if not fractionalized.
    function getFractionalTokenAddress(uint256 propertyId) public view returns (address) {
        return properties[propertyId].fractionalToken;
    }

    // --- Rent/Yield Distribution (Pull Pattern) ---

    /// @notice Allows anyone to deposit rent funds for a specific property.
    /// The deposited ETH is held by the main CryptoEstate contract.
    /// @param propertyId The ID of the property.
    function depositRent(uint256 propertyId) public payable onlyPropertyActive(propertyId) nonReentrant {
        require(properties[propertyId].isFractionalized, "Property must be fractionalized to deposit rent");
        require(msg.value > 0, "Must send positive amount of ETH");

        // Funds are held by this contract until claimed

        emit RentDeposited(propertyId, msg.sender, msg.value);
    }

    /// @notice Allows fractional token holders to claim their proportional share of deposited rent.
    /// This is a pull mechanism. The amount is calculated based on their current fractional token balance
    /// relative to the total supply and how much they have already claimed.
    /// @param propertyId The ID of the property.
    function claimRent(uint256 propertyId) public onlyPropertyActive(propertyId) onlyFractionalTokenHolder(propertyId) nonReentrant {
        IERC20 fractionalToken = IERC20(properties[propertyId].fractionalToken);
        require(address(fractionalToken) != address(0), "Fractional token not set");

        uint256 claimableAmount = _calculateClaimableRent(propertyId, msg.sender);
        require(claimableAmount > 0, "No claimable rent");

        _claimedRent[propertyId][msg.sender] += claimableAmount;

        // Apply platform fee
        uint256 feeAmount = (claimableAmount * platformFeeBps) / 10000;
        uint256 amountToSend = claimableAmount - feeAmount;

        totalCollectedFees += feeAmount;

        (bool success, ) = payable(msg.sender).call{value: amountToSend}("");
        require(success, "ETH transfer failed");

        emit RentClaimed(propertyId, msg.sender, amountToSend);
    }

    /// @notice Calculates the amount of rent a holder can claim for a property.
    /// @param propertyId The ID of the property.
    /// @param holder The address of the fractional token holder.
    /// @return The amount of claimable rent in wei.
    function getClaimableRent(uint256 propertyId, address holder) public view returns (uint256) {
         require(properties[propertyId].isFractionalized, "Property is not fractionalized");
         return _calculateClaimableRent(propertyId, holder);
    }

    /// @dev Internal helper to calculate claimable rent.
    function _calculateClaimableRent(uint256 propertyId, address holder) internal view returns (uint256) {
         require(properties[propertyId].isFractionalized, "Property is not fractionalized");
         IERC20 fractionalToken = IERC20(properties[propertyId].fractionalToken);
         uint256 holderBalance = fractionalToken.balanceOf(holder);
         uint256 totalSupply = fractionalToken.totalSupply();

         if (totalSupply == 0) { // Should not happen if property is fractionalized
             return 0;
         }

         uint256 totalRentReceived = address(this).balance; // This is a simplification - ideally, track rent received *per property*
         // A more complex system would track deposits per property using a separate balance mapping or events.
         // For this example, let's assume all ETH balance is claimable rent, divided proportionally.

         uint256 totalClaimableByAll = totalRentReceived; // Simplified
         uint256 holderShare = (totalClaimableByAll * holderBalance) / totalSupply;

         // Subtract already claimed amount
         return holderShare > _claimedRent[propertyId][holder] ? holderShare - _claimedRent[propertyId][holder] : 0;
    }

    // --- Simple Internal Fractional Share Marketplace ---

    /// @notice Lists a specific amount of fractional shares of a property for sale internally.
    /// Requires the seller to approve this contract to spend the fractional tokens.
    /// @param propertyId The ID of the property.
    /// @param amount The number of fractional shares to list.
    /// @param pricePerShare The price per share in wei.
    function listFractionalShares(uint256 propertyId, uint256 amount, uint256 pricePerShare) public onlyPropertyActive(propertyId) nonReentrant {
        Property storage property = properties[propertyId];
        require(property.isFractionalized, "Property is not fractionalized");
        require(amount > 0, "Amount must be positive");
        require(pricePerShare > 0, "Price per share must be positive");

        IERC20 fractionalToken = IERC20(property.fractionalToken);
        require(fractionalToken.balanceOf(msg.sender) >= amount, "Insufficient fractional token balance");
        // Check allowance (user must approve this contract to spend)
        require(fractionalToken.allowance(msg.sender, address(this)) >= amount, "Must approve contract to spend fractional tokens");

        fractionalListings[propertyId][msg.sender] = FractionalListing({
            amount: amount,
            pricePerShare: pricePerShare
        });

        emit FractionalSharesListed(propertyId, msg.sender, amount, pricePerShare);
    }

    /// @notice Allows buying listed fractional shares.
    /// Sends ETH to the seller (minus fee) and transfers fractional tokens from seller to buyer.
    /// @param propertyId The ID of the property.
    /// @param seller The address of the seller.
    /// @param amount The number of fractional shares to buy.
    function buyFractionalShares(uint256 propertyId, address seller, uint256 amount) public payable onlyPropertyActive(propertyId) nonReentrant {
        Property storage property = properties[propertyId];
        require(property.isFractionalized, "Property is not fractionalized");
        require(amount > 0, "Amount must be positive");
        require(seller != address(0) && seller != msg.sender, "Invalid seller address");

        FractionalListing storage listing = fractionalListings[propertyId][seller];
        require(listing.amount >= amount, "Insufficient shares listed");
        require(listing.pricePerShare > 0, "Listing price is zero");

        uint256 totalPrice = amount * listing.pricePerShare;
        require(msg.value >= totalPrice, "Insufficient ETH sent");

        IERC20 fractionalToken = IERC20(property.fractionalToken);
        // Transfer fractional tokens from seller (via allowance) to buyer
        fractionalToken.safeTransferFrom(seller, msg.sender, amount);

        // Handle payment to seller, apply fee
        uint256 feeAmount = (totalPrice * platformFeeBps) / 10000;
        uint256 amountToSeller = totalPrice - feeAmount;
        totalCollectedFees += feeAmount;

        if (amountToSeller > 0) {
             (bool success, ) = payable(seller).call{value: amountToSeller}("");
             require(success, "ETH transfer to seller failed");
        }

        // Update listing amount
        listing.amount -= amount;
        if (listing.amount == 0) {
            delete fractionalListings[propertyId][seller]; // Remove listing if all bought
        }

        // Refund any excess ETH sent by buyer
        if (msg.value > totalPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
            require(success, "ETH refund failed");
        }

        emit FractionalSharesBought(propertyId, msg.sender, seller, amount, totalPrice);
    }

    /// @notice Cancels a previously listed amount of fractional shares.
    /// @param propertyId The ID of the property.
    /// @param amount The number of fractional shares to cancel from the listing.
    function cancelFractionalListing(uint256 propertyId, uint256 amount) public onlyPropertyActive(propertyId) nonReentrant {
        FractionalListing storage listing = fractionalListings[propertyId][msg.sender];
        require(listing.amount >= amount, "Amount to cancel exceeds listed amount");
        require(amount > 0, "Amount must be positive");

        listing.amount -= amount;
        if (listing.amount == 0) {
            delete fractionalListings[propertyId][msg.sender];
        }

        emit FractionalListingCancelled(propertyId, msg.sender, amount);
    }

    /// @notice Gets the details of a seller's active fractional share listing for a property.
    /// @param propertyId The ID of the property.
    /// @param seller The address of the seller.
    /// @return amount The amount of shares listed.
    /// @return pricePerShare The price per share.
    function getFractionalListing(uint256 propertyId, address seller) public view returns (uint256 amount, uint256 pricePerShare) {
        FractionalListing storage listing = fractionalListings[propertyId][seller];
        return (listing.amount, listing.pricePerShare);
    }


    // --- Governance System ---

    /// @notice Creates a proposal for a property improvement.
    /// Requires the caller to be a fractional token holder of the property.
    /// @param propertyId The ID of the property.
    /// @param description Description of the improvement.
    /// @param cost Estimated cost of the improvement in wei.
    /// @param votingDurationBlocks The number of blocks voting is open for.
    /// @param requiredMajorityBps Required percentage of YES votes (in basis points) among votes cast, relative to total supply at snapshot block, or based on votes cast. (Define threshold logic clearly!) Let's use votes cast.
    /// @return The ID of the created proposal.
    function createImprovementProposal(
        uint256 propertyId,
        string memory description,
        uint256 cost,
        uint256 votingDurationBlocks,
        uint256 requiredMajorityBps
    ) public onlyPropertyActive(propertyId) onlyFractionalTokenHolder(propertyId) nonReentrant returns (uint256) {
        require(votingDurationBlocks > 0, "Voting duration must be positive");
        require(requiredMajorityBps > 0 && requiredMajorityBps <= 10000, "Invalid majority basis points");

        Property storage property = properties[propertyId];
        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        proposals[propertyId][proposalId] = Proposal({
            proposer: msg.sender,
            proposalType: ProposalType.Improvement,
            description: description,
            creationBlock: block.number,
            votingDeadlineBlock: block.number + votingDurationBlocks,
            requiredMajorityBps: requiredMajorityBps,
            yayVotes: 0,
            nayVotes: 0,
            executed: false,
            cancelled: false,
            improvementCost: cost,
            newRentPerPeriod: 0 // Not applicable for this type
        });
        // hasVoted mapping is initialized empty

        _activeProposals[propertyId].add(proposalId);

        emit ProposalCreated(propertyId, proposalId, msg.sender, ProposalType.Improvement, description, block.number + votingDurationBlocks);
        return proposalId;
    }

    /// @notice Creates a proposal to change a property's rent per period.
    /// Requires the caller to be a fractional token holder of the property.
    /// @param propertyId The ID of the property.
    /// @param description Description of the proposed change.
    /// @param newRentPerPeriod The proposed new rent amount per period in wei.
    /// @param votingDurationBlocks The number of blocks voting is open for.
    /// @param requiredMajorityBps Required percentage of YES votes (in basis points) among votes cast.
    /// @return The ID of the created proposal.
    function createRentChangeProposal(
        uint256 propertyId,
        string memory description,
        uint256 newRentPerPeriod,
        uint256 votingDurationBlocks,
        uint256 requiredMajorityBps
    ) public onlyPropertyActive(propertyId) onlyFractionalTokenHolder(propertyId) nonReentrant returns (uint256) {
        require(votingDurationBlocks > 0, "Voting duration must be positive");
        require(requiredMajorityBps > 0 && requiredMajorityBps <= 10000, "Invalid majority basis points");

        Property storage property = properties[propertyId];
        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        proposals[propertyId][proposalId] = Proposal({
            proposer: msg.sender,
            proposalType: ProposalType.RentChange,
            description: description,
            creationBlock: block.number,
            votingDeadlineBlock: block.number + votingDurationBlocks,
            requiredMajorityBps: requiredMajorityBps,
            yayVotes: 0,
            nayVotes: 0,
            executed: false,
            cancelled: false,
            improvementCost: 0, // Not applicable for this type
            newRentPerPeriod: newRentPerPeriod
        });
        // hasVoted mapping is initialized empty

        _activeProposals[propertyId].add(proposalId);

        emit ProposalCreated(propertyId, proposalId, msg.sender, ProposalType.RentChange, description, block.number + votingDurationBlocks);
        return proposalId;
    }


    /// @notice Allows fractional token holders to vote on a proposal.
    /// Vote weight is based on the voter's fractional token balance at the proposal creation block.
    /// @param propertyId The ID of the property.
    /// @param proposalId The ID of the proposal.
    /// @param support True for a 'Yes' vote, false for a 'No' vote.
    function voteOnProposal(uint256 propertyId, uint256 proposalId, bool support) public onlyPropertyActive(propertyId) onlyFractionalTokenHolder(propertyId) nonReentrant {
        Proposal storage proposal = proposals[propertyId][proposalId];
        require(proposal.creationBlock > 0, "Proposal does not exist"); // Check if proposal exists
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        require(block.number <= proposal.votingDeadlineBlock, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        IERC20 fractionalToken = IERC20(properties[propertyId].fractionalToken);
        // Get vote weight based on balance at creation block.
        // NOTE: Standard ERC20 doesn't have `balanceOfAt`. This requires a token standard that supports snapshots
        // like OpenZeppelin's ERC20Votes. For this example, we simplify and use current balance.
        // In a real system, replace with ERC20Votes and use `balanceOfAt(msg.sender, proposal.creationBlock)`.
        uint256 voteWeight = fractionalToken.balanceOf(msg.sender);
        require(voteWeight > 0, "Must hold fractional tokens to vote");

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.yayVotes += voteWeight;
        } else {
            proposal.nayVotes += voteWeight;
        }

        emit Voted(propertyId, proposalId, msg.sender, support, voteWeight);
    }

    /// @notice Executes an approved improvement proposal.
    /// Can only be called after the voting period ends and if the proposal passed.
    /// Requires sufficient ETH balance in the contract to cover the improvement cost.
    /// @param propertyId The ID of the property.
    /// @param proposalId The ID of the improvement proposal.
    function executeImprovementProposal(uint256 propertyId, uint256 proposalId) public onlyPropertyActive(propertyId) nonReentrant {
         Proposal storage proposal = proposals[propertyId][proposalId];
         require(proposal.proposalType == ProposalType.Improvement, "Proposal is not an Improvement type");
         require(!proposal.executed, "Proposal already executed");
         require(!proposal.cancelled, "Proposal cancelled");
         require(block.number > proposal.votingDeadlineBlock, "Voting period not ended");

         uint256 totalVotesCast = proposal.yayVotes + proposal.nayVotes;
         // Check if proposal passed based on majority of *votes cast*
         bool passed = (totalVotesCast > 0) && (proposal.yayVotes * 10000) / totalVotesCast >= proposal.requiredMajorityBps;

         require(passed, "Proposal did not pass");
         require(address(this).balance >= proposal.improvementCost, "Insufficient contract balance for improvement");

         // Assuming improvement cost is paid to the property manager or owner
         address payable recipient = payable(properties[propertyId].propertyManager == address(0) ? ownerOf(propertyId) : properties[propertyId].propertyManager);
         require(recipient != address(0), "Invalid recipient for improvement funds");

         (bool success, ) = recipient.call{value: proposal.improvementCost}("");
         require(success, "ETH transfer for improvement failed");

         // Optional: Update property value after improvement
         // properties[propertyId].currentValue += ... (some calculation based on cost/impact)

         proposal.executed = true;
         _activeProposals[propertyId].remove(proposalId);

         emit ProposalExecuted(propertyId, proposalId);
    }

    /// @notice Executes an approved rent change proposal.
    /// Can only be called after the voting period ends and if the proposal passed.
    /// @param propertyId The ID of the property.
    /// @param proposalId The ID of the rent change proposal.
    function executeRentChangeProposal(uint256 propertyId, uint256 proposalId) public onlyPropertyActive(propertyId) nonReentrant {
         Proposal storage proposal = proposals[propertyId][proposalId];
         require(proposal.proposalType == ProposalType.RentChange, "Proposal is not a Rent Change type");
         require(!proposal.executed, "Proposal already executed");
         require(!proposal.cancelled, "Proposal cancelled");
         require(block.number > proposal.votingDeadlineBlock, "Voting period not ended");

         uint256 totalVotesCast = proposal.yayVotes + proposal.nayVotes;
          // Check if proposal passed based on majority of *votes cast*
         bool passed = (totalVotesCast > 0) && (proposal.yayVotes * 10000) / totalVotesCast >= proposal.requiredMajorityBps;

         require(passed, "Proposal did not pass");

         properties[propertyId].rentPerPeriod = proposal.newRentPerPeriod;

         proposal.executed = true;
         _activeProposals[propertyId].remove(proposalId);

         emit ProposalExecuted(propertyId, proposalId);
    }


    /// @notice Gets details for a specific proposal.
    /// @param propertyId The ID of the property.
    /// @param proposalId The ID of the proposal.
    /// @return proposer The address who created the proposal.
    /// @return proposalType The type of proposal (Improvement or RentChange).
    /// @return description The proposal description.
    /// @return creationBlock The block number when created.
    /// @return votingDeadlineBlock The block number when voting ends.
    /// @return requiredMajorityBps The required majority percentage in basis points.
    /// @return yayVotes The total vote weight for 'Yes'.
    /// @return nayVotes The total vote weight for 'No'.
    /// @return executed Whether the proposal has been executed.
    /// @return cancelled Whether the proposal has been cancelled.
    /// @return improvementCost For Improvement proposals, the cost.
    /// @return newRentPerPeriod For RentChange proposals, the new rent.
    function getProposalDetails(uint256 propertyId, uint256 proposalId) public view returns (
        address proposer,
        ProposalType proposalType,
        string memory description,
        uint256 creationBlock,
        uint256 votingDeadlineBlock,
        uint256 requiredMajorityBps,
        uint256 yayVotes,
        uint256 nayVotes,
        bool executed,
        bool cancelled,
        uint256 improvementCost,
        uint256 newRentPerPeriod
    ) {
        Proposal storage proposal = proposals[propertyId][proposalId];
        require(proposal.creationBlock > 0, "Proposal does not exist");

        return (
            proposal.proposer,
            proposal.proposalType,
            proposal.description,
            proposal.creationBlock,
            proposal.votingDeadlineBlock,
            proposal.requiredMajorityBps,
            proposal.yayVotes,
            proposal.nayVotes,
            proposal.executed,
            proposal.cancelled,
            proposal.improvementCost,
            proposal.newRentPerPeriod
        );
    }

     /// @notice Gets a list of active proposal IDs for a specific property.
     /// Active means the voting period has not ended and it hasn't been executed or cancelled.
     /// @param propertyId The ID of the property.
     /// @return An array of active proposal IDs.
    function getActiveProposals(uint256 propertyId) public view returns (uint256[] memory) {
        EnumerableSet.UintSet storage active = _activeProposals[propertyId];
        uint256[] memory activeArr = new uint256[](active.length());
        for (uint i = 0; i < active.length(); i++) {
            uint256 proposalId = active.at(i);
             // Double check if truly active based on state
             Proposal storage proposal = proposals[propertyId][proposalId];
             if (block.number <= proposal.votingDeadlineBlock && !proposal.executed && !proposal.cancelled) {
                 activeArr[i] = proposalId;
             } else {
                 // Clean up expired/executed/cancelled proposals from the set
                 // This requires a state-changing transaction. A view function can't do this.
                 // For view purposes, we can filter dynamically.
                 activeArr[i] = 0; // Mark for filtering
             }
        }
         // Filter out marked (expired/executed/cancelled) proposals
        uint256 validCount = 0;
        for(uint i=0; i<activeArr.length; i++){
            if(activeArr[i] != 0) validCount++;
        }
        uint256[] memory filteredActiveArr = new uint256[](validCount);
        uint256 currentIdx = 0;
        for(uint i=0; i<activeArr.length; i++){
             if(activeArr[i] != 0) {
                 filteredActiveArr[currentIdx] = activeArr[i];
                 currentIdx++;
             }
        }
        return filteredActiveArr;
    }


    // --- Platform Fee Management ---

    /// @notice Sets the platform fee percentage in basis points (0-10000).
    /// @param feeBps The new fee percentage in basis points.
    function setPlatformFee(uint256 feeBps) public onlyOwner {
        require(feeBps <= 10000, "Fee cannot exceed 100%");
        platformFeeBps = feeBps;
        emit PlatformFeeUpdated(feeBps);
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawFees() public onlyOwner nonReentrant {
        uint256 amount = totalCollectedFees;
        require(amount > 0, "No fees to withdraw");

        totalCollectedFees = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(msg.sender, amount);
    }

    // --- Utility Getters ---

    /// @notice Get comprehensive details of a property.
    /// @param propertyId The ID of the property.
    /// @return location The property location/identifier.
    /// @return initialValue The initial estimated value.
    /// @return currentValue The current simulated value.
    /// @return rentPerPeriod The rent amount per period.
    /// @return propertyManager The address of the property manager.
    /// @return isFractionalized Whether the property is fractionalized.
    /// @return fractionalToken The address of the fractional token contract.
    /// @return isActive Whether the property is active.
    /// @return maintenanceCostLogged Accumulated maintenance costs.
    function getPropertyDetails(uint256 propertyId) public view returns (
        string memory location,
        uint256 initialValue,
        uint256 currentValue,
        uint256 rentPerPeriod,
        address propertyManager,
        bool isFractionalized,
        address fractionalToken,
        bool isActive,
        uint256 maintenanceCostLogged
    ) {
        Property storage property = properties[propertyId];
        require(property.initialValue > 0 || _exists(propertyId), "Property does not exist"); // Check existence

        return (
            property.location,
            property.initialValue,
            property.currentValue,
            property.rentPerPeriod,
            property.propertyManager,
            property.isFractionalized,
            property.fractionalToken,
            property.isActive,
            property.maintenanceCostLogged
        );
    }

    /// @notice Get rent-specific information for a property.
    /// @param propertyId The ID of the property.
    /// @return rentPerPeriod The rent amount per period.
    /// @return totalRentClaimedByHolder The total rent amount claimed by a specific holder.
    function getPropertyRentInfo(uint256 propertyId) public view returns (uint256 rentPerPeriod, uint256 totalRentClaimedByHolder) {
         Property storage property = properties[propertyId];
         require(property.initialValue > 0 || _exists(propertyId), "Property does not exist");

         // Return claimed rent for the caller of this function
         uint256 claimed = _claimedRent[propertyId][msg.sender];

         return (property.rentPerPeriod, claimed);
    }


    // --- Internal Fractional ERC20 Contract Definition ---
    // This is a simplified ERC20 deployed *per property*.
    // In a real system, this would likely be a separate contract file
    // and instantiated via a factory pattern.

    contract CryptoEstateFractionalToken is ERC20 {
        address public immutable cryptoEstateMainContract;
        uint256 public immutable propertyId;

        constructor(
            string memory name,
            string memory symbol,
            uint256 initialSupply,
            address _cryptoEstateMainContract,
            uint256 _propertyId
        ) ERC20(name, symbol) {
            cryptoEstateMainContract = _cryptoEstateMainContract;
            propertyId = _propertyId;
            // Mint initial supply to the main CryptoEstate contract
            _mint(cryptoEstateMainContract, initialSupply);
        }

        // Optional: Restrict transfers if the main property NFT is not owned by CryptoEstate
        // or if the property is inactive. This adds complexity and requires callbacks
        // or state checks against the main contract. For simplicity, keeping standard ERC20 transfers.

        // Adding a function to allow the main contract to call and trigger updates or signals if needed,
        // but rent claiming is done via the main contract's claimRent function based on balances here.
        // No specific custom functions needed *on* this ERC20 for the current model.

    }
}
```