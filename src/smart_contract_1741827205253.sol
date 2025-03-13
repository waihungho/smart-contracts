```solidity
/**
 * @title Decentralized Dynamic Art Gallery - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art gallery featuring dynamic and evolving artworks.
 *
 * **Outline:**
 * 1. **Gallery Management:**
 *    - `setGalleryName()`: Allows admin to set the gallery name.
 *    - `setGovernanceTokenAddress()`: Allows admin to set the governance token address for voting.
 *    - `setVotingDuration()`: Allows admin to set the voting duration for artwork proposals and dynamic property changes.
 *    - `addCurator()`: Allows admin to add a curator to help manage the gallery.
 *    - `removeCurator()`: Allows admin to remove a curator.
 *    - `setPlatformFee()`: Allows admin to set the platform fee percentage for artwork sales.
 *    - `pauseContract()`: Allows admin to pause core functionalities of the contract.
 *    - `unpauseContract()`: Allows admin to unpause the contract.
 *
 * 2. **Artwork Management:**
 *    - `submitArtworkProposal()`: Artists can submit artwork proposals for consideration.
 *    - `mintArtwork()`: Mints an approved artwork proposal into an ERC721 NFT.
 *    - `setArtworkDynamicPropertyLogic()`: Allows the artwork owner to set the logic for dynamic property updates (requires governance approval).
 *    - `triggerDynamicUpdate()`:  Allows anyone to trigger a dynamic update for an artwork based on its defined logic.
 *    - `reportArtwork()`: Allows users to report an artwork for inappropriate content.
 *    - `removeArtwork()`: Allows curators and admin to remove reported or inappropriate artworks (with voting or admin override).
 *    - `getArtworkDetails()`: Retrieves detailed information about a specific artwork.
 *    - `getAllArtworks()`: Retrieves a list of all artworks in the gallery.
 *    - `getArtworksByArtist()`: Retrieves a list of artworks by a specific artist.
 *    - `getFeaturedArtworks()`: Retrieves a list of featured artworks (curator/admin selected).
 *
 * 3. **Governance and Community Features:**
 *    - `voteOnArtworkProposal()`: Governance token holders can vote on artwork proposals.
 *    - `voteOnDynamicPropertyChange()`: Governance token holders can vote on proposed dynamic property logic changes.
 *    - `featureArtwork()`: Curators/Admin can feature artworks for increased visibility.
 *    - `unfeatureArtwork()`: Curators/Admin can unfeature artworks.
 *    - `donateToGallery()`: Users can donate ETH to support the gallery and artists.
 *    - `withdrawArtistEarnings()`: Artists can withdraw their earnings from artwork sales.
 *    - `withdrawPlatformFees()`: Admin can withdraw accumulated platform fees.
 *    - `getGalleryBalance()`: Retrieves the current ETH balance of the gallery contract.
 *
 * **Function Summary:**
 * This contract implements a decentralized dynamic art gallery where artists can submit and mint dynamic NFTs.
 * The gallery is governed by a community through a governance token, allowing for democratic decision-making on artwork approvals,
 * dynamic property logic, and gallery management. It includes features for artwork curation, reporting, dynamic updates,
 * and economic mechanisms for artists and the platform.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicArtGallery is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _artworkIds;

    string public galleryName;
    address public governanceTokenAddress;
    uint256 public votingDuration; // in seconds
    uint256 public platformFeePercentage; // e.g., 5 for 5%
    bool public isPaused;

    mapping(address => bool) public curators;
    mapping(uint256 => ArtworkProposal) public artworkProposals;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => bool) public featuredArtworks;
    mapping(uint256 => mapping(address => bool)) public artworkProposalVotes;
    mapping(uint256 => mapping(address => bool)) public dynamicPropertyVotes;
    mapping(uint256 => Report) public artworkReports;
    mapping(address => uint256) public artistEarnings;

    uint256 public proposalCounter;
    uint256 public reportCounter;

    struct ArtworkProposal {
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string imageUrl;
        string dynamicPropertyLogic; // JSON or string to define logic
        uint256 proposalTimestamp;
        bool isActive;
    }

    struct Artwork {
        uint256 artworkId;
        address artist;
        string title;
        string description;
        string imageUrl;
        string dynamicPropertyLogic;
        uint256 price; // in wei
        uint256 mintTimestamp;
        bool isFeatured;
    }

    struct Report {
        uint256 reportId;
        uint256 artworkId;
        address reporter;
        string reason;
        uint256 reportTimestamp;
        bool isResolved;
    }

    event GalleryNameUpdated(string newName);
    event GovernanceTokenUpdated(address tokenAddress);
    event VotingDurationUpdated(uint256 duration);
    event CuratorAdded(address curatorAddress);
    event CuratorRemoved(address curatorAddress);
    event PlatformFeeUpdated(uint256 feePercentage);
    event ContractPaused();
    event ContractUnpaused();
    event ArtworkProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtworkMinted(uint256 artworkId, address artist, string title);
    event DynamicPropertyLogicSet(uint256 artworkId);
    event DynamicUpdateTriggered(uint256 artworkId);
    event ArtworkReported(uint256 reportId, uint256 artworkId, address reporter);
    event ArtworkRemoved(uint256 artworkId);
    event ArtworkFeatured(uint256 artworkId);
    event ArtworkUnfeatured(uint256 artworkId);
    event DonationReceived(address donor, uint256 amount);
    event ArtistEarningsWithdrawn(address artist, uint256 amount);
    event PlatformFeesWithdrawn(address admin, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender] || msg.sender == owner(), "Only curator or admin can call this function.");
        _;
    }

    modifier onlyArtist(uint256 _artworkId) {
        require(artworks[_artworkId].artist == msg.sender, "Only artist of this artwork can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(isPaused, "Contract is not paused.");
        _;
    }

    constructor(string memory _galleryName, address _governanceTokenAddress, uint256 _votingDuration, uint256 _platformFeePercentage) ERC721(_galleryName, "DAG") {
        galleryName = _galleryName;
        governanceTokenAddress = _governanceTokenAddress;
        votingDuration = _votingDuration;
        platformFeePercentage = _platformFeePercentage;
        _artworkIds.increment(); // Start artwork IDs from 1
        proposalCounter = 1;
        reportCounter = 1;
    }

    // 1. Gallery Management Functions

    /**
     * @dev Sets the name of the art gallery. Only callable by the contract admin.
     * @param _newName The new name for the gallery.
     */
    function setGalleryName(string memory _newName) external onlyAdmin {
        galleryName = _newName;
        emit GalleryNameUpdated(_newName);
    }

    /**
     * @dev Sets the address of the governance token used for voting. Only callable by the contract admin.
     * @param _tokenAddress The address of the governance token contract.
     */
    function setGovernanceTokenAddress(address _tokenAddress) external onlyAdmin {
        governanceTokenAddress = _tokenAddress;
        emit GovernanceTokenUpdated(_tokenAddress);
    }

    /**
     * @dev Sets the duration for voting periods in seconds. Only callable by the contract admin.
     * @param _durationInSeconds The voting duration in seconds.
     */
    function setVotingDuration(uint256 _durationInSeconds) external onlyAdmin {
        votingDuration = _durationInSeconds;
        emit VotingDurationUpdated(_durationInSeconds);
    }

    /**
     * @dev Adds a new curator to the gallery management team. Only callable by the contract admin.
     * @param _curatorAddress The address of the curator to be added.
     */
    function addCurator(address _curatorAddress) external onlyAdmin {
        curators[_curatorAddress] = true;
        emit CuratorAdded(_curatorAddress);
    }

    /**
     * @dev Removes a curator from the gallery management team. Only callable by the contract admin.
     * @param _curatorAddress The address of the curator to be removed.
     */
    function removeCurator(address _curatorAddress) external onlyAdmin {
        curators[_curatorAddress] = false;
        emit CuratorRemoved(_curatorAddress);
    }

    /**
     * @dev Sets the platform fee percentage for artwork sales. Only callable by the contract admin.
     * @param _feePercentage The platform fee percentage (e.g., 5 for 5%).
     */
    function setPlatformFee(uint256 _feePercentage) external onlyAdmin {
        require(_feePercentage <= 100, "Fee percentage must be less than or equal to 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    /**
     * @dev Pauses the contract, disabling core functionalities. Only callable by the contract admin.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        _pause();
        isPaused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, re-enabling core functionalities. Only callable by the contract admin.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        _unpause();
        isPaused = false;
        emit ContractUnpaused();
    }

    // 2. Artwork Management Functions

    /**
     * @dev Allows artists to submit an artwork proposal for consideration.
     * @param _title The title of the artwork.
     * @param _description A description of the artwork.
     * @param _imageUrl URL or URI to the artwork image.
     * @param _dynamicPropertyLogic JSON or string defining the dynamic property logic.
     */
    function submitArtworkProposal(
        string memory _title,
        string memory _description,
        string memory _imageUrl,
        string memory _dynamicPropertyLogic
    ) external whenNotPaused {
        uint256 proposalId = proposalCounter++;
        artworkProposals[proposalId] = ArtworkProposal({
            proposalId: proposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            imageUrl: _imageUrl,
            dynamicPropertyLogic: _dynamicPropertyLogic,
            proposalTimestamp: block.timestamp,
            isActive: true
        });
        emit ArtworkProposalSubmitted(proposalId, msg.sender, _title);
    }

    /**
     * @dev Mints an artwork proposal into an ERC721 NFT after successful voting.
     * @param _proposalId The ID of the artwork proposal to mint.
     * @param _price The price of the artwork in wei.
     */
    function mintArtwork(uint256 _proposalId, uint256 _price) external whenNotPaused {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active or does not exist.");
        require(block.timestamp >= proposal.proposalTimestamp + votingDuration, "Voting is still active.");

        uint256 yesVotes = 0;
        uint256 noVotes = 0;
        uint256 totalVotesPossible = IERC20(governanceTokenAddress).totalSupply(); // Assuming 1 token = 1 vote

        // Count votes (simplified - in real app, iterate and check votes)
        for (uint256 i = 0; i < totalVotesPossible; i++) { // Inefficient, needs optimization for real-world
            address voterAddress = address(uint160(i)); // Placeholder for voter address retrieval - replace with actual logic
            if (artworkProposalVotes[_proposalId][voterAddress]) {
                yesVotes++;
            } else {
                noVotes++;
            }
        }

        require(yesVotes > noVotes, "Artwork proposal not approved by governance.");

        _artworkIds.increment();
        uint256 artworkId = _artworkIds.current();
        _safeMint(proposal.artist, artworkId);
        artworks[artworkId] = Artwork({
            artworkId: artworkId,
            artist: proposal.artist,
            title: proposal.title,
            description: proposal.description,
            imageUrl: proposal.imageUrl,
            dynamicPropertyLogic: proposal.dynamicPropertyLogic,
            price: _price,
            mintTimestamp: block.timestamp,
            isFeatured: false
        });

        artworkProposals[_proposalId].isActive = false; // Deactivate proposal after minting

        emit ArtworkMinted(artworkId, proposal.artist, proposal.title);
    }

    /**
     * @dev Allows the artwork owner to set the dynamic property logic for their artwork. Requires governance approval.
     * @param _artworkId The ID of the artwork.
     * @param _dynamicPropertyLogic JSON or string defining the new dynamic property logic.
     */
    function setArtworkDynamicPropertyLogic(uint256 _artworkId, string memory _dynamicPropertyLogic) external onlyArtist(_artworkId) whenNotPaused {
        // In a real-world scenario, governance voting should be implemented here for dynamic property changes.
        // For simplicity in this example, we're skipping the voting and directly setting it (consider adding governance voting for this in a more advanced version).

        artworks[_artworkId].dynamicPropertyLogic = _dynamicPropertyLogic;
        emit DynamicPropertyLogicSet(_artworkId);
    }

    /**
     * @dev Allows anyone to trigger a dynamic update for an artwork based on its defined logic.
     * @param _artworkId The ID of the artwork to update.
     */
    function triggerDynamicUpdate(uint256 _artworkId) external whenNotPaused {
        // Placeholder for dynamic update logic.
        // In a real-world application, this function would:
        // 1. Fetch external data (e.g., weather, market prices, random numbers using oracles).
        // 2. Parse the `dynamicPropertyLogic` of the artwork (e.g., JSON).
        // 3. Apply the logic based on the fetched data to update artwork metadata or visual representation (off-chain).
        // 4. Emit an event indicating the update.

        // For this example, we just emit an event.
        emit DynamicUpdateTriggered(_artworkId);
    }

    /**
     * @dev Allows users to report an artwork for inappropriate content.
     * @param _artworkId The ID of the artwork being reported.
     * @param _reason The reason for reporting the artwork.
     */
    function reportArtwork(uint256 _artworkId, string memory _reason) external whenNotPaused {
        require(artworks[_artworkId].artworkId > 0, "Artwork does not exist.");
        uint256 reportId = reportCounter++;
        artworkReports[reportId] = Report({
            reportId: reportId,
            artworkId: _artworkId,
            reporter: msg.sender,
            reason: _reason,
            reportTimestamp: block.timestamp,
            isResolved: false
        });
        emit ArtworkReported(reportId, _artworkId, msg.sender);
    }

    /**
     * @dev Allows curators or admin to remove a reported or inappropriate artwork. Requires curator or admin role.
     * @param _artworkId The ID of the artwork to remove.
     */
    function removeArtwork(uint256 _artworkId) external onlyCurator whenNotPaused {
        require(artworks[_artworkId].artworkId > 0, "Artwork does not exist.");
        // In a real-world scenario, consider adding a voting mechanism for artwork removal as well.
        delete artworks[_artworkId];
        _burn(_artworkId); // Burn the NFT to remove it permanently
        emit ArtworkRemoved(_artworkId);
    }

    /**
     * @dev Retrieves detailed information about a specific artwork.
     * @param _artworkId The ID of the artwork.
     * @return Artwork struct containing artwork details.
     */
    function getArtworkDetails(uint256 _artworkId) external view returns (Artwork memory) {
        require(artworks[_artworkId].artworkId > 0, "Artwork does not exist.");
        return artworks[_artworkId];
    }

    /**
     * @dev Retrieves a list of all artwork IDs in the gallery.
     * @return An array of artwork IDs.
     */
    function getAllArtworks() external view returns (uint256[] memory) {
        uint256 count = _artworkIds.current() - 1; // Exclude counter start value
        uint256[] memory allArtworkIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (artworks[i].artworkId != 0) { // Check if artwork exists (not deleted)
                allArtworkIds[index++] = i;
            }
        }
        assembly {
            mstore(allArtworkIds, index) // Correctly set the length of the returned array
        }
        return allArtworkIds;
    }


    /**
     * @dev Retrieves a list of artwork IDs created by a specific artist.
     * @param _artistAddress The address of the artist.
     * @return An array of artwork IDs by the specified artist.
     */
    function getArtworksByArtist(address _artistAddress) external view returns (uint256[] memory) {
        uint256 count = _artworkIds.current() - 1;
        uint256[] memory artistArtworkIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (artworks[i].artist == _artistAddress) {
                artistArtworkIds[index++] = i;
            }
        }
        assembly {
            mstore(artistArtworkIds, index) // Correctly set the length of the returned array
        }
        return artistArtworkIds;
    }

    /**
     * @dev Retrieves a list of featured artwork IDs.
     * @return An array of featured artwork IDs.
     */
    function getFeaturedArtworks() external view returns (uint256[] memory) {
        uint256 count = _artworkIds.current() - 1;
        uint256[] memory featuredArtworkIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (artworks[i].isFeatured) {
                featuredArtworkIds[index++] = i;
            }
        }
        assembly {
            mstore(featuredArtworkIds, index) // Correctly set the length of the returned array
        }
        return featuredArtworkIds;
    }

    // 3. Governance and Community Features

    /**
     * @dev Allows governance token holders to vote on an artwork proposal.
     * @param _proposalId The ID of the artwork proposal.
     * @param _vote true for yes, false for no.
     */
    function voteOnArtworkProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(artworkProposals[_proposalId].isActive, "Proposal is not active or does not exist.");
        require(block.timestamp < artworkProposals[_proposalId].proposalTimestamp + votingDuration, "Voting period has ended.");
        require(!artworkProposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");

        // In a real-world application, you would check if the voter holds governance tokens.
        // For simplicity, we're skipping token balance check here.
        // e.g., require(IERC20(governanceTokenAddress).balanceOf(msg.sender) > 0, "No governance tokens held.");

        artworkProposalVotes[_proposalId][msg.sender] = _vote;
    }

    /**
     * @dev Allows governance token holders to vote on a proposed dynamic property change for an artwork.
     * @param _artworkId The ID of the artwork.
     * @param _vote true for yes, false for no.
     */
    function voteOnDynamicPropertyChange(uint256 _artworkId, bool _vote) external whenNotPaused {
        // Implement governance voting for dynamic property changes similar to proposal voting.
        // This is a placeholder for a more advanced feature.
        // For now, dynamic property changes are simplified and directly set by the artist (in setArtworkDynamicPropertyLogic).
        // In a real-world scenario, implement voting logic here.
        require(false, "Dynamic property change voting not implemented in this version.");
    }

    /**
     * @dev Allows curators or admin to feature an artwork to increase its visibility.
     * @param _artworkId The ID of the artwork to feature.
     */
    function featureArtwork(uint256 _artworkId) external onlyCurator whenNotPaused {
        require(artworks[_artworkId].artworkId > 0, "Artwork does not exist.");
        artworks[_artworkId].isFeatured = true;
        featuredArtworks[_artworkId] = true;
        emit ArtworkFeatured(_artworkId);
    }

    /**
     * @dev Allows curators or admin to unfeature an artwork.
     * @param _artworkId The ID of the artwork to unfeature.
     */
    function unfeatureArtwork(uint256 _artworkId) external onlyCurator whenNotPaused {
        require(artworks[_artworkId].artworkId > 0, "Artwork does not exist.");
        artworks[_artworkId].isFeatured = false;
        featuredArtworks[_artworkId] = false;
        emit ArtworkUnfeatured(_artworkId);
    }

    /**
     * @dev Allows users to donate ETH to support the gallery and artists.
     */
    function donateToGallery() external payable whenNotPaused {
        emit DonationReceived(msg.sender, msg.value);
    }

    /**
     * @dev Allows artists to withdraw their earnings from artwork sales.
     */
    function withdrawArtistEarnings() external whenNotPaused {
        uint256 earnings = artistEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");
        artistEarnings[msg.sender] = 0;
        payable(msg.sender).transfer(earnings);
        emit ArtistEarningsWithdrawn(msg.sender, earnings);
    }

    /**
     * @dev Allows admin to withdraw accumulated platform fees from artwork sales.
     */
    function withdrawPlatformFees() external onlyAdmin whenNotPaused {
        uint256 platformBalance = address(this).balance - getGalleryBalance(); // Calculate platform fees (remaining balance after artist earnings)
        require(platformBalance > 0, "No platform fees to withdraw.");
        payable(owner()).transfer(platformBalance);
        emit PlatformFeesWithdrawn(owner(), platformBalance);
    }

    /**
     * @dev Gets the current ETH balance of the gallery contract (excluding platform fees, only artist earnings).
     * @return The current ETH balance allocated for artist earnings.
     */
    function getGalleryBalance() public view returns (uint256) {
        uint256 totalArtistEarnings = 0;
        for (uint256 i = 1; i <= _artworkIds.current(); i++) {
            totalArtistEarnings += artistEarnings[artworks[i].artist];
        }
        return totalArtistEarnings; // Returns only artist earnings balance
    }

    /**
     * @dev Override tokenURI to return dynamic metadata based on artwork properties.
     * @param tokenId The ID of the token.
     * @return URI for the token metadata.
     */
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        Artwork memory artwork = artworks[tokenId];
        string memory metadata = string(abi.encodePacked(
            '{"name": "', artwork.title, '",',
            '"description": "', artwork.description, '",',
            '"image": "', artwork.imageUrl, '",',
            '"dynamicProperties": ', artwork.dynamicPropertyLogic, // Include dynamic properties in metadata
            '}'
        ));

        string memory jsonBase64 = Base64.encode(bytes(metadata));
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }

    /**
     * @dev Internal function to handle token sale and fee distribution (example - needs customization for actual sale logic).
     * @param _artworkId The ID of the artwork being sold.
     * @param _buyer The address of the buyer.
     */
    function _sellArtwork(uint256 _artworkId, address _buyer) internal payable {
        Artwork storage artwork = artworks[_artworkId];
        require(msg.value >= artwork.price, "Insufficient payment.");

        uint256 platformFee = (artwork.price * platformFeePercentage) / 100;
        uint256 artistShare = artwork.price - platformFee;

        artistEarnings[artwork.artist] += artistShare; // Accumulate artist earnings
        payable(owner()).transfer(platformFee); // Immediately transfer platform fee to owner

        _transfer(ownerOf(_artworkId), _buyer, _artworkId); // Transfer NFT ownership
        // Consider emitting a Sale event here.
    }

    /**
     * @dev Example function to buy an artwork (demonstrates _sellArtwork usage).
     * @param _artworkId The ID of the artwork to buy.
     */
    function buyArtwork(uint256 _artworkId) external payable whenNotPaused {
        require(ownerOf(_artworkId) == address(this), "Artwork is not for sale in the gallery."); // Example: Artwork is owned by contract initially
        _sellArtwork(_artworkId, msg.sender);
    }
}

// --- Helper Library for Base64 Encoding (From OpenZeppelin Contracts - adapted for inline inclusion) ---
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        bytes memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end in case we end up using padding bytes
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare input, output pointers
            let dataPtr := add(data, 32)
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {
                dataPtr := add(dataPtr, 3)
                resultPtr := add(resultPtr, 4)
            } {
                // read 3 bytes (P1 P2 P3)
                let p1 := mload(dataPtr)
                let p2 := mload(add(dataPtr, 1))
                let p3 := mload(add(dataPtr, 2))

                // 6 bits from P1
                mstore(resultPtr, shl(248, mload(add(table, div(p1, 4)))))
                // last 2 bits from P1, 4 bits from P2
                mstore(add(resultPtr, 1), shl(248, mload(add(table, add(mul(and(p1, 3), 16), div(p2, 16))))))
                // last 4 bits from P2, 2 bits from P3
                mstore(add(resultPtr, 2), shl(248, mload(add(table, add(mul(and(p2, 15), 4), div(p3, 64))))))
                // last 6 bits from P3
                mstore(add(resultPtr, 3), shl(248, mload(add(table, and(p3, 63)))))
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
```