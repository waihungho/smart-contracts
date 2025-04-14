```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Gallery - Advanced Smart Contract
 * @author Bard (Example - Not for Production)
 *
 * @dev This smart contract implements a Decentralized Dynamic NFT Gallery where NFTs can be
 *      minted, showcased in galleries, and their properties can dynamically change based on
 *      community voting and external data feeds (simulated for demonstration).
 *
 * Function Summary:
 * -----------------
 * **NFT Management:**
 * 1.  `mintNFT(address _to, string memory _uri)`: Mints a new NFT with a given URI.
 * 2.  `burnNFT(uint256 _tokenId)`: Burns (destroys) an NFT.
 * 3.  `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to another address.
 * 4.  `setNFTBaseURI(string memory _baseURI)`: Sets the base URI for NFT metadata.
 * 5.  `getNFTMetadataURI(uint256 _tokenId)`: Retrieves the metadata URI for a specific NFT.
 *
 * **Gallery Management:**
 * 6.  `createGallery(string memory _galleryName)`: Creates a new gallery.
 * 7.  `addNFTtoGallery(uint256 _galleryId, uint256 _tokenId)`: Adds an NFT to a specific gallery.
 * 8.  `removeNFTfromGallery(uint256 _galleryId, uint256 _tokenId)`: Removes an NFT from a gallery.
 * 9.  `setGalleryCurator(uint256 _galleryId, address _curator)`: Sets a curator for a gallery.
 * 10. `getGalleryNFTs(uint256 _galleryId)`: Retrieves a list of NFT IDs in a gallery.
 * 11. `getGalleryCurator(uint256 _galleryId)`: Retrieves the curator address of a gallery.
 * 12. `getGalleryName(uint256 _galleryId)`: Retrieves the name of a gallery.
 *
 * **Dynamic NFT Features (Voting & Data Feed Simulation):**
 * 13. `startVotingRound(uint256 _galleryId, string[] memory _options, uint256 _durationSeconds)`: Starts a voting round for a gallery to dynamically change NFT properties.
 * 14. `castVote(uint256 _galleryId, uint256 _optionIndex)`: Allows users to cast a vote in a gallery's active voting round.
 * 15. `tallyVotes(uint256 _galleryId)`: Tallies the votes for a gallery's voting round and applies the winning option (simulated metadata update).
 * 16. `simulateDataFeedUpdate(uint256 _galleryId, string memory _newData)`: Simulates an external data feed update that can dynamically change gallery or NFT properties.
 *
 * **Utility & Features:**
 * 17. `giftNFT(uint256 _tokenId, address _recipient)`: Allows NFT owners to gift NFTs (internal transfer with message).
 * 18. `featureNFTinGallery(uint256 _galleryId, uint256 _tokenId)`:  Marks an NFT as "featured" within a gallery (for display priority).
 * 19. `pauseContract()`: Pauses core functionalities of the contract (minting, voting, etc.).
 * 20. `unpauseContract()`: Resumes paused functionalities.
 * 21. `withdrawContractBalance()`: Allows the contract owner to withdraw ETH balance from the contract.
 * 22. `setPlatformFee(uint256 _feePercentage)`: Sets a platform fee percentage for certain actions (e.g., minting, future marketplace features).
 * 23. `getPlatformFee()`: Retrieves the current platform fee percentage.
 */
