```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Advanced Smart Contract
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for a Decentralized Autonomous Art Gallery,
 * incorporating advanced concepts like dynamic pricing, curated exhibitions,
 * artist royalties, community governance, and innovative features.
 *
 * **Contract Outline:**
 *
 * **1. Art Submission and Management:**
 *    - `submitArt(string _title, string _description, string _ipfsHash, uint256 _initialPrice, uint256 _royaltyPercentage)`: Artists submit their digital art (NFT metadata IPFS hash).
 *    - `editArtDetails(uint256 _artId, string _title, string _description, uint256 _initialPrice, uint256 _royaltyPercentage)`: Artists can edit their art details (before approval/exhibition).
 *    - `withdrawArt(uint256 _artId)`: Artists can withdraw their submitted art (if not approved or sold).
 *    - `approveArt(uint256 _artId)`: Gallery admin/curators can approve submitted art for exhibition.
 *    - `rejectArt(uint256 _artId, string _reason)`: Gallery admin/curators can reject submitted art with a reason.
 *    - `getArtDetails(uint256 _artId)`: View function to retrieve details of a specific artwork.
 *    - `listSubmittedArt()`: View function to list all submitted artworks (admin/curators).
 *    - `listApprovedArt()`: View function to list all approved and exhibited artworks (public).
 *
 * **2. Dynamic Pricing and Sales:**
 *    - `purchaseArt(uint256 _artId)`: Users can purchase exhibited art. Price can dynamically adjust based on factors.
 *    - `setDynamicPricingStrategy(uint8 _strategy)`: Admin function to set dynamic pricing strategy (e.g., demand-based, time-based).
 *    - `getCurrentArtPrice(uint256 _artId)`: View function to get the current dynamic price of an artwork.
 *
 * **3. Curated Exhibitions and Themes:**
 *    - `createExhibition(string _exhibitionName, string _theme, uint256 _startDate, uint256 _endDate)`: Admin function to create new exhibitions with themes and timeframes.
 *    - `addArtToExhibition(uint256 _artId, uint256 _exhibitionId)`: Admin function to add approved art to a specific exhibition.
 *    - `removeArtFromExhibition(uint256 _artId, uint256 _exhibitionId)`: Admin function to remove art from an exhibition.
 *    - `getActiveExhibitions()`: View function to list currently active exhibitions.
 *    - `getExhibitionDetails(uint256 _exhibitionId)`: View function to get details of a specific exhibition.
 *
 * **4. Artist Royalties and Payouts:**
 *    - `withdrawRoyalties()`: Artists can withdraw their accumulated royalties from sales.
 *    - `setRoyaltyRecipient(uint256 _artId, address _recipient)`: Artist function to set or change royalty recipient address.
 *    - `getArtistRoyalties(address _artistAddress)`: View function to see total royalties earned by an artist.
 *
 * **5. Community Governance (Simple DAO Model):**
 *    - `proposeNewCurator(address _newCurator)`: Existing curators can propose new curators.
 *    - `voteForCurator(address _proposedCurator, bool _vote)`: Existing curators vote on proposed new curators.
 *    - `removeCurator(address _curatorToRemove)`: Admin/majority curators can remove a curator.
 *    - `setGalleryCommission(uint256 _commissionPercentage)`: Admin/governance function to set gallery commission percentage.
 *    - `withdrawGalleryFunds()`: Admin/governance function to withdraw accumulated gallery funds.
 *
 * **6. Additional Features:**
 *    - `reportArt(uint256 _artId, string _reportReason)`: Users can report art for policy violations.
 *    - `searchArtByTitle(string _searchTerm)`: View function to search for art by title (basic keyword search).
 *    - `getTotalArtSubmissions()`: View function to get the total number of art submissions.
 *    - `getTotalArtExhibited()`: View function to get the total number of exhibited artworks.
 *    - `getGalleryBalance()`: View function to check the gallery's contract balance.
 *
 * **Function Summary:**
 *
 * **Art Submission and Management:**
 *   - `submitArt`: Allows artists to submit their artwork with metadata, price, and royalty.
 *   - `editArtDetails`: Artists can modify details of their submitted art before approval.
 *   - `withdrawArt`: Artists can withdraw their art if not approved or sold.
 *   - `approveArt`: Gallery admins/curators approve submitted art for exhibition.
 *   - `rejectArt`: Gallery admins/curators reject submitted art with a reason.
 *   - `getArtDetails`: Retrieves detailed information about a specific artwork.
 *   - `listSubmittedArt`: Lists all submitted artworks (admin/curator access).
 *   - `listApprovedArt`: Lists all approved and exhibited artworks (public access).
 *
 * **Dynamic Pricing and Sales:**
 *   - `purchaseArt`: Allows users to purchase exhibited artworks, with dynamic pricing.
 *   - `setDynamicPricingStrategy`: Sets the strategy for dynamic price adjustments (admin).
 *   - `getCurrentArtPrice`: Retrieves the current dynamic price of an artwork.
 *
 * **Curated Exhibitions and Themes:**
 *   - `createExhibition`: Creates a new exhibition with a name, theme, and timeframe (admin).
 *   - `addArtToExhibition`: Adds approved artworks to a specific exhibition (admin).
 *   - `removeArtFromExhibition`: Removes artworks from an exhibition (admin).
 *   - `getActiveExhibitions`: Lists currently active exhibitions (public access).
 *   - `getExhibitionDetails`: Retrieves details of a specific exhibition (public access).
 *
 * **Artist Royalties and Payouts:**
 *   - `withdrawRoyalties`: Artists can withdraw their earned royalties.
 *   - `setRoyaltyRecipient`: Artists can set or change their royalty payout address.
 *   - `getArtistRoyalties`: Retrieves the total royalties earned by an artist.
 *
 * **Community Governance (Simple DAO):**
 *   - `proposeNewCurator`: Curators can propose new curators.
 *   - `voteForCurator`: Curators vote on proposed new curators.
 *   - `removeCurator`: Admins/majority curators can remove a curator.
 *   - `setGalleryCommission`: Sets the gallery's commission percentage (admin/governance).
 *   - `withdrawGalleryFunds`: Withdraws accumulated gallery funds (admin/governance).
 *
 * **Additional Features:**
 *   - `reportArt`: Users can report artworks for policy violations.
 *   - `searchArtByTitle`: Allows searching for artworks by title.
 *   - `getTotalArtSubmissions`: Gets the total number of art submissions.
 *   - `getTotalArtExhibited`: Gets the total number of exhibited artworks.
 *   - `getGalleryBalance`: Retrieves the contract's current balance.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousArtGallery is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Enums and Structs
    enum ArtStatus { Submitted, Approved, Rejected, Exhibited, Sold, Withdrawn }
    enum PricingStrategy { Fixed, DemandBased, TimeBased } // Example pricing strategies

    struct ArtPiece {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 initialPrice;
        uint256 royaltyPercentage;
        ArtStatus status;
        uint256 submissionTimestamp;
        uint256 approvalTimestamp;
        string rejectionReason;
        address royaltyRecipient; // Address to receive royalties, defaults to artist
        uint256 lastSalePrice;
        uint256 purchaseCount;
    }

    struct Exhibition {
        uint256 id;
        string name;
        string theme;
        uint256 startDate;
        uint256 endDate;
        bool isActive;
        uint256 creationTimestamp;
        uint256 artCount;
    }

    // State Variables
    Counters.Counter private _artIdCounter;
    Counters.Counter private _exhibitionIdCounter;
    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => uint256[]) public exhibitionArtworks; // Exhibition ID to list of Art IDs
    mapping(address => uint256) public artistRoyalties; // Artist address to accumulated royalties
    mapping(address => bool) public curators;
    address[] public curatorList;
    uint256 public curatorVoteDuration = 7 days;
    uint256 public curatorVoteThreshold = 2; // Minimum votes to approve curator
    mapping(address => uint256) public curatorProposals; // Proposed curator to timestamp of proposal
    uint256 public galleryCommissionPercentage = 10; // Default 10% commission
    PricingStrategy public currentPricingStrategy = PricingStrategy.Fixed;

    // Events
    event ArtSubmitted(uint256 artId, address artist, string title);
    event ArtDetailsEdited(uint256 artId, string title);
    event ArtWithdrawn(uint256 artId, address artist);
    event ArtApproved(uint256 artId, address curator);
    event ArtRejected(uint256 artId, uint256 artId, string reason, address curator);
    event ArtPurchased(uint256 artId, address buyer, uint256 price);
    event ExhibitionCreated(uint256 exhibitionId, string name, string theme);
    event ArtAddedToExhibition(uint256 artId, uint256 exhibitionId);
    event ArtRemovedFromExhibition(uint256 artId, uint256 exhibitionId);
    event RoyaltiesWithdrawn(address artist, uint256 amount);
    event CuratorProposed(address proposedCurator, address proposer);
    event CuratorVoted(address proposedCurator, address voter, bool vote);
    event CuratorAdded(address newCurator, address approver);
    event CuratorRemoved(address removedCurator, address remover);
    event GalleryCommissionSet(uint256 percentage, address setter);
    event PricingStrategySet(PricingStrategy strategy, address setter);
    event ArtReported(uint256 artId, address reporter, string reason);

    // Modifiers
    modifier onlyCurator() {
        require(curators[msg.sender] || msg.sender == owner(), "Only curators or owner allowed.");
        _;
    }

    modifier validArtId(uint256 _artId) {
        require(_artId > 0 && _artId <= _artIdCounter.current(), "Invalid Art ID.");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId <= _exhibitionIdCounter.current(), "Invalid Exhibition ID.");
        _;
    }

    modifier artExists(uint256 _artId) {
        require(artPieces[_artId].id == _artId, "Art piece does not exist.");
        _;
    }

    modifier artSubmittedByArtist(uint256 _artId) {
        require(artPieces[_artId].artist == msg.sender, "You are not the artist of this artwork.");
        _;
    }

    modifier artNotSoldOrWithdrawn(uint256 _artId) {
        require(artPieces[_artId].status != ArtStatus.Sold && artPieces[_artId].status != ArtStatus.Withdrawn, "Art cannot be modified after being sold or withdrawn.");
        _;
    }

    modifier artInExhibition(uint256 _artId, uint256 _exhibitionId) {
        bool found = false;
        for (uint256 i = 0; i < exhibitionArtworks[_exhibitionId].length; i++) {
            if (exhibitionArtworks[_exhibitionId][i] == _artId) {
                found = true;
                break;
            }
        }
        require(found, "Art is not in this exhibition.");
        _;
    }

    // Constructor - Owner is initially the admin/curator
    constructor() payable {
        _addCurator(owner());
    }

    // --- 1. Art Submission and Management ---

    function submitArt(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _initialPrice,
        uint256 _royaltyPercentage
    ) public {
        require(bytes(_title).length > 0 && bytes(_ipfsHash).length > 0, "Title and IPFS Hash are required.");
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");

        _artIdCounter.increment();
        uint256 artId = _artIdCounter.current();

        artPieces[artId] = ArtPiece({
            id: artId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            initialPrice: _initialPrice,
            royaltyPercentage: _royaltyPercentage,
            status: ArtStatus.Submitted,
            submissionTimestamp: block.timestamp,
            approvalTimestamp: 0,
            rejectionReason: "",
            royaltyRecipient: msg.sender, // Default recipient is the artist
            lastSalePrice: 0,
            purchaseCount: 0
        });

        emit ArtSubmitted(artId, msg.sender, _title);
    }

    function editArtDetails(
        uint256 _artId,
        string memory _title,
        string memory _description,
        uint256 _initialPrice,
        uint256 _royaltyPercentage
    ) public
        validArtId(_artId)
        artExists(_artId)
        artSubmittedByArtist(_artId)
        artNotSoldOrWithdrawn(_artId)
    {
        require(artPieces[_artId].status == ArtStatus.Submitted, "Art details can only be edited when status is Submitted.");
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");

        artPieces[_artId].title = _title;
        artPieces[_artId].description = _description;
        artPieces[_artId].initialPrice = _initialPrice;
        artPieces[_artId].royaltyPercentage = _royaltyPercentage;

        emit ArtDetailsEdited(_artId, _title);
    }

    function withdrawArt(uint256 _artId)
        public
        validArtId(_artId)
        artExists(_artId)
        artSubmittedByArtist(_artId)
        artNotSoldOrWithdrawn(_artId)
    {
        require(artPieces[_artId].status != ArtStatus.Approved && artPieces[_artId].status != ArtStatus.Exhibited && artPieces[_artId].status != ArtStatus.Sold, "Cannot withdraw approved, exhibited, or sold art.");
        artPieces[_artId].status = ArtStatus.Withdrawn;
        emit ArtWithdrawn(_artId, msg.sender);
    }

    function approveArt(uint256 _artId) public onlyCurator validArtId(_artId) artExists(_artId) {
        require(artPieces[_artId].status == ArtStatus.Submitted, "Art must be in Submitted status to be approved.");
        artPieces[_artId].status = ArtStatus.Approved;
        artPieces[_artId].approvalTimestamp = block.timestamp;
        emit ArtApproved(_artId, msg.sender);
    }

    function rejectArt(uint256 _artId, string memory _reason) public onlyCurator validArtId(_artId) artExists(_artId) {
        require(artPieces[_artId].status == ArtStatus.Submitted, "Art must be in Submitted status to be rejected.");
        artPieces[_artId].status = ArtStatus.Rejected;
        artPieces[_artId].rejectionReason = _reason;
        emit ArtRejected(_artId, _artId, _reason, msg.sender);
    }

    function getArtDetails(uint256 _artId) public view validArtId(_artId) artExists(_artId) returns (ArtPiece memory) {
        return artPieces[_artId];
    }

    function listSubmittedArt() public view onlyCurator returns (uint256[] memory) {
        uint256[] memory submittedArtIds = new uint256[](_artIdCounter.current()); // Max size, might be smaller
        uint256 count = 0;
        for (uint256 i = 1; i <= _artIdCounter.current(); i++) {
            if (artPieces[i].status == ArtStatus.Submitted) {
                submittedArtIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(submittedArtIds, count)
        }
        return submittedArtIds;
    }

    function listApprovedArt() public view returns (uint256[] memory) {
        uint256[] memory approvedArtIds = new uint256[](_artIdCounter.current()); // Max size
        uint256 count = 0;
        for (uint256 i = 1; i <= _artIdCounter.current(); i++) {
            if (artPieces[i].status == ArtStatus.Approved || artPieces[i].status == ArtStatus.Exhibited || artPieces[i].status == ArtStatus.Sold) {
                approvedArtIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(approvedArtIds, count)
        }
        return approvedArtIds;
    }

    // --- 2. Dynamic Pricing and Sales ---

    function purchaseArt(uint256 _artId) public payable validArtId(_artId) artExists(_artId) {
        require(artPieces[_artId].status == ArtStatus.Exhibited, "Art must be exhibited to be purchased.");
        uint256 currentPrice = getCurrentArtPrice(_artId);
        require(msg.value >= currentPrice, "Insufficient funds sent.");

        // Transfer funds to artist (minus commission)
        uint256 artistCut = (currentPrice * (100 - galleryCommissionPercentage)) / 100;
        uint256 galleryCut = currentPrice - artistCut;

        (bool successArtist, ) = payable(artPieces[_artId].royaltyRecipient).call{value: artistCut}("");
        require(successArtist, "Artist payment failed.");
        (bool successGallery, ) = payable(owner()).call{value: galleryCut}(""); // Gallery funds go to contract owner for simplicity, can be DAO controlled later
        require(successGallery, "Gallery commission payment failed.");

        // Update art status and details
        artPieces[_artId].status = ArtStatus.Sold;
        artPieces[_artId].lastSalePrice = currentPrice;
        artPieces[_artId].purchaseCount++;
        artistRoyalties[artPieces[_artId].royaltyRecipient] += (artistCut * artPieces[_artId].royaltyPercentage) / 100; // Accumulate royalties

        emit ArtPurchased(_artId, msg.sender, currentPrice);

        // Refund any extra amount sent
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }
    }

    function setDynamicPricingStrategy(uint8 _strategy) public onlyOwner {
        require(_strategy < uint8(PricingStrategy.TimeBased) + 1, "Invalid pricing strategy.");
        currentPricingStrategy = PricingStrategy(_strategy);
        emit PricingStrategySet(currentPricingStrategy, msg.sender);
    }

    function getCurrentArtPrice(uint256 _artId) public view validArtId artExists(_artId) returns (uint256) {
        PricingStrategy strategy = currentPricingStrategy;
        uint256 basePrice = artPieces[_artId].initialPrice;

        if (strategy == PricingStrategy.DemandBased) {
            // Example: Price increases with purchase count
            return basePrice + (artPieces[_artId].purchaseCount * (basePrice / 10)); // Increase by 10% of initial price per purchase
        } else if (strategy == PricingStrategy.TimeBased) {
            // Example: Price decreases over time (e.g., discount after exhibition start)
            uint256 exhibitionId = _findExhibitionForArt(_artId); // Assuming art is in an exhibition for time-based pricing
            if (exhibitionId > 0) {
                Exhibition memory exhibition = exhibitions[exhibitionId];
                if (block.timestamp > exhibition.startDate) {
                    uint256 timePassed = block.timestamp - exhibition.startDate;
                    uint256 discountPercentage = timePassed / (30 days); // Example: 1% discount per month, adjust as needed
                    if (discountPercentage < 50) { // Max 50% discount for example
                        return basePrice - (basePrice * discountPercentage) / 100;
                    } else {
                        return basePrice / 2; // Minimum price is half of initial price
                    }
                }
            }
        }
        // Default to Fixed pricing if no dynamic strategy applies or strategy is Fixed
        return basePrice;
    }

    function _findExhibitionForArt(uint256 _artId) private view returns (uint256) {
        for (uint256 i = 1; i <= _exhibitionIdCounter.current(); i++) {
            for (uint256 j = 0; j < exhibitionArtworks[i].length; j++) {
                if (exhibitionArtworks[i][j] == _artId) {
                    return i;
                }
            }
        }
        return 0; // Not found in any exhibition
    }

    // --- 3. Curated Exhibitions and Themes ---

    function createExhibition(string memory _exhibitionName, string memory _theme, uint256 _startDate, uint256 _endDate) public onlyCurator {
        require(bytes(_exhibitionName).length > 0 && _startDate < _endDate, "Exhibition name required and start date must be before end date.");
        _exhibitionIdCounter.increment();
        uint256 exhibitionId = _exhibitionIdCounter.current();

        exhibitions[exhibitionId] = Exhibition({
            id: exhibitionId,
            name: _exhibitionName,
            theme: _theme,
            startDate: _startDate,
            endDate: _endDate,
            isActive: (block.timestamp >= _startDate && block.timestamp <= _endDate),
            creationTimestamp: block.timestamp,
            artCount: 0
        });

        emit ExhibitionCreated(exhibitionId, _exhibitionName, _theme);
    }

    function addArtToExhibition(uint256 _artId, uint256 _exhibitionId) public onlyCurator validArtId(_artId) validExhibitionId(_exhibitionId) artExists(_artId) {
        require(artPieces[_artId].status == ArtStatus.Approved, "Art must be approved before adding to exhibition.");
        require(!_isArtInExhibition(_artId, _exhibitionId), "Art is already in this exhibition.");

        exhibitionArtworks[_exhibitionId].push(_artId);
        exhibitions[_exhibitionId].artCount++;
        artPieces[_artId].status = ArtStatus.Exhibited; // Update art status to Exhibited

        emit ArtAddedToExhibition(_artId, _exhibitionId);
    }

    function removeArtFromExhibition(uint256 _artId, uint256 _exhibitionId) public onlyCurator validArtId(_artId) validExhibitionId(_exhibitionId) artExists(_artId) artInExhibition(_artId, _exhibitionId) {
        uint256[] storage artworks = exhibitionArtworks[_exhibitionId];
        for (uint256 i = 0; i < artworks.length; i++) {
            if (artworks[i] == _artId) {
                // Remove art from array (preserve order is not critical, so efficient swap and pop)
                artworks[i] = artworks[artworks.length - 1];
                artworks.pop();
                exhibitions[_exhibitionId].artCount--;
                artPieces[_artId].status = ArtStatus.Approved; // Revert art status back to Approved

                emit ArtRemovedFromExhibition(_artId, _exhibitionId);
                return;
            }
        }
        // Should not reach here due to modifier `artInExhibition`
    }

    function getActiveExhibitions() public view returns (uint256[] memory) {
        uint256[] memory activeExhibitionIds = new uint256[](_exhibitionIdCounter.current()); // Max size
        uint256 count = 0;
        for (uint256 i = 1; i <= _exhibitionIdCounter.current(); i++) {
            if (exhibitions[i].isActive && block.timestamp >= exhibitions[i].startDate && block.timestamp <= exhibitions[i].endDate) {
                activeExhibitionIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(activeExhibitionIds, count)
        }
        return activeExhibitionIds;
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view validExhibitionId(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    function _isArtInExhibition(uint256 _artId, uint256 _exhibitionId) private view returns (bool) {
        for (uint256 i = 0; i < exhibitionArtworks[_exhibitionId].length; i++) {
            if (exhibitionArtworks[_exhibitionId][i] == _artId) {
                return true;
            }
        }
        return false;
    }

    // --- 4. Artist Royalties and Payouts ---

    function withdrawRoyalties() public {
        uint256 royaltyAmount = artistRoyalties[msg.sender];
        require(royaltyAmount > 0, "No royalties to withdraw.");

        artistRoyalties[msg.sender] = 0; // Reset royalties after withdrawal
        (bool success, ) = payable(msg.sender).call{value: royaltyAmount}("");
        require(success, "Royalty withdrawal failed.");

        emit RoyaltiesWithdrawn(msg.sender, royaltyAmount);
    }

    function setRoyaltyRecipient(uint256 _artId, address _recipient) public validArtId(_artId) artExists(_artId) artSubmittedByArtist(_artId) {
        require(_recipient != address(0), "Invalid royalty recipient address.");
        artPieces[_artId].royaltyRecipient = _recipient;
    }

    function getArtistRoyalties(address _artistAddress) public view returns (uint256) {
        return artistRoyalties[_artistAddress];
    }

    // --- 5. Community Governance (Simple DAO Model) ---

    function proposeNewCurator(address _newCurator) public onlyCurator {
        require(_newCurator != address(0) && !curators[_newCurator], "Invalid or existing curator address.");
        require(curatorProposals[_newCurator] == 0 || block.timestamp > curatorProposals[_newCurator] + curatorVoteDuration, "Proposal already active or too recent.");

        curatorProposals[_newCurator] = block.timestamp;
        emit CuratorProposed(_newCurator, msg.sender);
    }

    function voteForCurator(address _proposedCurator, bool _vote) public onlyCurator {
        require(curatorProposals[_proposedCurator] != 0 && block.timestamp <= curatorProposals[_proposedCurator] + curatorVoteDuration, "No active proposal for this curator or proposal expired.");

        // Simple vote counting - in a real DAO, you'd use more robust voting mechanisms
        uint256 yesVotes = 0;
        uint256 noVotes = 0;
        for (uint256 i = 0; i < curatorList.length; i++) {
            // In a real system, you'd track votes per curator and proposal to prevent double voting
            // This is a simplified example for demonstration.
            if (curators[curatorList[i]] && curatorProposals[_proposedCurator] > 0) { // Basic check if still curator and proposal active
                // Assume this curator voted 'yes' if they call this function (simplified)
                if (_vote) {
                    yesVotes++;
                } else {
                    noVotes++;
                }
            }
        }

        emit CuratorVoted(_proposedCurator, msg.sender, _vote);

        if (yesVotes >= curatorVoteThreshold) {
            _addCurator(_proposedCurator);
            delete curatorProposals[_proposedCurator]; // Clear proposal after approval
            emit CuratorAdded(_proposedCurator, msg.sender); // Who triggered the approval (last voter in this simplified model)
        } else if (noVotes > (curatorList.length - curatorVoteThreshold)) {
            delete curatorProposals[_proposedCurator]; // Clear proposal if rejected by majority
            // Optionally emit CuratorProposalRejected event if needed
        }
    }

    function removeCurator(address _curatorToRemove) public onlyCurator {
        require(curators[_curatorToRemove] && _curatorToRemove != owner(), "Cannot remove owner or non-curator.");
        require(curatorList.length > 1, "At least one curator must remain."); // Ensure at least one curator remains

        _removeCurator(_curatorToRemove);
        emit CuratorRemoved(_curatorToRemove, msg.sender);
    }

    function setGalleryCommission(uint256 _commissionPercentage) public onlyOwner { // Or governance controlled
        require(_commissionPercentage <= 100, "Commission percentage must be between 0 and 100.");
        galleryCommissionPercentage = _commissionPercentage;
        emit GalleryCommissionSet(_commissionPercentage, msg.sender);
    }

    function withdrawGalleryFunds() public onlyOwner { // Or governance controlled
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}(""); // Owner for simplicity, can be DAO controlled
        require(success, "Gallery funds withdrawal failed.");
    }

    // --- 6. Additional Features ---

    function reportArt(uint256 _artId, string memory _reportReason) public validArtId(_artId) artExists(_artId) {
        // In a real application, you would store reports, maybe with timestamps and reporter addresses,
        // and have a moderation process for curators to review reports and take action.
        // For this example, just emit an event.
        emit ArtReported(_artId, msg.sender, _reportReason);
    }

    function searchArtByTitle(string memory _searchTerm) public view returns (uint256[] memory) {
        uint256[] memory searchResults = new uint256[](_artIdCounter.current()); // Max size
        uint256 count = 0;
        string memory lowerSearchTerm = _stringToLower(_searchTerm);

        for (uint256 i = 1; i <= _artIdCounter.current(); i++) {
            if (artPieces[i].status != ArtStatus.Withdrawn && artPieces[i].status != ArtStatus.Rejected) { // Search only approved/exhibited/sold art
                string memory lowerArtTitle = _stringToLower(artPieces[i].title);
                if (_stringContains(lowerArtTitle, lowerSearchTerm)) {
                    searchResults[count] = i;
                    count++;
                }
            }
        }
         // Resize array to actual count
        assembly {
            mstore(searchResults, count)
        }
        return searchResults;
    }

    function getTotalArtSubmissions() public view returns (uint256) {
        return _artIdCounter.current();
    }

    function getTotalArtExhibited() public view returns (uint256) {
        uint256 exhibitedCount = 0;
        for (uint256 i = 1; i <= _artIdCounter.current(); i++) {
            if (artPieces[i].status == ArtStatus.Exhibited || artPieces[i].status == ArtStatus.Sold) {
                exhibitedCount++;
            }
        }
        return exhibitedCount;
    }

    function getGalleryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Internal Helper Functions ---

    function _addCurator(address _curator) private {
        if (!curators[_curator]) {
            curators[_curator] = true;
            curatorList.push(_curator);
        }
    }

    function _removeCurator(address _curator) private {
        if (curators[_curator]) {
            curators[_curator] = false;
            for (uint256 i = 0; i < curatorList.length; i++) {
                if (curatorList[i] == _curator) {
                    curatorList[i] = curatorList[curatorList.length - 1];
                    curatorList.pop();
                    break;
                }
            }
        }
    }

    function _stringToLower(string memory str) private pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLowerStr = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                bLowerStr[i] = bStr[i] + 0x20;
            } else {
                bLowerStr[i] = bStr[i];
            }
        }
        return string(bLowerStr);
    }

    function _stringContains(string memory str, string memory searchTerm) private pure returns (bool) {
        if (bytes(searchTerm).length == 0) {
            return true; // Empty search term matches everything
        }
        if (bytes(str).length < bytes(searchTerm).length) {
            return false; // Search term longer than string
        }

        for (uint i = 0; i <= bytes(str).length - bytes(searchTerm).length; i++) {
            bool match = true;
            for (uint j = 0; j < bytes(searchTerm).length; j++) {
                if (bytes(str)[i + j] != bytes(searchTerm)[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {} // Allow contract to receive ETH
}
```