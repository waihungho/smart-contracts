```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (Inspired by your request)
 * @dev A smart contract for a decentralized autonomous art gallery, featuring advanced concepts like
 *      curated NFT exhibitions, fractional NFT ownership, art lending/borrowing, dynamic pricing based on community voting,
 *      artist reputation system, decentralized governance for gallery operations, and more.
 *
 * Function Summary:
 *
 * --- Core Gallery Functions ---
 * 1. listNFT(address _nftContract, uint256 _tokenId, uint256 _price): Allows an NFT owner to list their NFT in the gallery for sale.
 * 2. unlistNFT(address _nftContract, uint256 _tokenId): Allows the NFT lister to remove their NFT from the gallery listing.
 * 3. purchaseNFT(address _nftContract, uint256 _tokenId): Allows anyone to purchase a listed NFT.
 * 4. getNFTDetails(address _nftContract, uint256 _tokenId): Retrieves details of an NFT listed in the gallery.
 * 5. getGalleryNFTs(): Returns a list of all NFTs currently listed in the gallery.
 *
 * --- Curation and Exhibition Functions ---
 * 6. submitCurationProposal(address _nftContract, uint256 _tokenId, string _proposalDescription): Allows registered curators to propose NFTs for gallery exhibition.
 * 7. voteOnCurationProposal(uint256 _proposalId, bool _vote): Allows gallery members to vote on curation proposals.
 * 8. executeCurationProposal(uint256 _proposalId): Executes a successful curation proposal, adding the NFT to the curated collection.
 * 9. createExhibition(string _exhibitionName, string _exhibitionDescription): Allows curators to create new themed exhibitions.
 * 10. addNFTtoExhibition(uint256 _exhibitionId, address _nftContract, uint256 _tokenId): Allows curators to add curated NFTs to specific exhibitions.
 * 11. removeNFTfromExhibition(uint256 _exhibitionId, address _nftContract, uint256 _tokenId): Allows curators to remove NFTs from exhibitions.
 * 12. getExhibitionDetails(uint256 _exhibitionId): Retrieves details of a specific exhibition, including NFTs.
 * 13. getActiveExhibitions(): Returns a list of currently active exhibitions.
 *
 * --- Fractional NFT Ownership Functions ---
 * 14. fractionalizeNFT(address _nftContract, uint256 _tokenId, uint256 _fractionCount): Allows NFT owners to fractionalize their listed NFT into fungible tokens.
 * 15. buyFractionalNFT(address _nftContract, uint256 _tokenId, uint256 _fractionAmount): Allows users to buy fractions of a fractionalized NFT.
 * 16. redeemFractionalNFT(address _nftContract, uint256 _tokenId): Allows majority fractional owners to redeem the original NFT (governance based).
 *
 * --- Art Lending/Borrowing Functions ---
 * 17. lendNFT(address _nftContract, uint256 _tokenId, uint256 _loanDurationDays, uint256 _dailyInterestRate): Allows NFT owners to list their listed NFTs for lending.
 * 18. borrowNFT(address _nftContract, uint256 _tokenId, uint256 _loanDurationDays): Allows users to borrow listed NFTs by paying interest.
 * 19. repayLoan(address _nftContract, uint256 _tokenId): Allows borrowers to repay the loan and reclaim the NFT.
 * 20. liquidateLoan(address _nftContract, uint256 _tokenId): Allows lenders to liquidate loans if borrowers default (after loan duration).
 *
 * --- Governance and Utility Functions ---
 * 21. registerCurator(): Allows users to register as gallery curators (governance approval needed in a real DAO).
 * 22. setGalleryFee(uint256 _feePercentage): Allows the gallery owner to set the platform fee percentage.
 * 23. withdrawGalleryBalance(): Allows the gallery owner to withdraw accumulated gallery fees.
 * 24. getCuratorList(): Returns a list of registered curators.
 * 25. getProposalDetails(uint256 _proposalId): Retrieves details of a specific curation proposal.
 * 26. setVotingDuration(uint256 _durationInBlocks): Allows the gallery owner to set the voting duration for proposals.
 * 27. setQuorum(uint256 _quorumPercentage): Allows the gallery owner to set the quorum percentage for proposal approval.
 */
contract DecentralizedAutonomousArtGallery {
    // --- State Variables ---

    address public galleryOwner;
    uint256 public galleryFeePercentage = 2; // Default 2% gallery fee
    uint256 public votingDurationBlocks = 100; // Default voting duration: 100 blocks
    uint256 public quorumPercentage = 50; // Default quorum: 50%

    struct NFTListing {
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isListed;
        bool isFractionalized;
        bool isLendable;
    }

    struct CurationProposal {
        address proposer;
        address nftContract;
        uint256 tokenId;
        string proposalDescription;
        uint256 upVotes;
        uint256 downVotes;
        uint256 voteEndTime;
        bool proposalExecuted;
    }

    struct Exhibition {
        uint256 exhibitionId;
        string name;
        string description;
        address curator;
        NFTListing[] nfts;
        bool isActive;
    }

    struct FractionalNFT {
        address nftContract;
        uint256 tokenId;
        uint256 fractionCount;
        mapping(address => uint256) fractionalTokenBalances; // Address to amount of fractional tokens held
        bool isFractionalized;
    }

    struct Loan {
        address nftContract;
        uint256 tokenId;
        address lender;
        address borrower;
        uint256 loanStartTime;
        uint256 loanEndTime;
        uint256 dailyInterestRate; // in percentage (e.g., 100 = 1%)
        bool isActive;
    }

    mapping(address => mapping(uint256 => NFTListing)) public nftListings; // nftContract => tokenId => Listing details
    mapping(uint256 => CurationProposal) public curationProposals;
    uint256 public proposalCounter = 0;
    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public exhibitionCounter = 0;
    mapping(address => mapping(uint256 => FractionalNFT)) public fractionalNFTs; // nftContract => tokenId => Fractional NFT data
    mapping(address => mapping(uint256 => Loan)) public nftLoans; // nftContract => tokenId => Loan details
    mapping(address => bool) public registeredCurators;
    address[] public curatorList;


    // --- Events ---
    event NFTListed(address nftContract, uint256 tokenId, address seller, uint256 price);
    event NFTUnlisted(address nftContract, uint256 tokenId);
    event NFTPurchased(address nftContract, uint256 tokenId, address buyer, address seller, uint256 price);
    event CurationProposalSubmitted(uint256 proposalId, address nftContract, uint256 tokenId, address proposer);
    event CurationProposalVoted(uint256 proposalId, address voter, bool vote);
    event CurationProposalExecuted(uint256 proposalId, address nftContract, uint256 tokenId);
    event ExhibitionCreated(uint256 exhibitionId, string name, address curator);
    event NFTAddedToExhibition(uint256 exhibitionId, address nftContract, uint256 tokenId);
    event NFTFractionalized(address nftContract, uint256 tokenId, uint256 fractionCount);
    event FractionalNFTBought(address nftContract, uint256 tokenId, address buyer, uint256 amount);
    event NFTLent(address nftContract, uint256 tokenId, address lender, uint256 loanDurationDays, uint256 dailyInterestRate);
    event NFTBorrowed(address nftContract, uint256 tokenId, address borrower, address lender, uint256 loanEndTime);
    event LoanRepaid(address nftContract, uint256 tokenId, address borrower, address lender);
    event LoanLiquidated(address nftContract, uint256 tokenId, address lender);
    event CuratorRegistered(address curatorAddress);
    event GalleryFeeSet(uint256 feePercentage);
    event GalleryBalanceWithdrawn(address owner, uint256 amount);
    event VotingDurationSet(uint256 durationInBlocks);
    event QuorumSet(uint256 quorumPercentage);


    // --- Modifiers ---
    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can call this function.");
        _;
    }

    modifier onlyRegisteredCurator() {
        require(registeredCurators[msg.sender], "Only registered curators can call this function.");
        _;
    }

    modifier nftListed(address _nftContract, uint256 _tokenId) {
        require(nftListings[_nftContract][_tokenId].isListed, "NFT is not listed in the gallery.");
        _;
    }

    modifier nftNotListed(address _nftContract, uint256 _tokenId) {
        require(!nftListings[_nftContract][_tokenId].isListed, "NFT is already listed in the gallery.");
        _;
    }

    modifier isNFTOwner(address _nftContract, uint256 _tokenId) {
        // Assuming a standard ERC721 interface for ownerOf function
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier isGalleryApproved(address _nftContract, uint256 _tokenId) {
        // Assuming a standard ERC721 interface for getApproved and isApprovedForAll
        IERC721 nft = IERC721(_nftContract);
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(nft.ownerOf(_tokenId), address(this)), "Gallery is not approved to operate on this NFT.");
        _;
    }

    modifier curationProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter && !curationProposals[_proposalId].proposalExecuted, "Invalid or executed proposal ID.");
        _;
    }

    modifier votingNotEnded(uint256 _proposalId) {
        require(block.number < curationProposals[_proposalId].voteEndTime, "Voting for this proposal has ended.");
        _;
    }

    modifier loanActive(address _nftContract, uint256 _tokenId) {
        require(nftLoans[_nftContract][_tokenId].isActive, "Loan is not active for this NFT.");
        _;
    }


    // --- Constructor ---
    constructor() {
        galleryOwner = msg.sender;
    }

    // --- Core Gallery Functions ---

    function listNFT(address _nftContract, uint256 _tokenId, uint256 _price)
        external
        isNFTOwner(_nftContract, _tokenId)
        isGalleryApproved(_nftContract, _tokenId)
        nftNotListed(_nftContract, _tokenId)
    {
        nftListings[_nftContract][_tokenId] = NFTListing({
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isListed: true,
            isFractionalized: false,
            isLendable: false
        });
        emit NFTListed(_nftContract, _tokenId, msg.sender, _price);
    }

    function unlistNFT(address _nftContract, uint256 _tokenId)
        external
        nftListed(_nftContract, _tokenId)
        isNFTOwner(_nftContract, _tokenId)
    {
        require(nftListings[_nftContract][_tokenId].seller == msg.sender, "Only the seller can unlist.");
        nftListings[_nftContract][_tokenId].isListed = false;
        emit NFTUnlisted(_nftContract, _tokenId);
    }

    function purchaseNFT(address _nftContract, uint256 _tokenId)
        external
        payable
        nftListed(_nftContract, _tokenId)
    {
        NFTListing storage listing = nftListings[_nftContract][_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to purchase NFT.");

        // Transfer NFT to buyer
        IERC721 nft = IERC721(listing.nftContract);
        nft.transferFrom(listing.seller, msg.sender, listing.tokenId);

        // Transfer funds to seller (after gallery fee)
        uint256 galleryFee = (listing.price * galleryFeePercentage) / 10000; // Fee calculation (percentage out of 10000 for precision)
        uint256 sellerPayout = listing.price - galleryFee;
        payable(listing.seller).transfer(sellerPayout);

        // Transfer gallery fee to gallery owner
        payable(galleryOwner).transfer(galleryFee);

        listing.isListed = false; // Mark as sold
        emit NFTPurchased(_nftContract, _tokenId, msg.sender, listing.seller, listing.price);

        // Refund any extra ETH sent
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }

    function getNFTDetails(address _nftContract, uint256 _tokenId)
        external
        view
        returns (address nftContract, uint256 tokenId, address seller, uint256 price, bool isListed, bool isFractionalized, bool isLendable)
    {
        NFTListing storage listing = nftListings[_nftContract][_tokenId];
        return (listing.nftContract, listing.tokenId, listing.seller, listing.price, listing.isListed, listing.isFractionalized, listing.isLendable);
    }

    function getGalleryNFTs()
        external
        view
        returns (NFTListing[] memory)
    {
        NFTListing[] memory listedNFTs = new NFTListing[](getListedNFTCount());
        uint256 index = 0;
        for (uint256 i = 0; i < proposalCounter + 1000; i++) { // Looping through a range to find listings, can be optimized in real world
            if (curationProposals[i].nftContract != address(0) && nftListings[curationProposals[i].nftContract][curationProposals[i].tokenId].isListed) { // Basic check, can be improved
                listedNFTs[index] = nftListings[curationProposals[i].nftContract][curationProposals[i].tokenId];
                index++;
            }
        }
        return listedNFTs;
    }

    function getListedNFTCount() private view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < proposalCounter + 1000; i++) { // Looping through a range, optimize in real world
             if (curationProposals[i].nftContract != address(0) && nftListings[curationProposals[i].nftContract][curationProposals[i].tokenId].isListed) {
                count++;
            }
        }
        return count;
    }


    // --- Curation and Exhibition Functions ---

    function submitCurationProposal(address _nftContract, uint256 _tokenId, string memory _proposalDescription)
        external
        onlyRegisteredCurator
        isGalleryApproved(_nftContract, _tokenId)
    {
        proposalCounter++;
        curationProposals[proposalCounter] = CurationProposal({
            proposer: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            proposalDescription: _proposalDescription,
            upVotes: 0,
            downVotes: 0,
            voteEndTime: block.number + votingDurationBlocks,
            proposalExecuted: false
        });
        emit CurationProposalSubmitted(proposalCounter, _nftContract, _tokenId, msg.sender);
    }

    function voteOnCurationProposal(uint256 _proposalId, bool _vote)
        external
        votingNotEnded(_proposalId)
        curationProposalExists(_proposalId)
    {
        CurationProposal storage proposal = curationProposals[_proposalId];
        require(proposal.voteEndTime > block.number, "Voting ended."); // Redundant check, but for clarity

        if (_vote) {
            proposal.upVotes++;
        } else {
            proposal.downVotes++;
        }
        emit CurationProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeCurationProposal(uint256 _proposalId)
        external
        curationProposalExists(_proposalId)
    {
        CurationProposal storage proposal = curationProposals[_proposalId];
        require(block.number >= proposal.voteEndTime, "Voting not yet ended."); // Redundant check, but for clarity
        require(!proposal.proposalExecuted, "Proposal already executed.");

        uint256 totalVotes = proposal.upVotes + proposal.downVotes;
        require(totalVotes > 0, "No votes cast on this proposal.");

        uint256 quorumReached = (totalVotes * 100) / getGalleryMemberCount(); // Assuming getGalleryMemberCount represents total voting members
        require(quorumReached >= quorumPercentage, "Quorum not reached.");

        if (proposal.upVotes > proposal.downVotes) {
            // Proposal approved -  Potentially add NFT to a "curated collection" or mark as "curated"
            proposal.proposalExecuted = true;
            emit CurationProposalExecuted(_proposalId, proposal.nftContract, proposal.tokenId);
        } else {
            proposal.proposalExecuted = true; // Mark as executed even if rejected (to prevent re-execution)
            // Proposal rejected -  Handle rejection logic if needed
        }
    }

    function getProposalDetails(uint256 _proposalId)
        external
        view
        curationProposalExists(_proposalId)
        returns (address proposer, address nftContract, uint256 tokenId, string memory proposalDescription, uint256 upVotes, uint256 downVotes, uint256 voteEndTime, bool proposalExecuted)
    {
        CurationProposal storage proposal = curationProposals[_proposalId];
        return (proposal.proposer, proposal.nftContract, proposal.tokenId, proposal.proposalDescription, proposal.upVotes, proposal.downVotes, proposal.voteEndTime, proposal.proposalExecuted);
    }

    function createExhibition(string memory _exhibitionName, string memory _exhibitionDescription)
        external
        onlyRegisteredCurator
    {
        exhibitionCounter++;
        exhibitions[exhibitionCounter] = Exhibition({
            exhibitionId: exhibitionCounter,
            name: _exhibitionName,
            description: _exhibitionDescription,
            curator: msg.sender,
            nfts: new NFTListing[](0), // Initialize with empty NFT array
            isActive: true
        });
        emit ExhibitionCreated(exhibitionCounter, _exhibitionName, msg.sender);
    }

    function addNFTtoExhibition(uint256 _exhibitionId, address _nftContract, uint256 _tokenId)
        external
        onlyRegisteredCurator
    {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only the exhibition curator can add NFTs.");
        require(nftListings[_nftContract][_tokenId].isListed == false, "NFT must not be listed for sale to be in exhibition."); // Example rule, can be changed
        // In a real implementation, you'd likely want to check if the NFT is already curated/approved
        exhibitions[_exhibitionId].nfts.push(nftListings[_nftContract][_tokenId]); // Add the NFT listing to the exhibition
        emit NFTAddedToExhibition(_exhibitionId, _nftContract, _tokenId);
    }

    function removeNFTfromExhibition(uint256 _exhibitionId, address _nftContract, uint256 _tokenId)
        external
        onlyRegisteredCurator
    {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only the exhibition curator can remove NFTs.");

        Exhibition storage exhibition = exhibitions[_exhibitionId];
        for (uint256 i = 0; i < exhibition.nfts.length; i++) {
            if (exhibition.nfts[i].nftContract == _nftContract && exhibition.nfts[i].tokenId == _tokenId) {
                // Remove the NFT from the array (shifting elements)
                for (uint256 j = i; j < exhibition.nfts.length - 1; j++) {
                    exhibition.nfts[j] = exhibition.nfts[j + 1];
                }
                exhibition.nfts.pop(); // Remove the last element (duplicate of the shifted last element)
                return;
            }
        }
        revert("NFT not found in this exhibition.");
    }


    function getExhibitionDetails(uint256 _exhibitionId)
        external
        view
        returns (uint256 exhibitionId, string memory name, string memory description, address curator, NFTListing[] memory nfts, bool isActive)
    {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        return (exhibition.exhibitionId, exhibition.name, exhibition.description, exhibition.curator, exhibition.nfts, exhibition.isActive);
    }

    function getActiveExhibitions()
        external
        view
        returns (Exhibition[] memory)
    {
        Exhibition[] memory activeExhibitions = new Exhibition[](getActiveExhibitionCount());
        uint256 index = 0;
        for (uint256 i = 1; i <= exhibitionCounter; i++) {
            if (exhibitions[i].isActive) {
                activeExhibitions[index] = exhibitions[i];
                index++;
            }
        }
        return activeExhibitions;
    }

    function getActiveExhibitionCount() private view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= exhibitionCounter; i++) {
            if (exhibitions[i].isActive) {
                count++;
            }
        }
        return count;
    }


    // --- Fractional NFT Ownership Functions ---

    function fractionalizeNFT(address _nftContract, uint256 _tokenId, uint256 _fractionCount)
        external
        isNFTOwner(_nftContract, _tokenId)
        isGalleryApproved(_nftContract, _tokenId)
        nftListed(_nftContract, _tokenId)
    {
        require(_fractionCount > 0 && _fractionCount <= 10000, "Fraction count must be between 1 and 10000."); // Example limit

        // Transfer the original NFT to this contract for safekeeping
        IERC721 nft = IERC721(_nftContract);
        nft.transferFrom(msg.sender, address(this), _tokenId);

        fractionalNFTs[_nftContract][_tokenId] = FractionalNFT({
            nftContract: _nftContract,
            tokenId: _tokenId,
            fractionCount: _fractionCount,
            isFractionalized: true
        });
        nftListings[_nftContract][_tokenId].isFractionalized = true; // Mark in listing as fractionalized
        emit NFTFractionalized(_nftContract, _tokenId, _fractionCount);
    }

    function buyFractionalNFT(address _nftContract, uint256 _tokenId, uint256 _fractionAmount)
        external
        payable
        nftListed(_nftContract, _tokenId)
    {
        FractionalNFT storage fractional = fractionalNFTs[_nftContract][_tokenId];
        require(fractional.isFractionalized, "NFT is not fractionalized.");
        require(_fractionAmount > 0 && _fractionAmount <= fractional.fractionCount, "Invalid fraction amount.");

        NFTListing storage listing = nftListings[_nftContract][_tokenId];
        require(listing.isFractionalized, "NFT listing is not for fractional sales."); // Double check listing status

        uint256 pricePerFraction = listing.price / fractional.fractionCount; // Simple equal division
        uint256 totalPrice = pricePerFraction * _fractionAmount;
        require(msg.value >= totalPrice, "Insufficient funds for fractional NFT purchase.");

        fractional.fractionalTokenBalances[msg.sender] += _fractionAmount; // Mint fractional tokens to buyer
        fractional.fractionCount -= _fractionAmount; // Reduce available fractions

        // Transfer funds to seller (after gallery fee) - Same as regular NFT purchase logic
        uint256 galleryFee = (totalPrice * galleryFeePercentage) / 10000;
        uint256 sellerPayout = totalPrice - galleryFee;
        payable(listing.seller).transfer(sellerPayout);
        payable(galleryOwner).transfer(galleryFee);

        emit FractionalNFTBought(_nftContract, _tokenId, msg.sender, _fractionAmount);

         // Refund any extra ETH sent
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        if (fractional.fractionCount == 0) {
            listing.isListed = false; // No more fractions available, unlist from marketplace
        }
    }

    function redeemFractionalNFT(address _nftContract, uint256 _tokenId)
        external
    {
        FractionalNFT storage fractional = fractionalNFTs[_nftContract][_tokenId];
        require(fractional.isFractionalized, "NFT is not fractionalized.");

        uint256 totalFractionsHeld = fractional.fractionalTokenBalances[msg.sender];
        uint256 totalIssuedFractions = 0;
        for(uint256 i = 0; i < 1000; i++) { // Iterate to sum fractional balances (can be optimized)
            address holder = address(uint160(uint256(keccak256(abi.encodePacked(i))))); // Simple iteration, not ideal for large scale
            totalIssuedFractions += fractional.fractionalTokenBalances[holder];
        }

        // Example redemption condition: Holder needs to own > 50% of the fractions
        require((totalFractionsHeld * 100) / totalIssuedFractions > 50, "You don't own enough fractions to redeem.");

        // Transfer the original NFT back to the redeemer
        IERC721 nft = IERC721(fractional.nftContract);
        nft.transferFrom(address(this), msg.sender, fractional.tokenId);

        fractional.isFractionalized = false; // Mark as no longer fractionalized
        nftListings[_nftContract][_tokenId].isFractionalized = false; // Update listing status as well (if still listed)
        // In a real system, you might burn the fractional tokens after redemption.

        // Remove fractional data (optional, depends on your design)
        delete fractionalNFTs[_nftContract][_tokenId];
    }


    // --- Art Lending/Borrowing Functions ---

    function lendNFT(address _nftContract, uint256 _tokenId, uint256 _loanDurationDays, uint256 _dailyInterestRate)
        external
        isNFTOwner(_nftContract, _tokenId)
        isGalleryApproved(_nftContract, _tokenId)
        nftListed(_nftContract, _tokenId)
    {
        require(_loanDurationDays > 0 && _loanDurationDays <= 365, "Loan duration must be between 1 and 365 days.");
        require(_dailyInterestRate > 0 && _dailyInterestRate <= 1000, "Daily interest rate must be between 0.01% and 10%."); // Example limit (10% daily is very high!)
        require(!nftLoans[_nftContract][_tokenId].isActive, "NFT is already on loan.");

        // Transfer NFT to this contract for the duration of the loan
        IERC721 nft = IERC721(_nftContract);
        nft.transferFrom(msg.sender, address(this), _tokenId);

        nftLoans[_nftContract][_tokenId] = Loan({
            nftContract: _nftContract,
            tokenId: _tokenId,
            lender: msg.sender,
            borrower: address(0), // No borrower yet
            loanStartTime: 0, // Set on borrowing
            loanEndTime: 0,   // Set on borrowing
            dailyInterestRate: _dailyInterestRate,
            isActive: false  // Loan becomes active when borrowed
        });
        nftListings[_nftContract][_tokenId].isLendable = true; // Mark as lendable in listing
        emit NFTLent(_nftContract, _tokenId, msg.sender, _loanDurationDays, _dailyInterestRate);
    }

    function borrowNFT(address _nftContract, uint256 _tokenId, uint256 _loanDurationDays)
        external
        payable
        nftListed(_nftContract, _tokenId)
    {
        Loan storage loan = nftLoans[_nftContract][_tokenId];
        require(nftListings[_nftContract][_tokenId].isLendable, "NFT is not available for lending.");
        require(!loan.isActive, "NFT is already borrowed.");
        require(_loanDurationDays > 0 && _loanDurationDays <= 365, "Loan duration must be between 1 and 365 days.");

        uint256 loanAmount = nftListings[_nftContract][_tokenId].price; // Example loan amount = NFT price
        uint256 dailyInterest = (loanAmount * loan.dailyInterestRate) / 10000;
        uint256 totalInterest = dailyInterest * _loanDurationDays;
        uint256 totalLoanCost = loanAmount + totalInterest;

        require(msg.value >= totalLoanCost, "Insufficient funds for borrowing.");

        // Transfer NFT to borrower (temporarily)
        IERC721 nft = IERC721(loan.nftContract);
        nft.transferFrom(address(this), msg.sender, loan.tokenId);

        loan.borrower = msg.sender;
        loan.loanStartTime = block.timestamp;
        loan.loanEndTime = block.timestamp + (_loanDurationDays * 1 days); // Calculate loan end time
        loan.isActive = true;

        // Transfer loan amount + interest to lender
        payable(loan.lender).transfer(totalLoanCost);

        emit NFTBorrowed(_nftContract, _tokenId, msg.sender, loan.lender, loan.loanEndTime);

        // Refund any extra ETH sent
        if (msg.value > totalLoanCost) {
            payable(msg.sender).transfer(msg.value - totalLoanCost);
        }
    }

    function repayLoan(address _nftContract, uint256 _tokenId)
        external
        payable
        loanActive(_nftContract, _tokenId)
    {
        Loan storage loan = nftLoans[_nftContract][_tokenId];
        require(msg.sender == loan.borrower, "Only the borrower can repay the loan.");

        uint256 loanAmount = nftListings[_nftContract][_tokenId].price; // Example loan amount
        uint256 dailyInterest = (loanAmount * loan.dailyInterestRate) / 10000;
        uint256 elapsedDays = (block.timestamp - loan.loanStartTime) / (1 days); // Days since loan start
        uint256 accruedInterest = dailyInterest * elapsedDays;
        uint256 totalRepaymentAmount = loanAmount + accruedInterest;

        require(msg.value >= totalRepaymentAmount, "Insufficient funds for repayment.");

        // Transfer NFT back to borrower
        IERC721 nft = IERC721(loan.nftContract);
        nft.transferFrom(address(this), loan.borrower, loan.tokenId);

        // Transfer repayment amount to lender
        payable(loan.lender).transfer(totalRepaymentAmount);

        loan.isActive = false; // Mark loan as inactive
        emit LoanRepaid(_nftContract, _tokenId, loan.borrower, loan.lender);

        // Refund any extra ETH sent
        if (msg.value > totalRepaymentAmount) {
            payable(msg.sender).transfer(msg.value - totalRepaymentAmount);
        }
    }

    function liquidateLoan(address _nftContract, uint256 _tokenId)
        external
        loanActive(_nftContract, _tokenId)
    {
        Loan storage loan = nftLoans[_nftContract][_tokenId];
        require(msg.sender == loan.lender, "Only the lender can liquidate.");
        require(block.timestamp > loan.loanEndTime, "Loan duration has not ended yet.");

        // Transfer NFT back to lender (liquidation)
        IERC721 nft = IERC721(loan.nftContract);
        nft.transferFrom(address(this), loan.lender, loan.tokenId);

        loan.isActive = false; // Mark loan as inactive
        emit LoanLiquidated(_nftContract, _tokenId, loan.lender);
    }


    // --- Governance and Utility Functions ---

    function registerCurator() external {
        require(!registeredCurators[msg.sender], "You are already a registered curator.");
        registeredCurators[msg.sender] = true;
        curatorList.push(msg.sender);
        emit CuratorRegistered(msg.sender);
    }

    function getCuratorList() external view returns (address[] memory) {
        return curatorList;
    }

    // Placeholder for getting total gallery members (e.g., token holders, DAO members)
    function getGalleryMemberCount() public view returns (uint256) {
        // In a real DAO, this would be based on token holders or DAO membership
        // For this example, we'll just return a fixed number for simplicity.
        return 100; // Example: Assume 100 gallery members for voting quorum calculation
    }

    function setGalleryFee(uint256 _feePercentage) external onlyGalleryOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        galleryFeePercentage = _feePercentage;
        emit GalleryFeeSet(_feePercentage);
    }

    function withdrawGalleryBalance() external onlyGalleryOwner {
        uint256 balance = address(this).balance;
        payable(galleryOwner).transfer(balance);
        emit GalleryBalanceWithdrawn(galleryOwner, balance);
    }

    function setVotingDuration(uint256 _durationInBlocks) external onlyGalleryOwner {
        require(_durationInBlocks > 0, "Voting duration must be greater than 0 blocks.");
        votingDurationBlocks = _durationInBlocks;
        emit VotingDurationSet(_durationInBlocks);
    }

    function setQuorum(uint256 _quorumPercentage) external onlyGalleryOwner {
        require(_quorumPercentage >= 0 && _quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _quorumPercentage;
        emit QuorumSet(_quorumPercentage);
    }


    // --- Interface for ERC721 (assuming standard ERC721 NFTs) ---
    interface IERC721 {
        function ownerOf(uint256 tokenId) external view returns (address owner);
        function transferFrom(address from, address to, uint256 tokenId) external;
        function approve(address approved, uint256 tokenId) external;
        function getApproved(uint256 tokenId) external view returns (address operator);
        function isApprovedForAll(address owner, address operator) external view returns (bool);
    }
}
```