contract DynamicNFTGallery {
    // --- State Variables ---
    address public owner;
    string public nftBaseURI;
    uint256 public nftCount;
    uint256 public galleryCount;
    uint256 public platformFeePercentage; // Example platform fee

    bool public paused;

    mapping(uint256 => string) public nftMetadataURIs;
    mapping(uint256 => address) public nftOwners;
    mapping(uint256 => uint256) public nftGalleries; // NFT ID -> Gallery ID (if in a gallery)

    struct Gallery {
        string name;
        address curator;
        uint256[] nfts;
        VotingRound activeVotingRound;
        string dynamicData; // Example: Store dynamic data from data feed or voting
        uint256 featuredNFTId; // ID of featured NFT in the gallery
    }
    mapping(uint256 => Gallery) public galleries;

    struct VotingRound {
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        string[] options;
        mapping(address => uint256) votes; // Voter address -> Option Index
        uint256 winningOptionIndex;
        bool votesTallied;
    }

    // --- Events ---
    event NFTMinted(uint256 tokenId, address minter, string tokenURI);
    event NFTBurned(uint256 tokenId);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event GalleryCreated(uint256 galleryId, string galleryName, address creator);
    event NFTAddedToGallery(uint256 galleryId, uint256 tokenId);
    event NFTRemovedFromGallery(uint256 galleryId, uint256 tokenId);
    event GalleryCuratorSet(uint256 galleryId, address curator, address setter);
    event VotingRoundStarted(uint256 galleryId, uint256 startTime, uint256 endTime, string[] options);
    event VoteCast(uint256 galleryId, address voter, uint256 optionIndex);
    event VotesTallied(uint256 galleryId, uint256 winningOptionIndex);
    event DataFeedUpdated(uint256 galleryId, string newData);
    event NFTFeaturedInGallery(uint256 galleryId, uint256 tokenId);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event PlatformFeeSet(uint256 feePercentage, address setter);
    event BalanceWithdrawn(address recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator(uint256 _galleryId) {
        require(galleries[_galleryId].curator == msg.sender, "Only gallery curator can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    // --- Constructor ---
    constructor(string memory _baseURI) {
        owner = msg.sender;
        nftBaseURI = _baseURI;
        nftCount = 0;
        galleryCount = 0;
        platformFeePercentage = 0; // Default fee is 0%
        paused = false;
    }

    // --- NFT Management Functions ---
    function mintNFT(address _to, string memory _uri) public onlyOwner whenNotPaused {
        require(_to != address(0), "Invalid recipient address.");
        nftCount++;
        uint256 tokenId = nftCount;
        nftMetadataURIs[tokenId] = string(abi.encodePacked(nftBaseURI, _uri)); // Combine base URI and specific URI
        nftOwners[tokenId] = _to;
        emit NFTMinted(tokenId, _to, nftMetadataURIs[tokenId]);
    }

    function burnNFT(uint256 _tokenId) public onlyOwner whenNotPaused {
        require(nftOwners[_tokenId] != address(0), "NFT does not exist.");
        delete nftMetadataURIs[_tokenId];
        delete nftOwners[_tokenId];
        if (nftGalleries[_tokenId] != 0) {
            removeNFTfromGallery(nftGalleries[_tokenId], _tokenId); // Remove from gallery if it's in one
            delete nftGalleries[_tokenId];
        }
        emit NFTBurned(_tokenId);
    }

    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused {
        require(nftOwners[_tokenId] == msg.sender, "Not NFT owner.");
        require(_to != address(0), "Invalid recipient address.");
        nftOwners[_tokenId] = _to;
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    function setNFTBaseURI(string memory _baseURI) public onlyOwner {
        nftBaseURI = _baseURI;
        // Consider emitting an event for URI update if needed
    }

    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(nftOwners[_tokenId] != address(0), "NFT does not exist.");
        return nftMetadataURIs[_tokenId];
    }

    // --- Gallery Management Functions ---
    function createGallery(string memory _galleryName) public onlyOwner whenNotPaused {
        galleryCount++;
        uint256 galleryId = galleryCount;
        galleries[galleryId] = Gallery({
            name: _galleryName,
            curator: msg.sender, // Creator is initial curator
            nfts: new uint256[](0),
            activeVotingRound: VotingRound({isActive: false, startTime: 0, endTime: 0, options: new string[](0), votes: mapping(address => uint256)(), winningOptionIndex: 0, votesTallied: false}),
            dynamicData: "",
            featuredNFTId: 0
        });
        emit GalleryCreated(galleryId, _galleryName, msg.sender);
    }

    function addNFTtoGallery(uint256 _galleryId, uint256 _tokenId) public onlyCurator(_galleryId) whenNotPaused {
        require(nftOwners[_tokenId] != address(0), "NFT does not exist.");
        require(nftGalleries[_tokenId] == 0, "NFT already in a gallery or assigned."); // Check if NFT is already assigned to a gallery
        galleries[_galleryId].nfts.push(_tokenId);
        nftGalleries[_tokenId] = _galleryId; // Track which gallery the NFT is in
        emit NFTAddedToGallery(_galleryId, _tokenId);
    }

    function removeNFTfromGallery(uint256 _galleryId, uint256 _tokenId) public onlyCurator(_galleryId) whenNotPaused {
        require(nftOwners[_tokenId] != address(0), "NFT does not exist.");
        require(nftGalleries[_tokenId] == _galleryId, "NFT is not in this gallery.");

        uint256[] storage galleryNFTs = galleries[_galleryId].nfts;
        for (uint256 i = 0; i < galleryNFTs.length; i++) {
            if (galleryNFTs[i] == _tokenId) {
                // Remove element, maintain order (less gas efficient for large arrays, consider other data structures if performance critical)
                for (uint256 j = i; j < galleryNFTs.length - 1; j++) {
                    galleryNFTs[j] = galleryNFTs[j + 1];
                }
                galleryNFTs.pop();
                delete nftGalleries[_tokenId]; // Clear gallery assignment for NFT
                emit NFTRemovedFromGallery(_galleryId, _tokenId);
                return;
            }
        }
        revert("NFT not found in gallery (internal error)."); // Should not reach here if previous check is correct
    }

    function setGalleryCurator(uint256 _galleryId, address _curator) public onlyCurator(_galleryId) whenNotPaused {
        require(_curator != address(0), "Invalid curator address.");
        galleries[_galleryId].curator = _curator;
        emit GalleryCuratorSet(_galleryId, _curator, msg.sender);
    }

    function getGalleryNFTs(uint256 _galleryId) public view returns (uint256[] memory) {
        return galleries[_galleryId].nfts;
    }

    function getGalleryCurator(uint256 _galleryId) public view returns (address) {
        return galleries[_galleryId].curator;
    }

    function getGalleryName(uint256 _galleryId) public view returns (string memory) {
        return galleries[_galleryId].name;
    }

    // --- Dynamic NFT Features (Voting & Data Feed Simulation) ---
    function startVotingRound(uint256 _galleryId, string[] memory _options, uint256 _durationSeconds) public onlyCurator(_galleryId) whenNotPaused {
        require(!galleries[_galleryId].activeVotingRound.isActive, "Voting round already active.");
        require(_options.length > 1, "Need at least two voting options.");
        require(_durationSeconds > 0, "Voting duration must be positive.");

        galleries[_galleryId].activeVotingRound = VotingRound({
            isActive: true,
            startTime: block.timestamp,
            endTime: block.timestamp + _durationSeconds,
            options: _options,
            votes: mapping(address => uint256)(),
            winningOptionIndex: 0,
            votesTallied: false
        });
        emit VotingRoundStarted(_galleryId, block.timestamp, block.timestamp + _durationSeconds, _options);
    }

    function castVote(uint256 _galleryId, uint256 _optionIndex) public whenNotPaused {
        VotingRound storage round = galleries[_galleryId].activeVotingRound;
        require(round.isActive, "No active voting round.");
        require(block.timestamp <= round.endTime, "Voting round has ended.");
        require(_optionIndex < round.options.length, "Invalid option index.");
        require(round.votes[msg.sender] == 0, "Already voted."); // Simple 1-vote per user

        round.votes[msg.sender] = _optionIndex + 1; // Store option index (1-based to distinguish from 0 default)
        emit VoteCast(_galleryId, msg.sender, _optionIndex);
    }

    function tallyVotes(uint256 _galleryId) public onlyCurator(_galleryId) whenNotPaused {
        VotingRound storage round = galleries[_galleryId].activeVotingRound;
        require(round.isActive, "No active voting round.");
        require(block.timestamp > round.endTime, "Voting round not yet ended.");
        require(!round.votesTallied, "Votes already tallied.");

        uint256[] memory voteCounts = new uint256[](round.options.length);
        uint256 winningOptionIndex = 0;
        uint256 maxVotes = 0;

        for (uint256 i = 0; i < round.options.length; i++) {
            voteCounts[i] = 0;
        }

        // Count votes for each option
        for (uint256 i = 0; i < round.options.length; i++) {
            for (address voter in round.votes) {
                if (round.votes[voter] == (i + 1)) { // Votes are 1-based
                    voteCounts[i]++;
                }
            }
            if (voteCounts[i] > maxVotes) {
                maxVotes = voteCounts[i];
                winningOptionIndex = i;
            }
        }

        round.winningOptionIndex = winningOptionIndex;
        round.isActive = false; // End voting round
        round.votesTallied = true;

        // --- Example Dynamic Update based on winning option ---
        galleries[_galleryId].dynamicData = round.options[winningOptionIndex]; // Store winning option as dynamic data example
        // In a real scenario, you might update NFT metadata, gallery theme, etc., based on the winning option.
        // For instance, if options were ["Retro Style", "Modern Style", "Futuristic Style"], and "Modern Style" wins,
        // you could update the gallery's display style or even trigger updates to NFTs within the gallery
        // (if NFTs are designed to be dynamically updatable).

        emit VotesTallied(_galleryId, winningOptionIndex);
    }

    function simulateDataFeedUpdate(uint256 _galleryId, string memory _newData) public onlyCurator(_galleryId) whenNotPaused {
        // This is a simplified simulation. In a real application, you would integrate with an oracle or external service.
        galleries[_galleryId].dynamicData = _newData;
        // Example: You could update NFT metadata, gallery display, etc., based on this external data.
        // For instance, if the data feed is a weather API, you could change the gallery's background based on the weather.
        emit DataFeedUpdated(_galleryId, _newData);
    }

    // --- Utility & Features ---
    function giftNFT(uint256 _tokenId, address _recipient) public whenNotPaused {
        require(nftOwners[_tokenId] == msg.sender, "Not NFT owner.");
        require(_recipient != address(0), "Invalid recipient address.");
        address from = msg.sender;
        nftOwners[_tokenId] = _recipient;
        emit NFTTransferred(_tokenId, from, _recipient);
        // Optionally, you can add a message or note to the gift in a more advanced implementation.
    }

    function featureNFTinGallery(uint256 _galleryId, uint256 _tokenId) public onlyCurator(_galleryId) whenNotPaused {
        require(nftGalleries[_tokenId] == _galleryId, "NFT is not in this gallery.");
        galleries[_galleryId].featuredNFTId = _tokenId;
        emit NFTFeaturedInGallery(_galleryId, _tokenId);
    }

    // --- Pause/Unpause Functionality ---
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- Platform Fee Management ---
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage, msg.sender);
    }

    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    // --- Withdrawal Function ---
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit BalanceWithdrawn(owner, balance);
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}
```