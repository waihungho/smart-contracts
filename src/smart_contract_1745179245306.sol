```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery, enabling artists to submit, curators to evaluate,
 *      and users to interact with digital art in a novel and engaging way. This contract incorporates advanced concepts
 *      like dynamic pricing, layered royalties, collaborative curation, on-chain reputation, and decentralized governance
 *      to create a unique and trendy art ecosystem.

 * **Contract Outline and Function Summary:**

 * **1. Gallery Management & Setup:**
 *    - `initializeGallery(string _galleryName, address _governanceToken)`: Initializes the gallery with a name and governance token address. (Once only)
 *    - `setGalleryFee(uint256 _feePercentage)`: Sets the gallery's platform fee percentage for art sales. (Admin/Governance)
 *    - `setCuratorNominationFee(uint256 _fee)`: Sets the fee required to nominate a curator. (Admin/Governance)
 *    - `setArtworkSubmissionFee(uint256 _fee)`: Sets the fee required to submit an artwork. (Admin/Governance)
 *    - `pauseGallery()`: Pauses core gallery functionalities (submission, curation, sales). (Admin/Governance)
 *    - `unpauseGallery()`: Resumes gallery functionalities after pausing. (Admin/Governance)

 * **2. Artist Management:**
 *    - `registerArtist(string _artistName)`: Registers a user as an artist in the gallery.
 *    - `updateArtistProfile(string _newArtistName)`: Allows artists to update their profile information.
 *    - `isRegisteredArtist(address _artistAddress) view returns (bool)`: Checks if an address is a registered artist.

 * **3. Curator Management & Nomination:**
 *    - `nominateCurator(address _potentialCurator, string _nominationReason)`: Allows registered artists to nominate users as curators.
 *    - `voteForCurator(address _nominatedCurator, bool _support)`: Allows current curators to vote on curator nominations.
 *    - `revokeCuratorStatus(address _curatorToRevoke)`: Allows governance to revoke curator status. (Governance)
 *    - `isCurator(address _curatorAddress) view returns (bool)`: Checks if an address is a current curator.
 *    - `getActiveCuratorCount() view returns (uint256)`: Returns the current number of active curators.

 * **4. Artwork Submission & Curation:**
 *    - `submitArtwork(string _artworkTitle, string _artworkDescription, string _artworkIPFSHash, uint256 _initialPrice)`: Artists submit their digital artwork for curation.
 *    - `updateArtworkMetadata(uint256 _artworkId, string _newArtworkTitle, string _newArtworkDescription, string _newArtworkIPFSHash)`: Artists can update their artwork metadata before curation.
 *    - `curateArtwork(uint256 _artworkId, bool _approve)`: Curators evaluate submitted artworks and approve or reject them.
 *    - `getArtworkStatus(uint256 _artworkId) view returns (ArtworkStatus)`: Retrieves the curation status of an artwork.
 *    - `getAllSubmittedArtworkIds() view returns (uint256[])`: Returns a list of IDs of all submitted artworks.
 *    - `getApprovedArtworkIds() view returns (uint256[])`: Returns a list of IDs of all approved artworks in the gallery.

 * **5. Artwork Sales & Dynamic Pricing:**
 *    - `purchaseArtwork(uint256 _artworkId)`: Allows users to purchase an approved artwork.
 *    - `setArtworkPrice(uint256 _artworkId, uint256 _newPrice)`: Artists can set or update the price of their approved artworks.
 *    - `getArtworkPrice(uint256 _artworkId) view returns (uint256)`: Retrieves the current price of an artwork.
 *    - `adjustArtworkPriceDynamically(uint256 _artworkId)`: (Advanced) Dynamically adjusts artwork price based on factors like view count, time listed, etc. (Example logic included).

 * **6. Layered Royalties & Revenue Distribution:**
 *    - `setRoyaltyPercentage(uint256 _artworkId, uint256 _royalty)`: Artists set their royalty percentage for secondary sales.
 *    - `withdrawArtistEarnings()`: Artists can withdraw their earnings from artwork sales.
 *    - `withdrawCuratorRewards()`: Curators can withdraw their rewards for curation activities.
 *    - `withdrawGalleryFees()`: Gallery owner/governance can withdraw accumulated platform fees.

 * **7. Reputation & On-Chain Badges (Concept - Could be expanded):**
 *    - `awardCuratorBadge(address _curatorAddress, string _badgeName)`: (Conceptual) Governance can award badges to curators based on performance.
 *    - `getCuratorBadges(address _curatorAddress) view returns (string[])`: (Conceptual) Retrieves badges awarded to a curator.

 * **8. Governance & Proposals (Simple Example - Needs Governance Token Integration):**
 *    - `submitGovernanceProposal(string _proposalDescription)`: Allows governance token holders to submit proposals.
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows governance token holders to vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal (Simple Example - Needs detailed implementation based on governance token).
 *    - `getProposalStatus(uint256 _proposalId) view returns (ProposalStatus)`: Retrieves the status of a governance proposal.

 * **9. Utility & Information Functions:**
 *    - `getGalleryName() view returns (string)`: Returns the name of the art gallery.
 *    - `getGalleryFeePercentage() view returns (uint256)`: Returns the current gallery fee percentage.
 *    - `getCuratorNominationFee() view returns (uint256)`: Returns the current curator nomination fee.
 *    - `getArtworkSubmissionFee() view returns (uint256)`: Returns the current artwork submission fee.
 *    - `isGalleryPaused() view returns (bool)`: Checks if the gallery is currently paused.
 *    - `getContractBalance() view returns (uint256)`: Returns the contract's current Ether balance.
 */

contract DecentralizedAutonomousArtGallery {
    // --- Enums and Structs ---

    enum ArtworkStatus { Submitted, PendingCuration, Approved, Rejected, Listed, Sold }
    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }

    struct Artist {
        string artistName;
        uint256 registrationTimestamp;
    }

    struct Curator {
        uint256 nominationTimestamp;
        bool isActive;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        string[] badges; // Conceptual - for reputation system
    }

    struct Artwork {
        uint256 artworkId;
        address artistAddress;
        string artworkTitle;
        string artworkDescription;
        string artworkIPFSHash;
        uint256 initialPrice;
        uint256 currentPrice;
        ArtworkStatus status;
        uint256 submissionTimestamp;
        uint256 lastPriceUpdateTimestamp;
        uint256 royaltyPercentage;
        address[] curatorsVoted; // Curators who voted on this artwork
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
    }


    // --- State Variables ---

    string public galleryName;
    address public governanceToken; // Address of the governance token contract (if any)
    address public galleryOwner; // Initial contract deployer is the owner
    uint256 public galleryFeePercentage; // Percentage of sale price taken as gallery fee
    uint256 public curatorNominationFee; // Fee to nominate a curator
    uint256 public artworkSubmissionFee; // Fee to submit an artwork

    bool public isPaused; // Gallery pause state

    uint256 public nextArtworkId;
    uint256 public nextProposalId;

    mapping(address => Artist) public artists;
    mapping(address => Curator) public curators;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    address[] public activeCurators;
    uint256[] public submittedArtworkIds;
    uint256[] public approvedArtworkIds;

    // --- Events ---

    event GalleryInitialized(string galleryName, address governanceToken, address owner);
    event GalleryFeeSet(uint256 feePercentage);
    event CuratorNominationFeeSet(uint256 fee);
    event ArtworkSubmissionFeeSet(uint256 fee);
    event GalleryPaused();
    event GalleryUnpaused();

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string newArtistName);

    event CuratorNominated(address nominator, address potentialCurator, string nominationReason);
    event CuratorVoted(address curator, address nominatedCurator, bool support);
    event CuratorStatusRevoked(address revokedCurator);
    event CuratorAdded(address newCurator);

    event ArtworkSubmitted(uint256 artworkId, address artistAddress, string artworkTitle);
    event ArtworkMetadataUpdated(uint256 artworkId, string newArtworkTitle, string newArtworkDescription, string newArtworkIPFSHash);
    event ArtworkCurated(uint256 artworkId, bool approved, address curator);
    event ArtworkPriceSet(uint256 artworkId, uint256 newPrice);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 pricePaid);
    event ArtworkPriceDynamicallyAdjusted(uint256 artworkId, uint256 newPrice, string reason);

    event RoyaltyPercentageSet(uint256 artworkId, uint256 royaltyPercentage);
    event ArtistEarningsWithdrawn(address artistAddress, uint256 amount);
    event CuratorRewardsWithdrawn(address curatorAddress, uint256 amount);
    event GalleryFeesWithdrawn(uint256 amount);

    event CuratorBadgeAwarded(address curatorAddress, string badgeName);

    event GovernanceProposalSubmitted(uint256 proposalId, string description, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event GovernanceProposalRejected(uint256 proposalId);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator(msg.sender), "Only curators can call this function.");
        _;
    }

    modifier onlyArtist() {
        require(isRegisteredArtist(msg.sender), "Only registered artists can call this function.");
        _;
    }

    modifier galleryNotPaused() {
        require(!isPaused, "Gallery is currently paused.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(artworks[_artworkId].artworkId == _artworkId, "Artwork does not exist.");
        _;
    }

    modifier artworkStatus(uint256 _artworkId, ArtworkStatus _status) {
        require(artworks[_artworkId].status == _status, "Artwork is not in the required status.");
        _;
    }


    // --- 1. Gallery Management & Setup ---

    constructor() {
        galleryOwner = msg.sender;
        isPaused = true; // Gallery initially paused for setup
        galleryFeePercentage = 5; // Default 5% gallery fee
        curatorNominationFee = 1 ether; // Example fee
        artworkSubmissionFee = 0.1 ether; // Example fee
        nextArtworkId = 1;
        nextProposalId = 1;
    }

    function initializeGallery(string memory _galleryName, address _governanceToken) external onlyOwner {
        require(bytes(galleryName).length == 0, "Gallery already initialized."); // Prevent re-initialization
        galleryName = _galleryName;
        governanceToken = _governanceToken;
        isPaused = false; // Unpause after initial setup
        emit GalleryInitialized(_galleryName, _governanceToken, galleryOwner);
    }

    function setGalleryFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Gallery fee percentage must be less than or equal to 100.");
        galleryFeePercentage = _feePercentage;
        emit GalleryFeeSet(_feePercentage);
    }

    function setCuratorNominationFee(uint256 _fee) external onlyOwner {
        curatorNominationFee = _fee;
        emit CuratorNominationFeeSet(_fee);
    }

    function setArtworkSubmissionFee(uint256 _fee) external onlyOwner {
        artworkSubmissionFee = _fee;
        emit ArtworkSubmissionFeeSet(_fee);
    }

    function pauseGallery() external onlyOwner {
        isPaused = true;
        emit GalleryPaused();
    }

    function unpauseGallery() external onlyOwner {
        isPaused = false;
        emit GalleryUnpaused();
    }


    // --- 2. Artist Management ---

    function registerArtist(string memory _artistName) external galleryNotPaused {
        require(!isRegisteredArtist(msg.sender), "Already registered as an artist.");
        artists[msg.sender] = Artist({
            artistName: _artistName,
            registrationTimestamp: block.timestamp
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function updateArtistProfile(string memory _newArtistName) external onlyArtist galleryNotPaused {
        artists[msg.sender].artistName = _newArtistName;
        emit ArtistProfileUpdated(msg.sender, _newArtistName);
    }

    function isRegisteredArtist(address _artistAddress) public view returns (bool) {
        return bytes(artists[_artistAddress].artistName).length > 0;
    }


    // --- 3. Curator Management & Nomination ---

    function nominateCurator(address _potentialCurator, string memory _nominationReason) external payable onlyArtist galleryNotPaused {
        require(msg.value >= curatorNominationFee, "Nomination fee required.");
        require(!isCurator(_potentialCurator), "User is already a curator.");
        require(artists[_potentialCurator].registrationTimestamp > 0 || curators[_potentialCurator].nominationTimestamp > 0, "Nominee must be a registered artist or have been nominated before."); // Ensure nominee has some gallery history

        curators[_potentialCurator] = Curator({
            nominationTimestamp: block.timestamp,
            isActive: false,
            approvalVotes: 0,
            rejectionVotes: 0,
            badges: new string[](0) // Initialize empty badge array
        });

        emit CuratorNominated(msg.sender, _potentialCurator, _nominationReason);
    }

    function voteForCurator(address _nominatedCurator, bool _support) external onlyCurator galleryNotPaused {
        require(!isCurator(_nominatedCurator), "Cannot vote for an already active curator.");
        require(curators[_nominatedCurator].nominationTimestamp > 0, "User has not been nominated.");

        if (_support) {
            curators[_nominatedCurator].approvalVotes++;
        } else {
            curators[_nominatedCurator].rejectionVotes++;
        }
        emit CuratorVoted(msg.sender, _nominatedCurator, _support);

        // Simple auto-approval logic (can be refined with more complex voting mechanisms and thresholds)
        if (curators[_nominatedCurator].approvalVotes >= 3 && curators[_nominatedCurator].rejectionVotes < 2) { // Example: 3 approvals and less than 2 rejections
            _addCurator(_nominatedCurator);
        } else if (curators[_nominatedCurator].rejectionVotes >= 3) {
            delete curators[_nominatedCurator]; // Remove nomination if rejected significantly
        }
    }

    function _addCurator(address _newCurator) private {
        curators[_newCurator].isActive = true;
        activeCurators.push(_newCurator);
        emit CuratorAdded(_newCurator);
    }

    function revokeCuratorStatus(address _curatorToRevoke) external onlyOwner galleryNotPaused { // Governance can revoke
        require(isCurator(_curatorToRevoke), "Address is not a curator.");
        curators[_curatorToRevoke].isActive = false;

        // Remove from activeCurators array (inefficient for large arrays, consider optimization if needed)
        for (uint256 i = 0; i < activeCurators.length; i++) {
            if (activeCurators[i] == _curatorToRevoke) {
                activeCurators[i] = activeCurators[activeCurators.length - 1];
                activeCurators.pop();
                break;
            }
        }
        emit CuratorStatusRevoked(_curatorToRevoke);
    }

    function isCurator(address _curatorAddress) public view returns (bool) {
        return curators[_curatorAddress].isActive;
    }

    function getActiveCuratorCount() public view returns (uint256) {
        return activeCurators.length;
    }


    // --- 4. Artwork Submission & Curation ---

    function submitArtwork(
        string memory _artworkTitle,
        string memory _artworkDescription,
        string memory _artworkIPFSHash,
        uint256 _initialPrice
    ) external payable onlyArtist galleryNotPaused {
        require(msg.value >= artworkSubmissionFee, "Artwork submission fee required.");

        uint256 artworkId = nextArtworkId++;
        artworks[artworkId] = Artwork({
            artworkId: artworkId,
            artistAddress: msg.sender,
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            artworkIPFSHash: _artworkIPFSHash,
            initialPrice: _initialPrice,
            currentPrice: _initialPrice,
            status: ArtworkStatus.Submitted, // Initial status is Submitted
            submissionTimestamp: block.timestamp,
            lastPriceUpdateTimestamp: block.timestamp,
            royaltyPercentage: 10, // Default royalty 10%
            curatorsVoted: new address[](0)
        });
        submittedArtworkIds.push(artworkId);
        emit ArtworkSubmitted(artworkId, msg.sender, _artworkTitle);
    }

    function updateArtworkMetadata(
        uint256 _artworkId,
        string memory _newArtworkTitle,
        string memory _newArtworkDescription,
        string memory _newArtworkIPFSHash
    ) external onlyArtist galleryNotPaused artworkExists(_artworkId) artworkStatus(_artworkId, ArtworkStatus.Submitted) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only artist can update metadata.");
        artworks[_artworkId].artworkTitle = _newArtworkTitle;
        artworks[_artworkId].artworkDescription = _newArtworkDescription;
        artworks[_artworkId].artworkIPFSHash = _newArtworkIPFSHash;
        emit ArtworkMetadataUpdated(_artworkId, _newArtworkTitle, _newArtworkDescription, _newArtworkIPFSHash);
    }

    function curateArtwork(uint256 _artworkId, bool _approve) external onlyCurator galleryNotPaused artworkExists(_artworkId) artworkStatus(_artworkId, ArtworkStatus.Submitted) {
        require(!_hasCuratorVoted(_artworkId, msg.sender), "Curator has already voted on this artwork.");

        artworks[_artworkId].curatorsVoted.push(msg.sender); // Record curator vote

        if (_approve) {
            artworks[_artworkId].status = ArtworkStatus.PendingCuration; // Move to pending curation - multi-curator approval can be implemented here if needed.
            // For simplicity, assuming single curator approval for now.
            _finalizeCuration(_artworkId, true); // Automatically approve after one curator approves
        } else {
            _finalizeCuration(_artworkId, false); // Reject immediately if a curator rejects
        }
        emit ArtworkCurated(_artworkId, _approve, msg.sender);
    }

    function _finalizeCuration(uint256 _artworkId, bool _approved) private artworkExists(_artworkId) artworkStatus(_artworkId, ArtworkStatus.Submitted) {
        if (_approved) {
            artworks[_artworkId].status = ArtworkStatus.Approved;
            approvedArtworkIds.push(_artworkId);
        } else {
            artworks[_artworkId].status = ArtworkStatus.Rejected;
        }
    }

    function _hasCuratorVoted(uint256 _artworkId, address _curator) private view returns (bool) {
        for (uint256 i = 0; i < artworks[_artworkId].curatorsVoted.length; i++) {
            if (artworks[_artworkId].curatorsVoted[i] == _curator) {
                return true;
            }
        }
        return false;
    }


    function getArtworkStatus(uint256 _artworkId) public view artworkExists(_artworkId) returns (ArtworkStatus) {
        return artworks[_artworkId].status;
    }

    function getAllSubmittedArtworkIds() external view returns (uint256[] memory) {
        return submittedArtworkIds;
    }

    function getApprovedArtworkIds() external view returns (uint256[] memory) {
        return approvedArtworkIds;
    }


    // --- 5. Artwork Sales & Dynamic Pricing ---

    function purchaseArtwork(uint256 _artworkId) external payable galleryNotPaused artworkExists(_artworkId) artworkStatus(_artworkId, ArtworkStatus.Approved) {
        require(msg.value >= artworks[_artworkId].currentPrice, "Insufficient funds to purchase artwork.");
        require(artworks[_artworkId].status != ArtworkStatus.Sold, "Artwork already sold.");

        uint256 salePrice = artworks[_artworkId].currentPrice;
        uint256 galleryFee = (salePrice * galleryFeePercentage) / 100;
        uint256 artistEarning = salePrice - galleryFee;

        artworks[_artworkId].status = ArtworkStatus.Sold; // Mark as sold

        // Transfer funds
        payable(artworks[_artworkId].artistAddress).transfer(artistEarning);
        payable(galleryOwner).transfer(galleryFee); // Gallery owner receives fee

        emit ArtworkPurchased(_artworkId, msg.sender, salePrice);
    }

    function setArtworkPrice(uint256 _artworkId, uint256 _newPrice) external onlyArtist galleryNotPaused artworkExists(_artworkId) artworkStatus(_artworkId, ArtworkStatus.Approved) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only artist can set artwork price.");
        artworks[_artworkId].currentPrice = _newPrice;
        artworks[_artworkId].lastPriceUpdateTimestamp = block.timestamp;
        emit ArtworkPriceSet(_artworkId, _newPrice);
    }

    function getArtworkPrice(uint256 _artworkId) external view artworkExists(_artworkId) returns (uint256) {
        return artworks[_artworkId].currentPrice;
    }

    function adjustArtworkPriceDynamically(uint256 _artworkId) external galleryNotPaused artworkExists(_artworkId) artworkStatus(_artworkId, ArtworkStatus.Approved) {
        // Example dynamic pricing logic (can be customized and made more complex)
        uint256 timeSinceLastUpdate = block.timestamp - artworks[_artworkId].lastPriceUpdateTimestamp;

        if (timeSinceLastUpdate > 30 days) { // If price hasn't been updated in 30 days, decrease by 5%
            uint256 priceDecrease = (artworks[_artworkId].currentPrice * 5) / 100;
            artworks[_artworkId].currentPrice -= priceDecrease;
            artworks[_artworkId].lastPriceUpdateTimestamp = block.timestamp;
            emit ArtworkPriceDynamicallyAdjusted(_artworkId, artworks[_artworkId].currentPrice, "Time-based decrease");
        }
        // Add more dynamic factors here (e.g., view count, curator recommendations, market trends, etc.)
    }


    // --- 6. Layered Royalties & Revenue Distribution ---

    function setRoyaltyPercentage(uint256 _artworkId, uint256 _royalty) external onlyArtist galleryNotPaused artworkExists(_artworkId) artworkStatus(_artworkId, ArtworkStatus.Approved) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only artist can set royalty.");
        require(_royalty <= 50, "Royalty percentage cannot exceed 50%."); // Example limit
        artworks[_artworkId].royaltyPercentage = _royalty;
        emit RoyaltyPercentageSet(_artworkId, _royalty);
    }

    // Royalty distribution logic would be implemented in a secondary sale/marketplace integration if desired.
    // This contract focuses on the core gallery functions.

    function withdrawArtistEarnings() external onlyArtist galleryNotPaused {
        // In a real system, earnings tracking and withdrawal logic would be more complex,
        // potentially involving a separate accounting system or tokenized earnings.
        // For simplicity, this is a placeholder function.
        uint256 artistBalance = address(this).balance; // Example - In real system, track artist specific balances.
        payable(msg.sender).transfer(artistBalance); // Example - Transfer entire contract balance.
        emit ArtistEarningsWithdrawn(msg.sender, artistBalance);
    }

    function withdrawCuratorRewards() external onlyCurator galleryNotPaused {
        // Similar to artist earnings, curator rewards would need a more detailed tracking and reward mechanism.
        // This is a placeholder.
        uint256 curatorReward = 0; // Example - Calculate curator reward based on activity, etc.
        payable(msg.sender).transfer(curatorReward);
        emit CuratorRewardsWithdrawn(msg.sender, curatorReward);
    }

    function withdrawGalleryFees() external onlyOwner galleryNotPaused {
        uint256 galleryBalance = address(this).balance; // Example - Withdraw all contract balance (excluding artist earnings if tracked separately).
        payable(galleryOwner).transfer(galleryBalance);
        emit GalleryFeesWithdrawn(galleryBalance);
    }


    // --- 7. Reputation & On-Chain Badges (Conceptual) ---

    function awardCuratorBadge(address _curatorAddress, string memory _badgeName) external onlyOwner galleryNotPaused {
        require(isCurator(_curatorAddress), "Address is not a curator.");
        curators[_curatorAddress].badges.push(_badgeName);
        emit CuratorBadgeAwarded(_curatorAddress, _badgeName);
    }

    function getCuratorBadges(address _curatorAddress) external view returns (string[] memory) {
        return curators[_curatorAddress].badges;
    }


    // --- 8. Governance & Proposals (Simple Example) ---

    function submitGovernanceProposal(string memory _proposalDescription) external galleryNotPaused {
        // In a real governance system, checks for governance token holdings and voting power would be implemented.
        // This is a simplified example.
        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _proposalDescription,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // Example: 7-day voting period
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active
        });
        emit GovernanceProposalSubmitted(proposalId, _proposalDescription, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external galleryNotPaused {
        require(governanceProposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        require(block.timestamp <= governanceProposals[_proposalId].endTime, "Voting period ended.");
        // In a real system, check for governance token holdings and voting power of msg.sender.

        if (_support) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);

        // Simple proposal outcome logic (needs proper governance token integration and quorum/thresholds)
        if (governanceProposals[_proposalId].votesFor > governanceProposals[_proposalId].votesAgainst * 2) { // Example: More than 2x Yes votes
            governanceProposals[_proposalId].status = ProposalStatus.Passed;
        } else if (block.timestamp > governanceProposals[_proposalId].endTime) {
            governanceProposals[_proposalId].status = ProposalStatus.Rejected; // Rejected if time expires and not enough support
        }
    }

    function executeProposal(uint256 _proposalId) external onlyOwner galleryNotPaused {
        require(governanceProposals[_proposalId].status == ProposalStatus.Passed, "Proposal not passed.");
        governanceProposals[_proposalId].status = ProposalStatus.Executed;
        emit GovernanceProposalExecuted(_proposalId);
        // Implement actual execution logic based on the proposal details.
        // Example: If proposal is to set a new gallery fee, call setGalleryFee() here.
    }

    function getProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        return governanceProposals[_proposalId].status;
    }


    // --- 9. Utility & Information Functions ---

    function getGalleryName() public view returns (string) {
        return galleryName;
    }

    function getGalleryFeePercentage() public view returns (uint256) {
        return galleryFeePercentage;
    }

    function getCuratorNominationFee() public view returns (uint256) {
        return curatorNominationFee;
    }

    function getArtworkSubmissionFee() public view returns (uint256) {
        return artworkSubmissionFee;
    }

    function isGalleryPaused() public view returns (bool) {
        return isPaused;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive Ether (for fees, purchases, etc.)
    receive() external payable {}
}
```