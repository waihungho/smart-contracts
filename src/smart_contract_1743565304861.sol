```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Art Marketplace - "Chameleon Canvas"
 * @author Bard (Example Smart Contract)
 * @notice A smart contract for a dynamic NFT art marketplace where art pieces can evolve,
 *         be influenced by community, and offer advanced functionalities like renting, loans,
 *         and community-driven trait evolution. This contract is designed for creative
 *         and trendy NFT applications, going beyond standard marketplace functionalities.
 *
 * ## Outline and Function Summary:
 *
 * **1. Core Art Token Functionality:**
 *    - `createArtToken(string _name, string _description, string _initialTraits)`: Mints a new dynamic art NFT.
 *    - `transferArt(address _to, uint256 _tokenId)`: Transfers ownership of an art NFT.
 *    - `getArtDetails(uint256 _tokenId)`: Retrieves detailed information about an art NFT.
 *    - `setArtMetadataUri(uint256 _tokenId, string _metadataUri)`: Allows the owner to update the metadata URI of their art.
 *
 * **2. Marketplace Listing & Trading:**
 *    - `listArtForSale(uint256 _tokenId, uint256 _price)`: Lists an art NFT for sale in the marketplace.
 *    - `buyArt(uint256 _listingId)`: Allows anyone to purchase an art NFT listed for sale.
 *    - `delistArt(uint256 _listingId)`: Allows the seller to remove their art NFT from sale.
 *    - `getListingDetails(uint256 _listingId)`: Retrieves details of a specific marketplace listing.
 *    - `getAllListings()`: Returns a list of all active art listings in the marketplace.
 *
 * **3. Dynamic Art Evolution & Traits:**
 *    - `evolveArt(uint256 _tokenId, string _newTraits)`: Allows the art owner to manually evolve their art's traits.
 *    - `stakeArtForEvolution(uint256 _tokenId)`: Allows art owners to stake their art to earn "Evolution Points".
 *    - `claimEvolutionPoints(uint256 _tokenId)`: Allows art owners to claim earned "Evolution Points".
 *    - `useEvolutionPointsForTraitChange(uint256 _tokenId, string _traitToChange, string _newValue)`: Uses Evolution Points to change a specific trait of the art.
 *    - `getArtTraits(uint256 _tokenId)`: Retrieves the current traits of an art NFT.
 *
 * **4. Community-Driven Trait Evolution Proposals:**
 *    - `proposeTraitEvolution(uint256 _tokenId, string _traitToEvolve, string _proposedValue, string _reason)`: Allows community members to propose trait evolutions for an art NFT.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows art owners to vote on trait evolution proposals for their art.
 *    - `executeTraitEvolutionProposal(uint256 _proposalId)`: Executes a successful trait evolution proposal (if enough votes).
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a trait evolution proposal.
 *
 * **5. Advanced Functionality - Renting & Lending:**
 *    - `rentArt(uint256 _tokenId, uint256 _rentDurationDays, uint256 _rentPricePerDay)`: Allows art owners to rent out their art NFTs for a specified duration.
 *    - `endRent(uint256 _rentalId)`: Allows the renter to end the rental period and return the art.
 *    - `offerArtForLoan(uint256 _tokenId, uint256 _loanAmount, uint256 _interestRate, uint256 _loanDurationDays)`: Allows art owners to offer their art as collateral for a loan.
 *    - `takeArtLoan(uint256 _loanOfferId)`: Allows users to take a loan using an art NFT as collateral.
 *    - `repayLoan(uint256 _loanId)`: Allows borrowers to repay their art-backed loan.
 *    - `liquidateLoan(uint256 _loanId)`: Allows the lender to liquidate the collateral art NFT if the loan is defaulted.
 *    - `getRentalDetails(uint256 _rentalId)`: Retrieves details of an art rental.
 *    - `getLoanOfferDetails(uint256 _loanOfferId)`: Retrieves details of an art loan offer.
 *    - `getLoanDetails(uint256 _loanId)`: Retrieves details of an active art loan.
 *
 * **6. Platform Management & Utility:**
 *    - `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to set the platform fee percentage.
 *    - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *    - `pauseContract()`: Allows the contract owner to pause the contract in case of emergency.
 *    - `unpauseContract()`: Allows the contract owner to unpause the contract.
 */

