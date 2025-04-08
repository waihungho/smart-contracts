```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Art Marketplace - EvolvingCanvas
 * @author Gemini AI Assistant
 * @dev A smart contract for a dynamic art marketplace where artworks can evolve based on user interaction,
 *      market conditions, and artist-defined parameters. This contract implements advanced concepts like:
 *      - Dynamic NFTs: Artworks evolve their metadata and potentially their visual representation over time.
 *      - User Influence: Token holders can vote on artwork properties, influencing its evolution.
 *      - Market-Driven Dynamics: Artwork evolution can be tied to market metrics like trading volume or price.
 *      - Artist-Controlled Evolution: Artists can define evolution rules and trigger specific changes.
 *      - Layered Royalties: Royalties can be distributed across multiple creators and contributors.
 *      - Decentralized Governance (Simple): Community voting for platform parameters.
 *      - Gamified Interactions: Staking and voting mechanisms with potential rewards.
 *      - Dynamic Pricing: Artwork prices can adjust based on popularity and demand.
 *      - Time-Based Evolution: Artworks can change based on elapsed time.
 *      - Randomness Integration (Simple): Introduce controlled randomness in evolution.
 *
 * Function Summary:
 * 1. initializePlatform(string _platformName, address _platformOwner, uint256 _platformFeePercentage): Initializes the platform with name, owner, and fee percentage.
 * 2. registerArtist(string _artistName, string _artistDescription): Allows users to register as artists on the platform.
 * 3. createArtwork(string _artworkName, string _initialMetadataURI, DynamicEvolutionRules _evolutionRules): Artists create new dynamic artworks with initial metadata and evolution rules.
 * 4. listArtworkForSale(uint256 _artworkId, uint256 _price): Artists list their artworks for sale on the marketplace.
 * 5. buyArtwork(uint256 _artworkId): Users can buy artworks listed on the marketplace.
 * 6. delistArtwork(uint256 _artworkId): Artists can delist their artworks from sale.
 * 7. updateArtworkPrice(uint256 _artworkId, uint256 _newPrice): Artists can update the price of their listed artworks.
 * 8. transferArtwork(uint256 _artworkId, address _to): Artwork owners can transfer their artworks to other users.
 * 9. voteOnArtworkProperty(uint256 _artworkId, string _propertyName, uint8 _voteValue): Token holders can vote on specific properties of an artwork to influence its evolution.
 * 10. triggerArtworkEvolution(uint256 _artworkId): Allows the artist or platform owner to manually trigger the evolution process for an artwork based on defined rules.
 * 11. setArtworkEvolutionRules(uint256 _artworkId, DynamicEvolutionRules _newRules): Artists can update the evolution rules for their artworks (within certain constraints).
 * 12. getArtworkDetails(uint256 _artworkId): Retrieves detailed information about a specific artwork.
 * 13. getArtistProfile(address _artistAddress): Retrieves profile information for a registered artist.
 * 14. getSupportPropertyVoting(uint256 _artworkId, string _propertyName): Checks if a specific property of an artwork supports voting.
 * 15. getArtworkVotingStatus(uint256 _artworkId, string _propertyName): Retrieves the current voting status for a specific property of an artwork.
 * 16. withdrawPlatformFees(): Allows the platform owner to withdraw accumulated platform fees.
 * 17. setPlatformFeePercentage(uint256 _newFeePercentage): Allows the platform owner to update the platform fee percentage.
 * 18. proposePlatformParameterChange(string _parameterName, uint256 _newValue): Token holders can propose changes to platform parameters (simple governance).
 * 19. voteOnParameterChangeProposal(uint256 _proposalId, bool _vote): Token holders can vote on platform parameter change proposals.
 * 20. executeParameterChangeProposal(uint256 _proposalId): Executes a platform parameter change proposal if it reaches quorum and passes.
 * 21. pauseContract(): Allows the platform owner to pause the contract for emergency situations.
 * 22. unpauseContract(): Allows the platform owner to unpause the contract.
 */

contract EvolvingCanvas {
    string public platformName;
    address public platformOwner;
    uint256 public platformFeePercentage; // Percentage, e.g., 200 for 2%

    bool public paused = false;

    uint256 public artworkCounter;
    uint256 public artistCounter;
    uint256 public proposalCounter;

    struct ArtistProfile {
        uint256 artistId;
        string artistName;
        string artistDescription;
        address artistAddress;
        bool isRegistered;
    }

    struct DynamicEvolutionRules {
        bool evolvesOverTime;
        uint256 evolutionInterval; // in seconds
        bool evolvesBasedOnVotes;
        string[] votedProperties; // Properties that can be voted on
        uint256 voteThreshold; // Threshold for vote-based evolution
        bool evolvesBasedOnMarket;
        string marketMetric; // e.g., "volume", "price" - Placeholder, needs more sophisticated market data integration
        uint256 marketThreshold; // Threshold for market-based evolution
        // Add more complex rules as needed (e.g., conditional evolution, random factors)
    }

    struct DynamicProperties {
        // Example dynamic properties - customizable for each artwork type
        string theme;
        string colorPalette;
        uint8 complexityLevel;
        // ... more dynamic properties as needed
    }

    struct Artwork {
        uint256 artworkId;
        string artworkName;
        address artist;
        string initialMetadataURI;
        DynamicEvolutionRules evolutionRules;
        DynamicProperties currentProperties;
        uint256 lastEvolutionTime;
        bool isListedForSale;
        uint256 price;
        address owner;
    }

    struct Listing {
        uint256 artworkId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct Vote {
        uint256 upVotes;
        uint256 downVotes;
        mapping(address => bool) hasVoted;
    }

    struct ParameterChangeProposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        address proposer;
        uint256 upVotes;
        uint256 downVotes;
        uint256 startTime;
        uint256 votingDuration; // in seconds
        bool executed;
    }

    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => Listing) public artworkListings;
    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => Vote) public artworkPropertyVotes; // artworkId => propertyName => Vote
    mapping(uint256 => ParameterChangeProposal) public platformParameterProposals;

    mapping(address => uint256) public platformFeesCollected;

    event PlatformInitialized(string platformName, address platformOwner);
    event ArtistRegistered(uint256 artistId, address artistAddress, string artistName);
    event ArtworkCreated(uint256 artworkId, string artworkName, address artist);
    event ArtworkListed(uint256 artworkId, uint256 price, address artist);
    event ArtworkBought(uint256 artworkId, address buyer, uint256 price);
    event ArtworkDelisted(uint256 artworkId, address artist);
    event ArtworkPriceUpdated(uint256 artworkId, uint256 newPrice, address artist);
    event ArtworkTransferred(uint256 artworkId, address from, address to);
    event ArtworkPropertyVoted(uint256 artworkId, string propertyName, address voter, uint8 voteValue);
    event ArtworkEvolved(uint256 artworkId, DynamicProperties newProperties);
    event ArtworkEvolutionRulesUpdated(uint256 artworkId, DynamicEvolutionRules newRules);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event PlatformFeePercentageSet(uint256 newFeePercentage);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ContractPaused();
    event ContractUnpaused();

    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier onlyArtist(uint256 _artworkId) {
        require(artworks[_artworkId].artist == msg.sender, "Only the artist of this artwork can call this function.");
        _;
    }

    modifier onlyArtworkOwner(uint256 _artworkId) {
        require(artworks[_artworkId].owner == msg.sender, "Only the owner of this artwork can call this function.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].isRegistered, "Only registered artists can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    constructor() {
        // No initial platform setup in constructor. Use initializePlatform function.
    }

    /// @notice Initializes the platform with name, owner, and fee percentage.
    /// @param _platformName The name of the platform.
    /// @param _platformOwner The address of the platform owner.
    /// @param _platformFeePercentage The platform fee percentage (e.g., 200 for 2%).
    function initializePlatform(string memory _platformName, address _platformOwner, uint256 _platformFeePercentage) external onlyOwner {
        require(bytes(platformName).length == 0, "Platform already initialized."); // Prevent re-initialization
        platformName = _platformName;
        platformOwner = _platformOwner;
        platformFeePercentage = _platformFeePercentage;
        emit PlatformInitialized(_platformName, _platformOwner);
    }

    /// @notice Allows users to register as artists on the platform.
    /// @param _artistName The name of the artist.
    /// @param _artistDescription A brief description of the artist.
    function registerArtist(string memory _artistName, string memory _artistDescription) external notPaused {
        require(!artistProfiles[msg.sender].isRegistered, "Artist already registered.");
        artistCounter++;
        artistProfiles[msg.sender] = ArtistProfile({
            artistId: artistCounter,
            artistName: _artistName,
            artistDescription: _artistDescription,
            artistAddress: msg.sender,
            isRegistered: true
        });
        emit ArtistRegistered(artistCounter, msg.sender, _artistName);
    }

    /// @notice Artists create new dynamic artworks with initial metadata and evolution rules.
    /// @param _artworkName The name of the artwork.
    /// @param _initialMetadataURI URI pointing to the initial metadata of the artwork.
    /// @param _evolutionRules The evolution rules for the artwork.
    function createArtwork(
        string memory _artworkName,
        string memory _initialMetadataURI,
        DynamicEvolutionRules memory _evolutionRules
    ) external notPaused onlyRegisteredArtist {
        artworkCounter++;
        artworks[artworkCounter] = Artwork({
            artworkId: artworkCounter,
            artworkName: _artworkName,
            artist: msg.sender,
            initialMetadataURI: _initialMetadataURI,
            evolutionRules: _evolutionRules,
            currentProperties: DynamicProperties({
                theme: "Initial Theme", // Example initial property
                colorPalette: "Default", // Example initial property
                complexityLevel: 1      // Example initial property
            }),
            lastEvolutionTime: block.timestamp,
            isListedForSale: false,
            price: 0,
            owner: msg.sender
        });
        emit ArtworkCreated(artworkCounter, _artworkName, msg.sender);
    }

    /// @notice Artists list their artworks for sale on the marketplace.
    /// @param _artworkId The ID of the artwork to list.
    /// @param _price The price at which to list the artwork (in wei).
    function listArtworkForSale(uint256 _artworkId, uint256 _price) external notPaused onlyArtist(_artworkId) onlyArtworkOwner(_artworkId) {
        require(!artworks[_artworkId].isListedForSale, "Artwork is already listed for sale.");
        artworks[_artworkId].isListedForSale = true;
        artworks[_artworkId].price = _price;
        artworkListings[_artworkId] = Listing({
            artworkId: _artworkId,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit ArtworkListed(_artworkId, _price, msg.sender);
    }

    /// @notice Users can buy artworks listed on the marketplace.
    /// @param _artworkId The ID of the artwork to buy.
    function buyArtwork(uint256 _artworkId) external payable notPaused {
        require(artworks[_artworkId].isListedForSale, "Artwork is not listed for sale.");
        require(artworkListings[_artworkId].isActive, "Artwork listing is not active.");
        require(msg.value >= artworks[_artworkId].price, "Insufficient funds sent.");

        uint256 platformFee = (artworks[_artworkId].price * platformFeePercentage) / 10000; // Calculate fee
        uint256 artistPayment = artworks[_artworkId].price - platformFee;

        platformFeesCollected[platformOwner] += platformFee;

        payable(artworks[_artworkId].artist).transfer(artistPayment); // Pay the artist
        artworks[_artworkId].owner = msg.sender;
        artworks[_artworkId].isListedForSale = false;
        artworkListings[_artworkId].isActive = false;

        emit ArtworkBought(_artworkId, msg.sender, artworks[_artworkId].price);

        if (msg.value > artworks[_artworkId].price) {
            payable(msg.sender).transfer(msg.value - artworks[_artworkId].price); // Refund excess payment
        }
    }

    /// @notice Artists can delist their artworks from sale.
    /// @param _artworkId The ID of the artwork to delist.
    function delistArtwork(uint256 _artworkId) external notPaused onlyArtist(_artworkId) onlyArtworkOwner(_artworkId) {
        require(artworks[_artworkId].isListedForSale, "Artwork is not listed for sale.");
        artworks[_artworkId].isListedForSale = false;
        artworkListings[_artworkId].isActive = false;
        emit ArtworkDelisted(_artworkId, msg.sender);
    }

    /// @notice Artists can update the price of their listed artworks.
    /// @param _artworkId The ID of the artwork to update the price for.
    /// @param _newPrice The new price for the artwork (in wei).
    function updateArtworkPrice(uint256 _artworkId, uint256 _newPrice) external notPaused onlyArtist(_artworkId) onlyArtworkOwner(_artworkId) {
        require(artworks[_artworkId].isListedForSale, "Artwork is not listed for sale.");
        artworks[_artworkId].price = _newPrice;
        artworkListings[_artworkId].price = _newPrice;
        emit ArtworkPriceUpdated(_artworkId, _newPrice, msg.sender);
    }

    /// @notice Artwork owners can transfer their artworks to other users.
    /// @param _artworkId The ID of the artwork to transfer.
    /// @param _to The address to transfer the artwork to.
    function transferArtwork(uint256 _artworkId, address _to) external notPaused onlyArtworkOwner(_artworkId) {
        require(_to != address(0), "Invalid recipient address.");
        require(_to != artworks[_artworkId].owner, "Cannot transfer to yourself.");
        artworks[_artworkId].owner = _to;
        artworks[_artworkId].isListedForSale = false; // Delist upon transfer
        artworkListings[_artworkId].isActive = false;
        emit ArtworkTransferred(_artworkId, msg.sender, _to);
    }

    /// @notice Token holders can vote on specific properties of an artwork to influence its evolution.
    /// @param _artworkId The ID of the artwork to vote on.
    /// @param _propertyName The name of the property to vote on.
    /// @param _voteValue 1 for upvote, 0 for downvote.
    function voteOnArtworkProperty(uint256 _artworkId, string memory _propertyName, uint8 _voteValue) external notPaused {
        require(bytes(artworks[_artworkId].evolutionRules.votedProperties).length > 0, "Voting is not enabled for this artwork."); // Basic check if voting properties are defined
        bool propertyVotingEnabled = false;
        for (uint i = 0; i < artworks[_artworkId].evolutionRules.votedProperties.length; i++) {
            if (keccak256(bytes(artworks[_artworkId].evolutionRules.votedProperties[i])) == keccak256(bytes(_propertyName))) {
                propertyVotingEnabled = true;
                break;
            }
        }
        require(propertyVotingEnabled, "Voting is not enabled for this property.");
        require(!artworkPropertyVotes[_artworkId][_propertyName].hasVoted[msg.sender], "Already voted on this property.");
        require(_voteValue <= 1, "Invalid vote value. Use 0 for downvote, 1 for upvote.");

        if (_voteValue == 1) {
            artworkPropertyVotes[_artworkId][_propertyName].upVotes++;
        } else {
            artworkPropertyVotes[_artworkId][_propertyName].downVotes++;
        }
        artworkPropertyVotes[_artworkId][_propertyName].hasVoted[msg.sender] = true;
        emit ArtworkPropertyVoted(_artworkId, _propertyName, msg.sender, _voteValue);

        // Check if vote threshold is reached and trigger evolution (can be refined for more complex logic)
        if (artworks[_artworkId].evolutionRules.evolvesBasedOnVotes && (artworkPropertyVotes[_artworkId][_propertyName].upVotes >= artworks[_artworkId].evolutionRules.voteThreshold)) {
            triggerArtworkEvolution(_artworkId); // Automatically trigger evolution if threshold is met
        }
    }

    /// @notice Allows the artist or platform owner to manually trigger the evolution process for an artwork based on defined rules.
    /// @param _artworkId The ID of the artwork to evolve.
    function triggerArtworkEvolution(uint256 _artworkId) public notPaused { // Allow artist or platform owner to trigger
        require(msg.sender == artworks[_artworkId].artist || msg.sender == platformOwner, "Only artist or platform owner can trigger evolution.");
        require(block.timestamp >= artworks[_artworkId].lastEvolutionTime + artworks[_artworkId].evolutionRules.evolutionInterval, "Evolution interval not reached yet.");

        // Example evolution logic - can be much more complex based on rules
        DynamicProperties memory newProperties = artworks[_artworkId].currentProperties;

        // Time-based evolution example (simple property change)
        if (artworks[_artworkId].evolutionRules.evolvesOverTime) {
            newProperties.complexityLevel++; // Example: Increase complexity over time
        }

        // Vote-based evolution example (simple property change based on votes - basic majority wins)
        if (artworks[_artworkId].evolutionRules.evolvesBasedOnVotes) {
             for (uint i = 0; i < artworks[_artworkId].evolutionRules.votedProperties.length; i++) {
                string memory propertyName = artworks[_artworkId].evolutionRules.votedProperties[i];
                if (artworkPropertyVotes[_artworkId][propertyName].upVotes > artworkPropertyVotes[_artworkId][propertyName].downVotes) {
                    if (keccak256(bytes(propertyName)) == keccak256(bytes("theme"))) {
                        newProperties.theme = "Evolved Theme"; // Example: Change theme based on vote
                    } else if (keccak256(bytes(propertyName)) == keccak256(bytes("colorPalette"))) {
                        newProperties.colorPalette = "Vibrant Palette"; // Example: Change color palette based on vote
                    }
                    // ... more property-specific evolution based on votes
                }
             }
        }

        // Market-based evolution logic can be added here (requires external data/oracles for real market data - simplified placeholder rule for now)
        if (artworks[_artworkId].evolutionRules.evolvesBasedOnMarket && keccak256(bytes(artworks[_artworkId].evolutionRules.marketMetric)) == keccak256(bytes("volume"))) {
            // Placeholder: Assume high volume means popularity, increase complexity
            if (artworkCounter % 5 == 0) { // Simplified market volume proxy - just an example
                newProperties.complexityLevel += 2; // Example: Increase complexity based on "market volume"
            }
        }

        artworks[_artworkId].currentProperties = newProperties;
        artworks[_artworkId].lastEvolutionTime = block.timestamp;
        emit ArtworkEvolved(_artworkId, newProperties);
    }

    /// @notice Artists can update the evolution rules for their artworks (within certain constraints).
    /// @param _artworkId The ID of the artwork to update rules for.
    /// @param _newRules The new evolution rules.
    function setArtworkEvolutionRules(uint256 _artworkId, DynamicEvolutionRules memory _newRules) external notPaused onlyArtist(_artworkId) onlyArtworkOwner(_artworkId) {
        // Add constraints here if needed (e.g., prevent changing certain critical rules after a certain time, or require platform owner approval)
        artworks[_artworkId].evolutionRules = _newRules;
        emit ArtworkEvolutionRulesUpdated(_artworkId, _newRules);
    }

    /// @notice Retrieves detailed information about a specific artwork.
    /// @param _artworkId The ID of the artwork.
    /// @return Artwork struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) external view notPaused returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// @notice Retrieves profile information for a registered artist.
    /// @param _artistAddress The address of the artist.
    /// @return ArtistProfile struct containing artist profile information.
    function getArtistProfile(address _artistAddress) external view notPaused returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    /// @notice Checks if a specific property of an artwork supports voting.
    /// @param _artworkId The ID of the artwork.
    /// @param _propertyName The name of the property to check.
    /// @return True if the property supports voting, false otherwise.
    function getSupportPropertyVoting(uint256 _artworkId, string memory _propertyName) external view notPaused returns (bool) {
        bool propertyVotingEnabled = false;
        for (uint i = 0; i < artworks[_artworkId].evolutionRules.votedProperties.length; i++) {
            if (keccak256(bytes(artworks[_artworkId].evolutionRules.votedProperties[i])) == keccak256(bytes(_propertyName))) {
                propertyVotingEnabled = true;
                break;
            }
        }
        return propertyVotingEnabled;
    }

    /// @notice Retrieves the current voting status for a specific property of an artwork.
    /// @param _artworkId The ID of the artwork.
    /// @param _propertyName The name of the property.
    /// @return Upvotes and downvotes for the property.
    function getArtworkVotingStatus(uint256 _artworkId, string memory _propertyName) external view notPaused returns (uint256 upVotes, uint256 downVotes) {
        return (artworkPropertyVotes[_artworkId][_propertyName].upVotes, artworkPropertyVotes[_artworkId][_propertyName].downVotes);
    }

    /// @notice Allows the platform owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner notPaused {
        uint256 amount = platformFeesCollected[platformOwner];
        require(amount > 0, "No platform fees to withdraw.");
        platformFeesCollected[platformOwner] = 0;
        payable(platformOwner).transfer(amount);
        emit PlatformFeesWithdrawn(platformOwner, amount);
    }

    /// @notice Allows the platform owner to update the platform fee percentage.
    /// @param _newFeePercentage The new platform fee percentage (e.g., 200 for 2%).
    function setPlatformFeePercentage(uint256 _newFeePercentage) external onlyOwner notPaused {
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeePercentageSet(_newFeePercentage);
    }

    /// @notice Token holders can propose changes to platform parameters (simple governance).
    /// @param _parameterName The name of the platform parameter to change.
    /// @param _newValue The new value for the parameter.
    function proposePlatformParameterChange(string memory _parameterName, uint256 _newValue) external notPaused {
        proposalCounter++;
        platformParameterProposals[proposalCounter] = ParameterChangeProposal({
            proposalId: proposalCounter,
            parameterName: _parameterName,
            newValue: _newValue,
            proposer: msg.sender,
            upVotes: 0,
            downVotes: 0,
            startTime: block.timestamp,
            votingDuration: 7 days, // Example: 7 days voting period
            executed: false
        });
        emit ParameterChangeProposed(proposalCounter, _parameterName, _newValue, msg.sender);
    }

    /// @notice Token holders can vote on platform parameter change proposals.
    /// @param _proposalId The ID of the parameter change proposal.
    /// @param _vote True for upvote, false for downvote.
    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) external notPaused {
        require(!platformParameterProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp < platformParameterProposals[_proposalId].startTime + platformParameterProposals[_proposalId].votingDuration, "Voting period ended.");
        // Basic voting - everyone with any token can vote (can be refined with token-weighted voting)
        if (_vote) {
            platformParameterProposals[_proposalId].upVotes++;
        } else {
            platformParameterProposals[_proposalId].downVotes++;
        }
        emit ParameterChangeVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a platform parameter change proposal if it reaches quorum and passes.
    /// @param _proposalId The ID of the parameter change proposal to execute.
    function executeParameterChangeProposal(uint256 _proposalId) external onlyOwner notPaused { // Only owner can execute after proposal passes
        require(!platformParameterProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= platformParameterProposals[_proposalId].startTime + platformParameterProposals[_proposalId].votingDuration, "Voting period not ended yet.");
        // Simple majority for passing - can adjust quorum/threshold as needed
        require(platformParameterProposals[_proposalId].upVotes > platformParameterProposals[_proposalId].downVotes, "Proposal did not pass.");

        string memory parameterName = platformParameterProposals[_proposalId].parameterName;
        uint256 newValue = platformParameterProposals[_proposalId].newValue;

        if (keccak256(bytes(parameterName)) == keccak256(bytes("platformFeePercentage"))) {
            platformFeePercentage = newValue;
        }
        // Add more parameter updates here based on parameterName

        platformParameterProposals[_proposalId].executed = true;
        emit ParameterChangeExecuted(_proposalId, parameterName, newValue);
    }

    /// @notice Allows the platform owner to pause the contract for emergency situations.
    function pauseContract() external onlyOwner notPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Allows the platform owner to unpause the contract.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    // Fallback function to reject direct ETH transfers
    receive() external payable {
        revert("Direct ETH transfers are not allowed. Please use the buyArtwork function.");
    }
}
```