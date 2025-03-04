```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Not for Production)
 * @dev A smart contract implementing a Decentralized Autonomous Art Collective (DAAC)
 *      with advanced features for art creation, collaborative ownership, curated exhibitions,
 *      dynamic royalties, and community governance.
 *
 * Outline and Function Summary:
 *
 * 1.  **Artist Registration & Profile Management:**
 *     - `registerArtist(string _artistName, string _artistDescription)`: Allows artists to register with the platform.
 *     - `updateArtistProfile(string _artistName, string _artistDescription)`: Allows registered artists to update their profile.
 *     - `getArtistProfile(address _artistAddress)`: Retrieves the profile information of an artist.
 *
 * 2.  **Artwork Submission & Minting (Dynamic NFTs):**
 *     - `submitArtwork(string _artworkTitle, string _artworkDescription, string _initialMetadataURI, uint256 _initialRoyaltyPercentage)`: Artists submit artwork proposals.
 *     - `mintArtworkNFT(uint256 _artworkId)`:  Mints an NFT for an approved artwork (governance approval).
 *     - `setArtworkMetadataURI(uint256 _artworkId, string _newMetadataURI)`: Allows artists to update the metadata URI of their artwork.
 *     - `getArtworkDetails(uint256 _artworkId)`: Retrieves detailed information about an artwork.
 *     - `getArtistArtworks(address _artistAddress)`: Retrieves a list of artworks submitted by an artist.
 *
 * 3.  **Collaborative Ownership & Fractionalization (Proof of Concept - Simplified):**
 *     - `createFractionalOwnership(uint256 _artworkId, uint256 _fractionCount)`:  Allows artwork owners to create fractional ownership (simplified, no actual fractional tokens in this example, tracks percentages).
 *     - `transferFractionalOwnership(uint256 _artworkId, address _recipient, uint256 _fractionPercentage)`: Allows owners to transfer a percentage of fractional ownership.
 *     - `getFractionalOwners(uint256 _artworkId)`: Retrieves a list of fractional owners and their percentages.
 *
 * 4.  **Curated Exhibitions & Voting:**
 *     - `createExhibitionProposal(string _exhibitionTitle, string _exhibitionDescription, uint256[] _artworkIds)`:  Allows community members to propose exhibitions.
 *     - `voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`: Allows registered artists to vote on exhibition proposals.
 *     - `executeExhibitionProposal(uint256 _proposalId)`: Executes an approved exhibition proposal (admin function).
 *     - `getActiveExhibitions()`: Retrieves a list of currently active exhibitions.
 *     - `getExhibitionDetails(uint256 _exhibitionId)`: Retrieves details of a specific exhibition.
 *
 * 5.  **Dynamic Royalties & Revenue Sharing:**
 *     - `setArtworkRoyaltyPercentage(uint256 _artworkId, uint256 _newRoyaltyPercentage)`: Allows artists to adjust their royalty percentage (within limits, governed).
 *     - `purchaseArtwork(uint256 _artworkId)`: Allows users to purchase artwork NFTs, distributing royalties dynamically.
 *     - `withdrawArtistEarnings()`: Allows artists to withdraw their accumulated earnings.
 *     - `distributeExhibitionRewards(uint256 _exhibitionId)`: Distributes rewards to artists participating in an exhibition.
 *
 * 6.  **Community Governance & Proposals (Simplified DAO):**
 *     - `createGovernanceProposal(string _proposalTitle, string _proposalDescription, bytes _proposalData)`: Allows artists to create general governance proposals.
 *     - `voteOnGovernanceProposal(uint256 _proposalId, bool _vote)`: Allows registered artists to vote on governance proposals.
 *     - `executeGovernanceProposal(uint256 _proposalId)`: Executes an approved governance proposal (admin function, based on proposal data).
 *     - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a governance proposal.
 *
 * 7.  **Platform Management & Utility:**
 *     - `setPlatformFeePercentage(uint256 _newFeePercentage)`: Allows the platform admin to set the platform fee percentage.
 *     - `getPlatformFeePercentage()`: Retrieves the current platform fee percentage.
 *     - `pauseContract()`: Pauses core contract functionalities (admin function - emergency).
 *     - `unpauseContract()`: Resumes contract functionalities (admin function).
 */

contract DecentralizedAutonomousArtCollective {
    // --- Structs ---

    struct ArtistProfile {
        string artistName;
        string artistDescription;
        bool isRegistered;
    }

    struct Artwork {
        uint256 artworkId;
        address artistAddress;
        string artworkTitle;
        string artworkDescription;
        string metadataURI;
        uint256 royaltyPercentage; // Percentage (e.g., 1000 for 10%)
        bool isMinted;
        bool isApproved; // Approved by governance for minting
        uint256 submissionTimestamp;
        uint256 lastRoyaltyUpdateTimestamp;
    }

    struct ExhibitionProposal {
        uint256 proposalId;
        string exhibitionTitle;
        string exhibitionDescription;
        uint256[] artworkIds;
        uint256 upVotes;
        uint256 downVotes;
        bool isExecuted;
        uint256 proposalTimestamp;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string proposalTitle;
        string proposalDescription;
        bytes proposalData; // Generic data for proposal execution
        uint256 upVotes;
        uint256 downVotes;
        bool isExecuted;
        uint256 proposalTimestamp;
    }

    struct FractionalOwnership {
        address ownerAddress;
        uint256 percentage; // Percentage of ownership (e.g., 2500 for 25%)
    }

    struct Exhibition {
        uint256 exhibitionId;
        string exhibitionTitle;
        string exhibitionDescription;
        uint256[] artworkIds;
        bool isActive;
        uint256 startTime;
        uint256 endTime; // Optional end time
    }


    // --- State Variables ---

    address public platformAdmin;
    uint256 public platformFeePercentage = 500; // Default 5% platform fee (500 out of 10000)
    bool public paused = false;

    uint256 public nextArtistId = 1;
    mapping(address => ArtistProfile) public artistProfiles;
    address[] public registeredArtists;

    uint256 public nextArtworkId = 1;
    mapping(uint256 => Artwork) public artworks;
    mapping(address => uint256[]) public artistArtworks; // Maps artist address to array of artwork IDs
    uint256[] public allArtworks;

    mapping(uint256 => FractionalOwnership[]) public artworkFractionalOwners;

    uint256 public nextExhibitionProposalId = 1;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    uint256[] public activeExhibitionProposals;

    uint256 public nextGovernanceProposalId = 1;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256[] public activeGovernanceProposals;

    uint256 public nextExhibitionId = 1;
    mapping(uint256 => Exhibition) public exhibitions;
    uint256[] public activeExhibitions;


    // --- Events ---

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string artistName);
    event ArtworkSubmitted(uint256 artworkId, address artistAddress, string artworkTitle);
    event ArtworkMinted(uint256 artworkId, address artistAddress);
    event ArtworkMetadataUpdated(uint256 artworkId, string newMetadataURI);
    event ArtworkRoyaltyUpdated(uint256 artworkId, uint256 newRoyaltyPercentage);
    event FractionalOwnershipCreated(uint256 artworkId, uint256 fractionCount);
    event FractionalOwnershipTransferred(uint256 artworkId, address from, address to, uint256 percentage);
    event ExhibitionProposalCreated(uint256 proposalId, string exhibitionTitle);
    event ExhibitionProposalVote(uint256 proposalId, address voter, bool vote);
    event ExhibitionProposalExecuted(uint256 proposalId);
    event ExhibitionActivated(uint256 exhibitionId, string exhibitionTitle);
    event GovernanceProposalCreated(uint256 proposalId, string proposalTitle);
    event GovernanceProposalVote(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event PlatformFeePercentageUpdated(uint256 newFeePercentage);
    event ContractPaused();
    event ContractUnpaused();
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price, address artist, uint256 royaltyAmount, uint256 platformFee);
    event ArtistEarningsWithdrawn(address artistAddress, uint256 amount);
    event ExhibitionRewardsDistributed(uint256 exhibitionId, uint256 totalRewards);


    // --- Modifiers ---

    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin can perform this action.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].isRegistered, "Only registered artists can perform this action.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId < nextArtworkId && artworks[_artworkId].artworkId == _artworkId, "Artwork does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextExhibitionProposalId && exhibitionProposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier governanceProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextGovernanceProposalId && governanceProposals[_proposalId].proposalId == _proposalId, "Governance proposal does not exist.");
        _;
    }

    modifier exhibitionExists(uint256 _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId < nextExhibitionId && exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Exhibition does not exist.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        platformAdmin = msg.sender;
    }

    // --- 1. Artist Registration & Profile Management ---

    function registerArtist(string memory _artistName, string memory _artistDescription) public notPaused {
        require(!artistProfiles[msg.sender].isRegistered, "Artist is already registered.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistDescription: _artistDescription,
            isRegistered: true
        });
        registeredArtists.push(msg.sender);
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function updateArtistProfile(string memory _artistName, string memory _artistDescription) public onlyRegisteredArtist notPaused {
        artistProfiles[msg.sender].artistName = _artistName;
        artistProfiles[msg.sender].artistDescription = _artistDescription;
        emit ArtistProfileUpdated(msg.sender, _artistName);
    }

    function getArtistProfile(address _artistAddress) public view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }


    // --- 2. Artwork Submission & Minting (Dynamic NFTs) ---

    function submitArtwork(string memory _artworkTitle, string memory _artworkDescription, string memory _initialMetadataURI, uint256 _initialRoyaltyPercentage) public onlyRegisteredArtist notPaused {
        require(_initialRoyaltyPercentage <= 10000, "Royalty percentage cannot exceed 100%."); // Max 100% royalty
        artworks[nextArtworkId] = Artwork({
            artworkId: nextArtworkId,
            artistAddress: msg.sender,
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            metadataURI: _initialMetadataURI,
            royaltyPercentage: _initialRoyaltyPercentage,
            isMinted: false,
            isApproved: false, // Initially not approved, needs governance
            submissionTimestamp: block.timestamp,
            lastRoyaltyUpdateTimestamp: block.timestamp
        });
        artistArtworks[msg.sender].push(nextArtworkId);
        allArtworks.push(nextArtworkId);
        emit ArtworkSubmitted(nextArtworkId, msg.sender, _artworkTitle);
        nextArtworkId++;
    }

    function mintArtworkNFT(uint256 _artworkId) public onlyPlatformAdmin artworkExists(_artworkId) notPaused { // Admin approves minting after governance
        require(!artworks[_artworkId].isMinted, "Artwork NFT already minted.");
        require(artworks[_artworkId].isApproved, "Artwork is not yet approved for minting by governance."); // Governance approval check

        artworks[_artworkId].isMinted = true;
        emit ArtworkMinted(_artworkId, artworks[_artworkId].artistAddress);
        // In a real NFT implementation, you would mint an actual NFT token here (ERC721/ERC1155)
        // and link it to the artworkId. This example focuses on the DAAC logic.
    }

    function setArtworkMetadataURI(uint256 _artworkId, string memory _newMetadataURI) public onlyRegisteredArtist artworkExists(_artworkId) notPaused {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist can update metadata.");
        artworks[_artworkId].metadataURI = _newMetadataURI;
        emit ArtworkMetadataUpdated(_artworkId, _newMetadataURI);
    }

    function getArtworkDetails(uint256 _artworkId) public view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getArtistArtworks(address _artistAddress) public view returns (uint256[] memory) {
        return artistArtworks[_artistAddress];
    }


    // --- 3. Collaborative Ownership & Fractionalization (Proof of Concept - Simplified) ---

    function createFractionalOwnership(uint256 _artworkId, uint256 _fractionCount) public onlyRegisteredArtist artworkExists(_artworkId) notPaused {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the original artist can initiate fractionalization.");
        require(artworkFractionalOwners[_artworkId].length == 0, "Fractional ownership already initialized.");
        require(_fractionCount > 1 && _fractionCount <= 100, "Fraction count must be between 2 and 100."); // Example limit

        uint256 percentagePerFraction = 10000 / _fractionCount; // Equal fractions for simplicity
        for (uint256 i = 0; i < _fractionCount; i++) {
            artworkFractionalOwners[_artworkId].push(FractionalOwnership({
                ownerAddress: msg.sender, // Initially, artist owns all fractions
                percentage: percentagePerFraction
            }));
        }
        emit FractionalOwnershipCreated(_artworkId, _fractionCount);
    }

    function transferFractionalOwnership(uint256 _artworkId, address _recipient, uint256 _fractionPercentage) public artworkExists(_artworkId) notPaused {
        bool foundOwner = false;
        for (uint256 i = 0; i < artworkFractionalOwners[_artworkId].length; i++) {
            if (artworkFractionalOwners[_artworkId][i].ownerAddress == msg.sender && artworkFractionalOwners[_artworkId][i].percentage >= _fractionPercentage) {
                artworkFractionalOwners[_artworkId][i].percentage -= _fractionPercentage;
                artworkFractionalOwners[_artworkId].push(FractionalOwnership({
                    ownerAddress: _recipient,
                    percentage: _fractionPercentage
                }));
                foundOwner = true;
                emit FractionalOwnershipTransferred(_artworkId, msg.sender, _recipient, _fractionPercentage);
                break; // Assuming one owner can transfer at a time
            }
        }
        require(foundOwner, "Sender is not a fractional owner or does not have enough percentage to transfer.");
    }

    function getFractionalOwners(uint256 _artworkId) public view artworkExists(_artworkId) returns (FractionalOwnership[] memory) {
        return artworkFractionalOwners[_artworkId];
    }


    // --- 4. Curated Exhibitions & Voting ---

    function createExhibitionProposal(string memory _exhibitionTitle, string memory _exhibitionDescription, uint256[] memory _artworkIds) public onlyRegisteredArtist notPaused {
        require(_artworkIds.length > 0, "Exhibition must include at least one artwork.");
        // Basic check: ensure artworks exist (more robust checks in real scenario)
        for (uint256 i = 0; i < _artworkIds.length; i++) {
            require(artworks[_artworkIds[i]].artworkId == _artworkIds[i], "Invalid artwork ID in proposal.");
        }

        exhibitionProposals[nextExhibitionProposalId] = ExhibitionProposal({
            proposalId: nextExhibitionProposalId,
            exhibitionTitle: _exhibitionTitle,
            exhibitionDescription: _exhibitionDescription,
            artworkIds: _artworkIds,
            upVotes: 0,
            downVotes: 0,
            isExecuted: false,
            proposalTimestamp: block.timestamp
        });
        activeExhibitionProposals.push(nextExhibitionProposalId);
        emit ExhibitionProposalCreated(nextExhibitionProposalId, _exhibitionTitle);
        nextExhibitionProposalId++;
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) public onlyRegisteredArtist proposalExists(_proposalId) notPaused {
        require(!exhibitionProposals[_proposalId].isExecuted, "Proposal already executed.");
        if (_vote) {
            exhibitionProposals[_proposalId].upVotes++;
        } else {
            exhibitionProposals[_proposalId].downVotes++;
        }
        emit ExhibitionProposalVote(_proposalId, msg.sender, _vote);
    }

    function executeExhibitionProposal(uint256 _proposalId) public onlyPlatformAdmin proposalExists(_proposalId) notPaused {
        require(!exhibitionProposals[_proposalId].isExecuted, "Proposal already executed.");
        require(exhibitionProposals[_proposalId].upVotes > exhibitionProposals[_proposalId].downVotes, "Proposal not approved by governance."); // Simple majority vote

        exhibitionProposals[_proposalId].isExecuted = true;
        activeExhibitionProposals = removeProposalId(activeExhibitionProposals, _proposalId); // Remove from active proposals

        exhibitions[nextExhibitionId] = Exhibition({
            exhibitionId: nextExhibitionId,
            exhibitionTitle: exhibitionProposals[_proposalId].exhibitionTitle,
            exhibitionDescription: exhibitionProposals[_proposalId].exhibitionDescription,
            artworkIds: exhibitionProposals[_proposalId].artworkIds,
            isActive: true,
            startTime: block.timestamp,
            endTime: 0 // Example: No fixed end time in this simplified version
        });
        activeExhibitions.push(nextExhibitionId);
        emit ExhibitionProposalExecuted(_proposalId);
        emit ExhibitionActivated(nextExhibitionId, exhibitionProposals[_proposalId].exhibitionTitle);
        nextExhibitionId++;
    }

    function getActiveExhibitions() public view returns (uint256[] memory) {
        return activeExhibitions;
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view exhibitionExists(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }


    // --- 5. Dynamic Royalties & Revenue Sharing ---

    function setArtworkRoyaltyPercentage(uint256 _artworkId, uint256 _newRoyaltyPercentage) public onlyRegisteredArtist artworkExists(_artworkId) notPaused {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist can update royalty.");
        require(_newRoyaltyPercentage <= 10000, "Royalty percentage cannot exceed 100%.");
        require(block.timestamp > artworks[_artworkId].lastRoyaltyUpdateTimestamp + 30 days, "Royalty can only be updated every 30 days."); // Example cooldown
        artworks[_artworkId].royaltyPercentage = _newRoyaltyPercentage;
        artworks[_artworkId].lastRoyaltyUpdateTimestamp = block.timestamp;
        emit ArtworkRoyaltyUpdated(_artworkId, _newRoyaltyPercentage);
    }

    function purchaseArtwork(uint256 _artworkId) public payable artworkExists(_artworkId) notPaused {
        require(artworks[_artworkId].isMinted, "Artwork NFT is not yet minted.");
        uint256 artworkPrice = msg.value; // Assume msg.value is the artwork price
        require(artworkPrice > 0, "Purchase price must be greater than zero.");

        uint256 royaltyAmount = (artworkPrice * artworks[_artworkId].royaltyPercentage) / 10000;
        uint256 platformFee = (artworkPrice * platformFeePercentage) / 10000;
        uint256 artistPayout = royaltyAmount; // In this simplified example, artist gets full royalty
        uint256 platformRevenue = platformFee;

        payable(artworks[_artworkId].artistAddress).transfer(artistPayout);
        payable(platformAdmin).transfer(platformRevenue);

        emit ArtworkPurchased(_artworkId, msg.sender, artworkPrice, artworks[_artworkId].artistAddress, royaltyAmount, platformFee);
    }

    // Simplified withdrawal - In a real system, earnings tracking and more complex withdrawal logic would be needed.
    function withdrawArtistEarnings() public onlyRegisteredArtist notPaused {
        // In a more advanced system, track artist earnings separately.
        // For this example, artists withdraw all contract balance (simplified, not secure for large amounts).
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit ArtistEarningsWithdrawn(msg.sender, balance);
    }

    function distributeExhibitionRewards(uint256 _exhibitionId) public onlyPlatformAdmin exhibitionExists(_exhibitionId) notPaused {
        // Example: Simple reward distribution - could be based on exhibition success metrics, etc.
        uint256 totalRewardPool = 1 ether; // Example reward pool
        uint256 artworkCount = exhibitions[_exhibitionId].artworkIds.length;
        uint256 rewardPerArtwork = totalRewardPool / artworkCount;

        for (uint256 i = 0; i < artworkCount; i++) {
            uint256 artworkId = exhibitions[_exhibitionId].artworkIds[i];
            payable(artworks[artworkId].artistAddress).transfer(rewardPerArtwork);
        }
        emit ExhibitionRewardsDistributed(_exhibitionId, totalRewardPool);
    }


    // --- 6. Community Governance & Proposals (Simplified DAO) ---

    function createGovernanceProposal(string memory _proposalTitle, string memory _proposalDescription, bytes memory _proposalData) public onlyRegisteredArtist notPaused {
        governanceProposals[nextGovernanceProposalId] = GovernanceProposal({
            proposalId: nextGovernanceProposalId,
            proposalTitle: _proposalTitle,
            proposalDescription: _proposalDescription,
            proposalData: _proposalData,
            upVotes: 0,
            downVotes: 0,
            isExecuted: false,
            proposalTimestamp: block.timestamp
        });
        activeGovernanceProposals.push(nextGovernanceProposalId);
        emit GovernanceProposalCreated(nextGovernanceProposalId, _proposalTitle);
        nextGovernanceProposalId++;
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote) public onlyRegisteredArtist governanceProposalExists(_proposalId) notPaused {
        require(!governanceProposals[_proposalId].isExecuted, "Governance proposal already executed.");
        if (_vote) {
            governanceProposals[_proposalId].upVotes++;
        } else {
            governanceProposals[_proposalId].downVotes++;
        }
        emit GovernanceProposalVote(_proposalId, msg.sender, _vote);
    }

    function executeGovernanceProposal(uint256 _proposalId) public onlyPlatformAdmin governanceProposalExists(_proposalId) notPaused {
        require(!governanceProposals[_proposalId].isExecuted, "Governance proposal already executed.");
        require(governanceProposals[_proposalId].upVotes > governanceProposals[_proposalId].downVotes, "Governance proposal not approved by community.");

        governanceProposals[_proposalId].isExecuted = true;
        activeGovernanceProposals = removeGovernanceProposalId(activeGovernanceProposals, _proposalId); // Remove from active proposals

        // Example: Generic proposal data execution - needs to be tailored to specific proposal types
        bytes memory proposalData = governanceProposals[_proposalId].proposalData;
        (address targetContract, bytes memory functionCallData) = abi.decode(proposalData, (address, bytes));

        // Low-level call to target contract (use with caution - security risks)
        (bool success, bytes memory returnData) = targetContract.call(functionCallData);
        require(success, "Governance proposal execution failed.");

        emit GovernanceProposalExecuted(_proposalId);
    }

    function getProposalDetails(uint256 _proposalId) public view governanceProposalExists(_proposalId) returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }


    // --- 7. Platform Management & Utility ---

    function setPlatformFeePercentage(uint256 _newFeePercentage) public onlyPlatformAdmin notPaused {
        require(_newFeePercentage <= 5000, "Platform fee percentage cannot exceed 50%."); // Example limit
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeePercentageUpdated(_newFeePercentage);
    }

    function getPlatformFeePercentage() public view returns (uint256) {
        return platformFeePercentage;
    }

    function pauseContract() public onlyPlatformAdmin {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyPlatformAdmin {
        paused = false;
        emit ContractUnpaused();
    }


    // --- Internal Utility Functions ---

    function removeProposalId(uint256[] memory _proposalIds, uint256 _proposalIdToRemove) internal pure returns (uint256[] memory) {
        uint256[] memory newProposalIds = new uint256[](_proposalIds.length - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < _proposalIds.length; i++) {
            if (_proposalIds[i] != _proposalIdToRemove) {
                newProposalIds[index] = _proposalIds[i];
                index++;
            }
        }
        return newProposalIds;
    }

    function removeGovernanceProposalId(uint256[] memory _proposalIds, uint256 _proposalIdToRemove) internal pure returns (uint256[] memory) {
        uint256[] memory newProposalIds = new uint256[](_proposalIds.length - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < _proposalIds.length; i++) {
            if (_proposalIds[i] != _proposalIdToRemove) {
                newProposalIds[index] = _proposalIds[i];
                index++;
            }
        }
        return newProposalIds;
    }

    // Fallback function to receive ETH (for purchases)
    receive() external payable {}
}
```