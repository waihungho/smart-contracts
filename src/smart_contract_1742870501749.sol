```solidity
/**
 * @title Decentralized Dynamic Art NFT Marketplace - "Chameleon Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace where NFTs can evolve and change their properties based on owner actions, community votes, or time-based triggers.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core NFT Functionality:**
 *    - `mintDynamicNFT(string memory _name, string memory _initialCID, string memory _description, uint8 _initialEvolutionStage)`: Mints a new Dynamic Art NFT.
 *    - `transferNFT(address _to, uint256 _tokenId)`: Transfers NFT ownership.
 *    - `getNFTMetadata(uint256 _tokenId)`: Retrieves metadata (name, description, current CID, evolution stage) for an NFT.
 *    - `getNFTOwner(uint256 _tokenId)`: Returns the owner of an NFT.
 *    - `getTotalNFTSupply()`: Returns the total number of NFTs minted.
 *
 * **2. Dynamic Evolution System:**
 *    - `defineEvolutionStage(uint8 _stageId, string memory _stageName, string memory _stageCID, string memory _stageDescription, uint256 _evolutionCost)`: Defines a new evolution stage for NFTs.
 *    - `getEvolutionStageDetails(uint8 _stageId)`: Retrieves details of a specific evolution stage.
 *    - `evolveNFT(uint256 _tokenId, uint8 _targetStageId)`: Allows an NFT owner to evolve their NFT to a defined stage, paying an evolution cost.
 *    - `setAutoEvolveTime(uint256 _timeInSeconds)`: Sets the time interval for automatic NFT evolution (governance/admin function).
 *    - `triggerAutoEvolve()`: Manually triggers automatic evolution for eligible NFTs (governance/admin function).
 *
 * **3. Community Interaction & Voting:**
 *    - `enableCommunityVoting(uint256 _tokenId)`: Enables community voting for an NFT's evolution path by its owner.
 *    - `disableCommunityVoting(uint256 _tokenId)`: Disables community voting for an NFT.
 *    - `voteForEvolutionStage(uint256 _tokenId, uint8 _targetStageId)`: Allows NFT holders to vote for the next evolution stage of an NFT with community voting enabled.
 *    - `tallyVotesAndEvolve(uint256 _tokenId)`: Tallies votes for an NFT and evolves it to the winning stage (owner or governance function).
 *    - `getVotingStatus(uint256 _tokenId)`: Returns the current voting status and top voted stage for an NFT.
 *
 * **4. Marketplace Functionality (Basic):**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 *    - `buyNFT(uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 *    - `cancelNFTListing(uint256 _tokenId)`: Allows the owner to cancel an NFT listing.
 *    - `getListingDetails(uint256 _tokenId)`: Retrieves listing details for an NFT (price, seller, listed status).
 *
 * **5. Governance & Admin Functions:**
 *    - `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage for marketplace sales (governance/admin function).
 *    - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *    - `pauseContract()`: Pauses core contract functionalities (emergency stop).
 *    - `unpauseContract()`: Resumes contract functionalities.
 */
pragma solidity ^0.8.0;

contract ChameleonCanvas {
    // ** State Variables **

    // Contract Owner
    address public owner;

    // NFT Details
    uint256 public nftCounter;
    mapping(uint256 => NFT) public nfts;
    mapping(uint256 => address) public nftOwners;

    struct NFT {
        string name;
        string currentCID; // Current Content Identifier (e.g., IPFS CID)
        string description;
        uint8 currentEvolutionStage;
        uint256 lastEvolvedTimestamp;
        bool communityVotingEnabled;
    }

    // Evolution Stages Definition
    uint8 public evolutionStageCounter;
    mapping(uint8 => EvolutionStage) public evolutionStages;

    struct EvolutionStage {
        string stageName;
        string stageCID;
        string stageDescription;
        uint256 evolutionCost; // Cost to evolve to this stage
    }

    // Community Voting
    mapping(uint256 => bool) public isVotingEnabled;
    mapping(uint256 => mapping(address => uint8)) public nftVotes; // tokenId => voter address => target stageId
    mapping(uint256 => uint256) public votingEndTime; // Store the end time for voting periods

    // Marketplace Listings
    mapping(uint256 => Listing) public listings;

    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }

    // Platform Fees
    uint256 public platformFeePercentage = 2; // Default 2% fee
    uint256 public accumulatedPlatformFees;

    // Auto Evolution
    uint256 public autoEvolveTimeInterval = 86400; // Default 24 hours
    uint256 public lastAutoEvolveTrigger;

    // Contract Paused State
    bool public paused;

    // ** Events **
    event NFTMinted(uint256 tokenId, address minter, string name, string initialCID);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTEvolved(uint256 tokenId, uint8 previousStage, uint8 newStage, string newCID);
    event EvolutionStageDefined(uint8 stageId, string stageName);
    event NFTListedForSale(uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTListingCancelled(uint256 tokenId, address seller);
    event CommunityVotingEnabled(uint256 tokenId);
    event CommunityVotingDisabled(uint256 tokenId);
    event VoteCast(uint256 tokenId, address voter, uint8 targetStageId);
    event VotesTalliedAndEvolved(uint256 tokenId, uint8 winningStage);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event ContractPaused();
    event ContractUnpaused();
    event AutoEvolutionTriggered();

    // ** Modifiers **
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwners[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    // ** Constructor **
    constructor() {
        owner = msg.sender;
        nftCounter = 0;
        evolutionStageCounter = 0;
    }

    // ** 1. Core NFT Functionality **

    /// @dev Mints a new Dynamic Art NFT.
    /// @param _name The name of the NFT.
    /// @param _initialCID The initial Content Identifier (CID) for the NFT's metadata.
    /// @param _description A brief description of the NFT.
    /// @param _initialEvolutionStage The initial evolution stage ID.
    function mintDynamicNFT(
        string memory _name,
        string memory _initialCID,
        string memory _description,
        uint8 _initialEvolutionStage
    ) external whenNotPaused returns (uint256 tokenId) {
        nftCounter++;
        tokenId = nftCounter;
        nfts[tokenId] = NFT({
            name: _name,
            currentCID: _initialCID,
            description: _description,
            currentEvolutionStage: _initialEvolutionStage,
            lastEvolvedTimestamp: block.timestamp,
            communityVotingEnabled: false
        });
        nftOwners[tokenId] = msg.sender;
        emit NFTMinted(tokenId, msg.sender, _name, _initialCID);
        return tokenId;
    }

    /// @dev Transfers NFT ownership.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        address currentOwner = nftOwners[_tokenId];
        nftOwners[_tokenId] = _to;
        emit NFTTransferred(_tokenId, currentOwner, _to);
    }

    /// @dev Retrieves metadata (name, description, current CID, evolution stage) for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return NFT metadata (name, description, current CID, evolution stage).
    function getNFTMetadata(uint256 _tokenId) external view returns (string memory name, string memory cid, string memory description, uint8 stage) {
        NFT storage nft = nfts[_tokenId];
        return (nft.name, nft.currentCID, nft.description, nft.currentEvolutionStage);
    }

    /// @dev Returns the owner of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the NFT owner.
    function getNFTOwner(uint256 _tokenId) external view returns (address) {
        return nftOwners[_tokenId];
    }

    /// @dev Returns the total number of NFTs minted.
    /// @return The total NFT supply.
    function getTotalNFTSupply() external view returns (uint256) {
        return nftCounter;
    }

    // ** 2. Dynamic Evolution System **

    /// @dev Defines a new evolution stage for NFTs. Only owner can call.
    /// @param _stageId Unique identifier for the evolution stage.
    /// @param _stageName Name of the evolution stage.
    /// @param _stageCID Content Identifier (CID) for the metadata of this stage.
    /// @param _stageDescription Description of this evolution stage.
    /// @param _evolutionCost Cost in wei to evolve to this stage.
    function defineEvolutionStage(
        uint8 _stageId,
        string memory _stageName,
        string memory _stageCID,
        string memory _stageDescription,
        uint256 _evolutionCost
    ) external onlyOwner whenNotPaused {
        require(evolutionStages[_stageId].stageName.length == 0, "Evolution stage already defined."); // Prevent overwriting
        evolutionStages[_stageId] = EvolutionStage({
            stageName: _stageName,
            stageCID: _stageCID,
            stageDescription: _stageDescription,
            evolutionCost: _evolutionCost
        });
        emit EvolutionStageDefined(_stageId, _stageName);
        if (_stageId > evolutionStageCounter) {
            evolutionStageCounter = _stageId; // Update counter if a higher stage ID is defined
        }
    }

    /// @dev Retrieves details of a specific evolution stage.
    /// @param _stageId The ID of the evolution stage.
    /// @return Details of the evolution stage (name, CID, description, evolution cost).
    function getEvolutionStageDetails(uint8 _stageId) external view returns (string memory stageName, string memory stageCID, string memory stageDescription, uint256 evolutionCost) {
        EvolutionStage storage stage = evolutionStages[_stageId];
        return (stage.stageName, stage.stageCID, stage.stageDescription, stage.evolutionCost);
    }

    /// @dev Allows an NFT owner to evolve their NFT to a defined stage, paying an evolution cost.
    /// @param _tokenId The ID of the NFT to evolve.
    /// @param _targetStageId The target evolution stage ID.
    function evolveNFT(uint256 _tokenId, uint8 _targetStageId) external payable whenNotPaused onlyNFTOwner(_tokenId) {
        require(evolutionStages[_targetStageId].stageName.length > 0, "Target evolution stage not defined.");
        require(_targetStageId > nfts[_tokenId].currentEvolutionStage, "Target stage must be a higher evolution stage.");

        EvolutionStage storage targetStage = evolutionStages[_targetStageId];
        require(msg.value >= targetStage.evolutionCost, "Insufficient evolution cost sent.");

        // Transfer evolution cost to the contract owner (platform fees can be taken from here later)
        payable(owner).transfer(targetStage.evolutionCost);

        _updateNFTStage(_tokenId, _targetStageId, targetStage.stageCID);
        emit NFTEvolved(_tokenId, nfts[_tokenId].currentEvolutionStage, _targetStageId, targetStage.stageCID);
    }

    /// @dev Sets the time interval for automatic NFT evolution (governance/admin function).
    /// @param _timeInSeconds Time interval in seconds.
    function setAutoEvolveTime(uint256 _timeInSeconds) external onlyOwner whenNotPaused {
        autoEvolveTimeInterval = _timeInSeconds;
    }

    /// @dev Manually triggers automatic evolution for eligible NFTs (governance/admin function).
    /// @dev NFTs can auto-evolve if they have not evolved for `autoEvolveTimeInterval` and there's a next stage defined.
    function triggerAutoEvolve() external onlyOwner whenNotPaused {
        require(block.timestamp >= lastAutoEvolveTrigger + autoEvolveTimeInterval, "Auto-evolve can only be triggered after the set interval.");
        lastAutoEvolveTrigger = block.timestamp;

        for (uint256 tokenId = 1; tokenId <= nftCounter; tokenId++) {
            NFT storage nft = nfts[tokenId];
            uint8 currentStage = nft.currentEvolutionStage;
            uint8 nextStage = currentStage + 1; // Assume stages are sequential

            if (evolutionStages[nextStage].stageName.length > 0 && block.timestamp >= nft.lastEvolvedTimestamp + autoEvolveTimeInterval) {
                _autoEvolveNFT(tokenId, nextStage, evolutionStages[nextStage].stageCID);
            }
        }
        emit AutoEvolutionTriggered();
    }

    /// @dev Internal function to automatically evolve an NFT (no cost, used by auto-evolve).
    /// @param _tokenId The ID of the NFT to evolve.
    /// @param _targetStageId The target evolution stage ID.
    /// @param _targetCID The CID for the target evolution stage.
    function _autoEvolveNFT(uint256 _tokenId, uint8 _targetStageId, string memory _targetCID) internal {
        _updateNFTStage(_tokenId, _targetStageId, _targetCID);
        emit NFTEvolved(_tokenId, nfts[_tokenId].currentEvolutionStage, _targetStageId, _targetCID);
    }

    /// @dev Internal function to update NFT stage and CID.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _targetStageId The target evolution stage ID.
    /// @param _targetCID The CID for the target evolution stage.
    function _updateNFTStage(uint256 _tokenId, uint8 _targetStageId, string memory _targetCID) internal {
        nfts[_tokenId].currentEvolutionStage = _targetStageId;
        nfts[_tokenId].currentCID = _targetCID;
        nfts[_tokenId].lastEvolvedTimestamp = block.timestamp;
    }


    // ** 3. Community Interaction & Voting **

    /// @dev Enables community voting for an NFT's evolution path by its owner.
    /// @param _tokenId The ID of the NFT for which to enable voting.
    function enableCommunityVoting(uint256 _tokenId) external onlyNFTOwner(_tokenId) whenNotPaused {
        require(!isVotingEnabled[_tokenId], "Community voting is already enabled for this NFT.");
        isVotingEnabled[_tokenId] = true;
        votingEndTime[_tokenId] = block.timestamp + 7 days; // Set voting period for 7 days (example)
        emit CommunityVotingEnabled(_tokenId);
    }

    /// @dev Disables community voting for an NFT.
    /// @param _tokenId The ID of the NFT for which to disable voting.
    function disableCommunityVoting(uint256 _tokenId) external onlyNFTOwner(_tokenId) whenNotPaused {
        require(isVotingEnabled[_tokenId], "Community voting is not enabled for this NFT.");
        isVotingEnabled[_tokenId] = false;
        delete votingEndTime[_tokenId]; // Clear voting end time
        emit CommunityVotingDisabled(_tokenId);
    }

    /// @dev Allows NFT holders to vote for the next evolution stage of an NFT with community voting enabled.
    /// @param _tokenId The ID of the NFT being voted on.
    /// @param _targetStageId The evolution stage the voter is voting for.
    function voteForEvolutionStage(uint256 _tokenId, uint8 _targetStageId) external whenNotPaused {
        require(isVotingEnabled[_tokenId], "Community voting is not enabled for this NFT.");
        require(nftOwners[_tokenId] != msg.sender, "NFT owner cannot vote on their own NFT."); // Owner should not vote
        require(nftOwners[_tokenId] == nftOwners[_tokenId], "Only NFT holders can vote (for now, everyone can vote)."); // In real scenario, check if msg.sender holds *any* NFT or specific collection NFTs
        require(evolutionStages[_targetStageId].stageName.length > 0, "Target evolution stage not defined.");
        require(block.timestamp < votingEndTime[_tokenId], "Voting period has ended.");

        nftVotes[_tokenId][msg.sender] = _targetStageId;
        emit VoteCast(_tokenId, msg.sender, _targetStageId);
    }

    /// @dev Tallies votes for an NFT and evolves it to the winning stage (owner or governance function).
    /// @param _tokenId The ID of the NFT to tally votes for.
    function tallyVotesAndEvolve(uint256 _tokenId) external onlyNFTOwner(_tokenId) whenNotPaused {
        require(isVotingEnabled[_tokenId], "Community voting is not enabled for this NFT.");
        require(block.timestamp >= votingEndTime[_tokenId], "Voting period has not ended yet.");

        uint8 winningStage = nfts[_tokenId].currentEvolutionStage; // Default to current stage if no votes or tie
        uint256 maxVotes = 0;
        mapping(uint8 => uint256) stageVotes;

        // Tally Votes
        for (uint8 stageId = 1; stageId <= evolutionStageCounter; stageId++) { // Iterate through defined stages
            stageVotes[stageId] = 0;
        }
        for (address voter : nftVotes[_tokenId]) {
            uint8 votedStage = nftVotes[_tokenId][voter];
            stageVotes[votedStage]++;
        }

        // Determine Winning Stage (simplest: first with most votes)
        for (uint8 stageId = nfts[_tokenId].currentEvolutionStage + 1; stageId <= evolutionStageCounter; stageId++) {
             if (stageVotes[stageId] > maxVotes) {
                maxVotes = stageVotes[stageId];
                winningStage = stageId;
            }
        }

        if (winningStage > nfts[_tokenId].currentEvolutionStage) {
            _updateNFTStage(_tokenId, winningStage, evolutionStages[winningStage].stageCID);
            emit VotesTalliedAndEvolved(_tokenId, winningStage);
        }

        isVotingEnabled[_tokenId] = false; // Voting finished, disable voting
        delete votingEndTime[_tokenId];
        delete nftVotes[_tokenId]; // Clear votes after tallying
    }

    /// @dev Returns the current voting status and top voted stage for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return Voting status (enabled/disabled), voting end time, and top voted stage (if voting enabled).
    function getVotingStatus(uint256 _tokenId) external view returns (bool votingEnabled, uint256 endTime, uint8 topVotedStage) {
        votingEnabled = isVotingEnabled[_tokenId];
        endTime = votingEndTime[_tokenId];

        if (votingEnabled) {
            uint8 currentTopStage = nfts[_tokenId].currentEvolutionStage;
            uint256 maxVotes = 0;
            mapping(uint8 => uint256) stageVotes;

            for (uint8 stageId = 1; stageId <= evolutionStageCounter; stageId++) {
                stageVotes[stageId] = 0;
            }
            for (address voter : nftVotes[_tokenId]) {
                uint8 votedStage = nftVotes[_tokenId][voter];
                stageVotes[votedStage]++;
            }

             for (uint8 stageId = nfts[_tokenId].currentEvolutionStage + 1; stageId <= evolutionStageCounter; stageId++) {
                 if (stageVotes[stageId] > maxVotes) {
                    maxVotes = stageVotes[stageId];
                    currentTopStage = stageId;
                }
            }
            topVotedStage = currentTopStage;
        } else {
            topVotedStage = 0; // No top voted stage if voting disabled
        }
        return (votingEnabled, endTime, topVotedStage);
    }


    // ** 4. Marketplace Functionality (Basic) **

    /// @dev Lists an NFT for sale in the marketplace.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The price in wei to list the NFT for.
    function listNFTForSale(uint256 _tokenId, uint256 _price) external onlyNFTOwner(_tokenId) whenNotPaused {
        require(_price > 0, "Price must be greater than zero.");
        listings[_tokenId] = Listing({
            seller: msg.sender,
            price: _price,
            isListed: true
        });
        emit NFTListedForSale(_tokenId, msg.sender, _price);
    }

    /// @dev Allows anyone to buy a listed NFT.
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) external payable whenNotPaused {
        require(listings[_tokenId].isListed, "NFT is not listed for sale.");
        Listing storage listing = listings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds sent.");

        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - platformFee;

        // Transfer funds: Buyer -> Seller
        payable(listing.seller).transfer(sellerProceeds);
        // Transfer platform fee to contract balance
        accumulatedPlatformFees += platformFee;

        // Transfer NFT ownership
        address previousOwner = nftOwners[_tokenId];
        nftOwners[_tokenId] = msg.sender;

        // Remove from listing
        delete listings[_tokenId]; // or set isListed = false;
        emit NFTBought(_tokenId, msg.sender, previousOwner, listing.price);
        emit NFTTransferred(_tokenId, previousOwner, msg.sender);
    }

    /// @dev Allows the owner to cancel an NFT listing.
    /// @param _tokenId The ID of the NFT listing to cancel.
    function cancelNFTListing(uint256 _tokenId) external onlyNFTOwner(_tokenId) whenNotPaused {
        require(listings[_tokenId].isListed, "NFT is not currently listed for sale.");
        require(listings[_tokenId].seller == msg.sender, "Only the seller can cancel the listing.");

        delete listings[_tokenId]; // or set isListed = false;
        emit NFTListingCancelled(_tokenId, msg.sender);
    }

    /// @dev Retrieves listing details for an NFT (price, seller, listed status).
    /// @param _tokenId The ID of the NFT.
    /// @return Listing details (seller address, price, listed status).
    function getListingDetails(uint256 _tokenId) external view returns (address seller, uint256 price, bool isListed) {
        Listing storage listing = listings[_tokenId];
        return (listing.seller, listing.price, listing.isListed);
    }

    // ** 5. Governance & Admin Functions **

    /// @dev Sets the platform fee percentage for marketplace sales (governance/admin function).
    /// @param _feePercentage The platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        require(_feePercentage <= 10, "Platform fee percentage cannot exceed 10%."); // Example limit
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @dev Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        uint256 amount = accumulatedPlatformFees;
        accumulatedPlatformFees = 0; // Reset to zero after withdrawal
        payable(owner).transfer(amount);
        emit PlatformFeesWithdrawn(amount, owner);
    }

    /// @dev Pauses core contract functionalities (emergency stop).
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @dev Resumes contract functionalities.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // ** Fallback and Receive functions (Optional - for receiving ETH if needed) **
    receive() external payable {}
    fallback() external payable {}
}
```