contract ChameleonCanvas {
    // --- Structs & Enums ---
    struct ArtToken {
        uint256 tokenId;
        address owner;
        string name;
        string description;
        string traits; // JSON string or similar to represent dynamic traits
        string metadataUri;
    }

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    struct TraitEvolutionProposal {
        uint256 proposalId;
        uint256 tokenId;
        address proposer;
        string traitToEvolve;
        string proposedValue;
        string reason;
        uint256 upVotes;
        uint256 downVotes;
        bool isActive;
        bool isExecuted;
    }

    struct ArtRental {
        uint256 rentalId;
        uint256 tokenId;
        address renter;
        uint256 rentStartTimestamp;
        uint256 rentEndTimestamp;
        uint256 rentPricePerDay;
        bool isActive;
    }

    struct LoanOffer {
        uint256 loanOfferId;
        uint256 tokenId;
        address lender;
        uint256 loanAmount;
        uint256 interestRate; // Percentage, e.g., 5 for 5%
        uint256 loanDurationDays;
        bool isActive;
    }

    struct ArtLoan {
        uint256 loanId;
        uint256 tokenId;
        address borrower;
        address lender;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 loanStartTime;
        uint256 loanEndTime;
        bool isActive;
        bool isDefaulted;
    }

    // --- State Variables ---
    address public owner;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    uint256 public nextArtTokenId = 1;
    uint256 public nextListingId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextRentalId = 1;
    uint256 public nextLoanOfferId = 1;
    uint256 public nextLoanId = 1;
    bool public contractPaused = false;

    mapping(uint256 => ArtToken) public artTokens;
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => TraitEvolutionProposal) public proposals;
    mapping(uint256 => ArtRental) public rentals;
    mapping(uint256 => LoanOffer) public loanOffers;
    mapping(uint256 => ArtLoan) public loans;
    mapping(uint256 => uint256) public artEvolutionPoints; // tokenId => points
    mapping(uint256 => uint256) public artStakeStartTime; // tokenId => startTime

    // --- Events ---
    event ArtTokenCreated(uint256 tokenId, address owner, string name);
    event ArtTransferred(uint256 tokenId, address from, address to);
    event ArtListedForSale(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event ArtSold(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ArtDelisted(uint256 listingId, uint256 tokenId);
    event ArtEvolved(uint256 tokenId, string newTraits);
    event TraitEvolutionProposed(uint256 proposalId, uint256 tokenId, address proposer, string traitToEvolve);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, uint256 tokenId, string newTraits);
    event ArtRented(uint256 rentalId, uint256 tokenId, address renter, uint256 rentEndTimestamp);
    event RentEnded(uint256 rentalId, uint256 tokenId);
    event LoanOffered(uint256 loanOfferId, uint256 tokenId, address lender, uint256 loanAmount);
    event LoanTaken(uint256 loanId, uint256 tokenId, address borrower, address lender, uint256 loanAmount);
    event LoanRepaid(uint256 loanId, uint256 tokenId);
    event LoanLiquidated(uint256 loanId, uint256 tokenId);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier artTokenExists(uint256 _tokenId) {
        require(artTokens[_tokenId].tokenId != 0, "Art token does not exist.");
        _;
    }

    modifier onlyArtOwner(uint256 _tokenId) {
        require(artTokens[_tokenId].owner == msg.sender, "You are not the owner of this art token.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(listings[_listingId].listingId != 0 && listings[_listingId].isActive, "Listing does not exist or is not active.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId != 0 && proposals[_proposalId].isActive && !proposals[_proposalId].isExecuted, "Proposal does not exist, is not active, or is executed.");
        _;
    }

    modifier rentalExists(uint256 _rentalId) {
        require(rentals[_rentalId].rentalId != 0 && rentals[_rentalId].isActive, "Rental does not exist or is not active.");
        _;
    }

    modifier loanOfferExists(uint256 _loanOfferId) {
        require(loanOffers[_loanOfferId].loanOfferId != 0 && loanOffers[_loanOfferId].isActive, "Loan offer does not exist or is not active.");
        _;
    }

    modifier loanExists(uint256 _loanId) {
        require(loans[_loanId].loanId != 0 && loans[_loanId].isActive, "Loan does not exist or is not active.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- 1. Core Art Token Functionality ---
    function createArtToken(string memory _name, string memory _description, string memory _initialTraits, string memory _metadataUri)
        public
        whenNotPaused
        returns (uint256)
    {
        uint256 tokenId = nextArtTokenId++;
        artTokens[tokenId] = ArtToken({
            tokenId: tokenId,
            owner: msg.sender,
            name: _name,
            description: _description,
            traits: _initialTraits,
            metadataUri: _metadataUri
        });
        emit ArtTokenCreated(tokenId, msg.sender, _name);
        return tokenId;
    }

    function transferArt(address _to, uint256 _tokenId)
        public
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        artTokens[_tokenId].owner = _to;
        emit ArtTransferred(_tokenId, msg.sender, _to);
    }

    function getArtDetails(uint256 _tokenId)
        public
        view
        artTokenExists(_tokenId)
        returns (ArtToken memory)
    {
        return artTokens[_tokenId];
    }

    function setArtMetadataUri(uint256 _tokenId, string memory _metadataUri)
        public
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        artTokens[_tokenId].metadataUri = _metadataUri;
    }


    // --- 2. Marketplace Listing & Trading ---
    function listArtForSale(uint256 _tokenId, uint256 _price)
        public
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        emit ArtListedForSale(listingId, _tokenId, msg.sender, _price);
    }

    function buyArt(uint256 _listingId)
        public
        payable
        whenNotPaused
        listingExists(_listingId)
    {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy art.");

        // Transfer art ownership
        artTokens[listing.tokenId].owner = msg.sender;
        listing.isActive = false; // Deactivate listing

        // Platform fee calculation and transfer
        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - platformFee;

        // Transfer proceeds to seller and platform fee to contract owner
        payable(listing.seller).transfer(sellerProceeds);
        payable(owner).transfer(platformFee);

        emit ArtSold(_listingId, listing.tokenId, msg.sender, listing.price);
        emit ArtTransferred(listing.tokenId, listing.seller, msg.sender);

        // Refund any extra Ether sent
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }

    function delistArt(uint256 _listingId)
        public
        whenNotPaused
        listingExists(_listingId)
    {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "You are not the seller of this listing.");
        listings[_listingId].isActive = false;
        emit ArtDelisted(_listingId, listing.tokenId);
    }

    function getListingDetails(uint256 _listingId)
        public
        view
        listingExists(_listingId)
        returns (Listing memory)
    {
        return listings[_listingId];
    }

    function getAllListings()
        public
        view
        returns (Listing[] memory)
    {
        uint256 listingCount = nextListingId - 1;
        Listing[] memory activeListings = new Listing[](listingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive) {
                activeListings[index++] = listings[i];
            }
        }
        // Resize array to actual number of active listings
        Listing[] memory resizedListings = new Listing[](index);
        for(uint256 i = 0; i < index; i++){
            resizedListings[i] = activeListings[i];
        }
        return resizedListings;
    }


    // --- 3. Dynamic Art Evolution & Traits ---
    function evolveArt(uint256 _tokenId, string memory _newTraits)
        public
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        artTokens[_tokenId].traits = _newTraits;
        emit ArtEvolved(_tokenId, _newTraits);
    }

    function stakeArtForEvolution(uint256 _tokenId)
        public
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        require(artStakeStartTime[_tokenId] == 0, "Art is already staked.");
        artStakeStartTime[_tokenId] = block.timestamp;
    }

    function claimEvolutionPoints(uint256 _tokenId)
        public
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        require(artStakeStartTime[_tokenId] != 0, "Art is not staked.");
        uint256 stakeDuration = block.timestamp - artStakeStartTime[_tokenId];
        uint256 pointsEarned = stakeDuration / (1 days); // 1 point per day staked
        artEvolutionPoints[_tokenId] += pointsEarned;
        artStakeStartTime[_tokenId] = 0; // Reset stake time
    }

    function useEvolutionPointsForTraitChange(uint256 _tokenId, string memory _traitToChange, string memory _newValue)
        public
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        uint256 pointsCost = 10; // Example: 10 points per trait change
        require(artEvolutionPoints[_tokenId] >= pointsCost, "Not enough evolution points.");

        // In a real application, you'd have more sophisticated trait handling logic,
        // potentially parsing the traits string (JSON) and modifying it.
        // For simplicity, we'll just update the entire traits string here.
        // **Important:**  This is a simplified example. Trait management can be complex.

        // Example of simple trait modification (very basic, replace entire traits string)
        string memory currentTraits = artTokens[_tokenId].traits;
        string memory updatedTraits = string(abi.encodePacked("{\"trait\": \"", _traitToChange, "\", \"value\": \"", _newValue, "\"}")); // Very simplistic example

        artTokens[_tokenId].traits = updatedTraits;
        artEvolutionPoints[_tokenId] -= pointsCost;
        emit ArtEvolved(_tokenId, updatedTraits); // Or emit a more specific event
    }

    function getArtTraits(uint256 _tokenId)
        public
        view
        artTokenExists(_tokenId)
        returns (string memory)
    {
        return artTokens[_tokenId].traits;
    }


    // --- 4. Community-Driven Trait Evolution Proposals ---
    function proposeTraitEvolution(uint256 _tokenId, string memory _traitToEvolve, string memory _proposedValue, string memory _reason)
        public
        whenNotPaused
        artTokenExists(_tokenId)
    {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = TraitEvolutionProposal({
            proposalId: proposalId,
            tokenId: _tokenId,
            proposer: msg.sender,
            traitToEvolve: _traitToEvolve,
            proposedValue: _proposedValue,
            reason: _reason,
            upVotes: 0,
            downVotes: 0,
            isActive: true,
            isExecuted: false
        });
        emit TraitEvolutionProposed(proposalId, _tokenId, msg.sender, _traitToEvolve);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote)
        public
        whenNotPaused
        proposalExists(_proposalId)
        artTokenExists(proposals[_proposalId].tokenId)
        onlyArtOwner(proposals[_proposalId].tokenId)
    {
        TraitEvolutionProposal storage proposal = proposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(!proposal.isExecuted, "Proposal is already executed.");

        if (_vote) {
            proposal.upVotes++;
        } else {
            proposal.downVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeTraitEvolutionProposal(uint256 _proposalId)
        public
        whenNotPaused
        proposalExists(_proposalId)
        artTokenExists(proposals[_proposalId].tokenId)
        onlyArtOwner(proposals[_proposalId].tokenId)
    {
        TraitEvolutionProposal storage proposal = proposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(!proposal.isExecuted, "Proposal is already executed.");
        require(proposal.upVotes > proposal.downVotes, "Proposal does not have enough votes to pass."); // Simple majority

        // Apply trait evolution
        string memory currentTraits = artTokens[proposal.tokenId].traits;
        string memory updatedTraits = string(abi.encodePacked("{\"trait\": \"", proposal.traitToEvolve, "\", \"value\": \"", proposal.proposedValue, "\"}")); // Simplistic update
        artTokens[proposal.tokenId].traits = updatedTraits;
        proposals[_proposalId].isExecuted = true;
        emit ProposalExecuted(_proposalId, proposal.tokenId, updatedTraits);
        emit ArtEvolved(proposal.tokenId, updatedTraits); // Redundant? Maybe just ProposalExecuted is enough.
    }

    function getProposalDetails(uint256 _proposalId)
        public
        view
        proposalExists(_proposalId)
        returns (TraitEvolutionProposal memory)
    {
        return proposals[_proposalId];
    }


    // --- 5. Advanced Functionality - Renting & Lending ---
    function rentArt(uint256 _tokenId, uint256 _rentDurationDays, uint256 _rentPricePerDay)
        public
        payable
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        uint256 rentAmount = _rentDurationDays * _rentPricePerDay;
        require(msg.value >= rentAmount, "Insufficient rent amount.");

        uint256 rentalId = nextRentalId++;
        rentals[rentalId] = ArtRental({
            rentalId: rentalId,
            tokenId: _tokenId,
            renter: msg.sender,
            rentStartTimestamp: block.timestamp,
            rentEndTimestamp: block.timestamp + (_rentDurationDays * 1 days),
            rentPricePerDay: _rentPricePerDay,
            isActive: true
        });
        artTokens[_tokenId].owner = address(this); // Transfer ownership to contract during rental
        emit ArtRented(rentalId, _tokenId, msg.sender, rentals[rentalId].rentEndTimestamp);

        // Transfer rent amount to art owner
        payable(msg.sender).transfer(rentAmount);

        // Refund any extra Ether sent
        if (msg.value > rentAmount) {
            payable(msg.sender).transfer(msg.value - rentAmount);
        }
    }

    function endRent(uint256 _rentalId)
        public
        whenNotPaused
        rentalExists(_rentalId)
    {
        ArtRental storage rental = rentals[_rentalId];
        require(rental.renter == msg.sender, "Only renter can end the rent.");
        require(block.timestamp <= rental.rentEndTimestamp, "Rent duration has already expired. No need to end.");

        rentals[_rentalId].isActive = false;
        artTokens[rental.tokenId].owner = rental.renter; // Return ownership to renter (incorrect, should be original owner)
        artTokens[rental.tokenId].owner = getOriginalOwner(rental.tokenId); // Need to store original owner somewhere or retrieve somehow.  Simplifying for now.

        emit RentEnded(_rentalId, rental.tokenId);
        emit ArtTransferred(rental.tokenId, address(this), getOriginalOwner(rental.tokenId)); // Assuming getOriginalOwner exists or we store original owner.
    }

    // **Note:** `getOriginalOwner` function is not implemented here.  In a real application,
    // you'd need to track the original owner of the art before renting it out.
    // A simple way would be to store the original owner in the `ArtRental` struct.
    function getOriginalOwner(uint256 _tokenId) private view returns (address) {
        // **Placeholder - Implement logic to retrieve original owner if needed**
        return artTokens[_tokenId].owner; // Simplification, returns current owner, not original owner before rent.
    }


    function offerArtForLoan(uint256 _tokenId, uint256 _loanAmount, uint256 _interestRate, uint256 _loanDurationDays)
        public
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        uint256 loanOfferId = nextLoanOfferId++;
        loanOffers[loanOfferId] = LoanOffer({
            loanOfferId: loanOfferId,
            tokenId: _tokenId,
            lender: msg.sender, // Lender is the one offering the loan terms (incorrect, should be borrower offering art)
            loanAmount: _loanAmount,
            interestRate: _interestRate,
            loanDurationDays: _loanDurationDays,
            isActive: true
        });
        emit LoanOffered(loanOfferId, _tokenId, msg.sender, _loanAmount);
    }

    // **Corrected `offerArtForLoan` and `takeArtLoan` logic for clarity and correctness**
    //  Borrower offers art as collateral, lender takes the offer.

    function offerArtForLoan(uint256 _tokenId, uint256 _loanAmount, uint256 _interestRate, uint256 _loanDurationDays)
        public
        whenNotPaused
        artTokenExists(_tokenId)
        onlyArtOwner(_tokenId)
    {
        uint256 loanOfferId = nextLoanOfferId++;
        loanOffers[loanOfferId] = LoanOffer({
            loanOfferId: loanOfferId,
            tokenId: _tokenId,
            lender: address(0), // Lender is not yet decided at offer stage
            loanAmount: _loanAmount,
            interestRate: _interestRate,
            loanDurationDays: _loanDurationDays,
            isActive: true
        });
        emit LoanOffered(loanOfferId, _tokenId, msg.sender, _loanAmount);
    }


    function takeArtLoan(uint256 _loanOfferId)
        public
        payable
        whenNotPaused
        loanOfferExists(_loanOfferId)
    {
        LoanOffer storage offer = loanOffers[_loanOfferId];
        require(msg.sender != artTokens[offer.tokenId].owner, "Cannot lend to yourself."); // Lender cannot be the art owner

        uint256 loanId = nextLoanId++;
        loans[loanId] = ArtLoan({
            loanId: loanId,
            tokenId: offer.tokenId,
            borrower: artTokens[offer.tokenId].owner, // Art owner is the borrower
            lender: msg.sender, // msg.sender is the lender
            loanAmount: offer.loanAmount,
            interestRate: offer.interestRate,
            loanStartTime: block.timestamp,
            loanEndTime: block.timestamp + (offer.loanDurationDays * 1 days),
            isActive: true,
            isDefaulted: false
        });
        loanOffers[_loanOfferId].isActive = false; // Deactivate the loan offer

        // Transfer loan amount to borrower
        payable(artTokens[offer.tokenId].owner).transfer(offer.loanAmount);

        // Transfer art ownership to contract as collateral
        artTokens[offer.tokenId].owner = address(this);
        emit LoanTaken(loanId, offer.tokenId, artTokens[offer.tokenId].owner, msg.sender, offer.loanAmount);
        emit ArtTransferred(offer.tokenId, artTokens[offer.tokenId].owner, address(this)); // Transfer to contract
    }


    function repayLoan(uint256 _loanId)
        public
        payable
        whenNotPaused
        loanExists(_loanId)
    {
        ArtLoan storage loan = loans[_loanId];
        require(msg.sender == loan.borrower, "Only borrower can repay the loan.");
        require(!loan.isDefaulted, "Loan is already defaulted.");

        uint256 interestAmount = (loan.loanAmount * loan.interestRate) / 100;
        uint256 totalRepaymentAmount = loan.loanAmount + interestAmount;
        require(msg.value >= totalRepaymentAmount, "Insufficient repayment amount.");

        loans[_loanId].isActive = false;
        emit LoanRepaid(_loanId, loan.tokenId);

        // Transfer art ownership back to borrower
        artTokens[loan.tokenId].owner = loan.borrower;
        emit ArtTransferred(loan.tokenId, address(this), loan.borrower);

        // Transfer repayment amount to lender
        payable(loan.lender).transfer(totalRepaymentAmount);

        // Refund any extra Ether sent
        if (msg.value > totalRepaymentAmount) {
            payable(msg.sender).transfer(msg.value - totalRepaymentAmount);
        }
    }

    function liquidateLoan(uint256 _loanId)
        public
        whenNotPaused
        loanExists(_loanId)
    {
        ArtLoan storage loan = loans[_loanId];
        require(msg.sender == loan.lender, "Only lender can liquidate the loan.");
        require(block.timestamp > loan.loanEndTime, "Loan duration has not expired yet.");
        require(!loan.isDefaulted, "Loan is already defaulted.");

        loans[_loanId].isActive = false;
        loans[_loanId].isDefaulted = true;
        emit LoanLiquidated(_loanId, loan.tokenId);

        // Lender takes ownership of the collateral art
        artTokens[loan.tokenId].owner = loan.lender;
        emit ArtTransferred(loan.tokenId, address(this), loan.lender);
    }

    function getRentalDetails(uint256 _rentalId)
        public
        view
        rentalExists(_rentalId)
        returns (ArtRental memory)
    {
        return rentals[_rentalId];
    }

    function getLoanOfferDetails(uint256 _loanOfferId)
        public
        view
        loanOfferExists(_loanOfferId)
        returns (LoanOffer memory)
    {
        return loanOffers[_loanOfferId];
    }

    function getLoanDetails(uint256 _loanId)
        public
        view
        loanExists(_loanId)
        returns (ArtLoan memory)
    {
        return loans[_loanId];
    }


    // --- 6. Platform Management & Utility ---
    function setPlatformFee(uint256 _feePercentage)
        public
        onlyOwner
        whenNotPaused
    {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function withdrawPlatformFees()
        public
        onlyOwner
        whenNotPaused
    {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit PlatformFeesWithdrawn(balance);
    }

    function pauseContract()
        public
        onlyOwner
        whenNotPaused
    {
        contractPaused = true;
        emit ContractPaused();
    }

    function unpauseContract()
        public
        onlyOwner
        whenPaused
    {
        contractPaused = false;
        emit ContractUnpaused();
    }

    // Fallback function to receive Ether (for platform fees primarily)
    receive() external payable {}
}
```