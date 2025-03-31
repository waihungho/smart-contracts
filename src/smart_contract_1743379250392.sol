```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution (DDNE)
 * @author Bard (AI Assistant)
 * @dev A smart contract for creating dynamic NFTs that evolve through user interaction,
 * governance, and on-chain events. This contract implements a unique evolution
 * mechanism, decentralized governance for evolution paths, and innovative features
 * to enhance NFT utility and engagement.

 * **Outline & Function Summary:**

 * **Contract Overview:**
 *   - Implements a dynamic NFT standard, extending beyond basic ERC721.
 *   - NFTs evolve through stages based on user actions, governance proposals, and time.
 *   - Features a staking mechanism for NFTs to earn "Evolution Points" (EP).
 *   - Decentralized governance allows community to vote on evolution paths and contract parameters.
 *   - Includes a basic marketplace functionality for trading evolved NFTs.
 *   - Implements a "Synergy System" for combining NFTs to unlock unique traits.
 *   - Features a "Rarity Score" dynamically calculated based on evolution history and traits.
 *   - Introduces "Skill Trees" within NFTs that can be unlocked through evolution.

 * **Function Categories:**

 * **1. Core NFT Functions (ERC721-like with extensions):**
 *   - `mintNFT(address _to, string memory _baseURI)`: Mints a new base-level NFT.
 *   - `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers NFT ownership.
 *   - `approveNFT(address _approved, uint256 _tokenId)`: Approves an address to operate on a single NFT.
 *   - `setApprovalForAllNFT(address _operator, bool _approved)`: Sets approval for all NFTs for an operator.
 *   - `getApprovedNFT(uint256 _tokenId)`: Gets the approved address for a specific NFT.
 *   - `isApprovedForAllNFT(address _owner, address _operator)`: Checks if an operator is approved for all NFTs of an owner.
 *   - `ownerOfNFT(uint256 _tokenId)`: Returns the owner of an NFT.
 *   - `balanceOfNFT(address _owner)`: Returns the NFT balance of an owner.
 *   - `totalSupplyNFT()`: Returns the total supply of NFTs.
 *   - `tokenURINFT(uint256 _tokenId)`: Returns the URI for an NFT's metadata (dynamic based on evolution).

 * **2. Evolution and Staking Functions:**
 *   - `stakeNFT(uint256 _tokenId)`: Stakes an NFT to start earning Evolution Points (EP).
 *   - `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT, claiming accumulated EP.
 *   - `claimEvolutionPoints(uint256 _tokenId)`: Manually claims accumulated EP for a staked NFT.
 *   - `evolveNFT(uint256 _tokenId, uint8 _evolutionPath)`: Evolves an NFT to the next stage, consuming EP and choosing an evolution path.
 *   - `getNFTStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 *   - `getNFTAttributes(uint256 _tokenId)`: Returns the current attributes of an NFT (dynamic based on evolution).
 *   - `getNFTEvolutionPoints(uint256 _tokenId)`: Returns the accumulated Evolution Points for an NFT.

 * **3. Decentralized Governance Functions:**
 *   - `proposeEvolutionPath(string memory _proposalDescription, uint8 _stage, uint8 _pathId, AttributeChange[] memory _attributeChanges)`:  Proposes a new evolution path for a specific stage (governance function).
 *   - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on evolution proposals.
 *   - `executeProposal(uint256 _proposalId)`: Executes an approved evolution proposal (admin/governance executed).
 *   - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.

 * **4. Synergy and Rarity Functions:**
 *   - `performSynergy(uint256 _tokenId1, uint256 _tokenId2)`: Attempts to perform synergy between two NFTs to unlock traits (requires specific conditions).
 *   - `calculateRarityScore(uint256 _tokenId)`: Calculates a dynamic rarity score for an NFT based on its evolution history and attributes.
 *   - `getNFTTraits(uint256 _tokenId)`: Returns the unlocked traits of an NFT (influenced by synergy and evolution paths).

 * **5. Marketplace (Basic) Functions:**
 *   - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the contract's marketplace.
 *   - `purchaseNFT(uint256 _tokenId)`: Allows purchasing a listed NFT.
 *   - `cancelListing(uint256 _tokenId)`: Cancels an NFT listing.
 *   - `getListingDetails(uint256 _tokenId)`: Retrieves details of a specific NFT listing.

 * **6. Admin/Utility Functions:**
 *   - `setEvolutionPointRate(uint256 _newRate)`: Admin function to set the rate of Evolution Point accumulation.
 *   - `withdrawContractBalance()`: Admin function to withdraw contract's ETH balance.
 *   - `pauseContract()`: Admin function to pause core contract functionalities.
 *   - `unpauseContract()`: Admin function to unpause contract functionalities.

 * **Data Structures:**
 *   - `NFTData`: Stores core NFT information like stage, attributes, EP, etc.
 *   - `EvolutionPath`: Defines an evolution path with attribute changes and stage transition.
 *   - `AttributeChange`: Structure to define changes in NFT attributes during evolution.
 *   - `GovernanceProposal`: Structure to store details of evolution path proposals.
 *   - `NFTListing`: Structure to store NFT marketplace listing details.
 */

contract DecentralizedDynamicNFT {
    // --- State Variables ---

    string public name = "Dynamic Evolving NFT";
    string public symbol = "DDNFT";
    string public baseURI; // Base URI for token metadata, can be updated by admin

    address public admin;
    bool public paused = false;

    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public nftApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    uint256 public evolutionPointRate = 1; // EP per time unit staked (e.g., per block)
    uint256 public nextProposalId = 1;

    // --- Data Structures ---

    enum NFTStage { BASE, STAGE_1, STAGE_2, STAGE_3, STAGE_4, STAGE_MAX } // Define evolution stages

    struct NFTData {
        NFTStage stage;
        uint256 evolutionPoints;
        uint256 lastStakeTime;
        mapping(string => uint256) attributes; // Dynamic attributes, can be expanded
        string[] traits; // Unlocked traits from synergy or specific paths
    }

    struct AttributeChange {
        string attributeName;
        int256 changeValue; // Can be positive or negative
    }

    struct EvolutionPath {
        uint8 stage; // Stage to evolve to
        uint8 pathId; // Identifier for the evolution path within a stage
        string description;
        AttributeChange[] attributeChanges;
        uint256 evolutionPointCost;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        uint8 stage;
        uint8 pathId;
        AttributeChange[] attributeChanges;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 executionTimestamp;
    }

    struct NFTListing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
    }

    // --- Mappings ---

    mapping(uint256 => NFTData) public nftData;
    mapping(NFTStage => mapping(uint8 => EvolutionPath)) public evolutionPaths; // Stage -> PathId -> EvolutionPath
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => NFTListing) public nftListings;
    mapping(uint256 => uint256) public nftStakeStartTime; // Track stake start time for EP calculation


    // --- Events ---

    event NFTMinted(uint256 tokenId, address to);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTApproved(uint256 tokenId, address approved);
    event ApprovalForAllSet(address owner, address operator, bool approved);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, uint256 tokenIdUnstaked, address owner, uint256 evolutionPointsClaimed);
    event EvolutionPointsClaimed(uint256 tokenId, address owner, uint256 evolutionPoints);
    event NFTEvolved(uint256 tokenId, NFTStage fromStage, NFTStage toStage, uint8 evolutionPathId);
    event EvolutionPathProposed(uint256 proposalId, string description, uint8 stage, uint8 pathId);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event NFTListedForSale(uint256 tokenId, address seller, uint256 price);
    event NFTPurchased(uint256 tokenId, address buyer, address seller, uint256 price);
    event ListingCancelled(uint256 tokenId);
    event EvolutionPointRateUpdated(uint256 newRate);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
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

    modifier validTokenId(uint256 _tokenId) {
        require(ownerOf[_tokenId] != address(0), "Invalid token ID.");
        _;
    }

    modifier onlyOwnerOfNFT(uint256 _tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "Not NFT owner.");
        _;
    }

    modifier approvedOrOwner(address _spender, uint256 _tokenId) {
        require(ownerOf[_tokenId] == _spender || nftApprovals[_tokenId] == _spender || operatorApprovals[ownerOf[_tokenId]][_spender], "Not approved or owner.");
        _;
    }

    // --- Constructor ---

    constructor(string memory _baseTokenURI) {
        admin = msg.sender;
        baseURI = _baseTokenURI;
    }

    // --- 1. Core NFT Functions ---

    /**
     * @dev Mints a new base-level NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The base URI for token metadata.
     */
    function mintNFT(address _to, string memory _baseURI) public onlyAdmin whenNotPaused {
        totalSupply++;
        uint256 newTokenId = totalSupply;
        ownerOf[newTokenId] = _to;
        balanceOf[_to]++;
        nftData[newTokenId] = NFTData({
            stage: NFTStage.BASE,
            evolutionPoints: 0,
            lastStakeTime: 0,
            attributes: initializeBaseAttributes(), // Function to define base attributes
            traits: new string[](0)
        });
        baseURI = _baseURI; // Update base URI if needed on minting (or separate admin function)

        emit NFTMinted(newTokenId, _to);
    }

    /**
     * @dev Transfers ownership of an NFT.
     * @param _from The current owner address.
     * @param _to The recipient address.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused validTokenId(_tokenId) approvedOrOwner(msg.sender, _tokenId) {
        require(ownerOf[_tokenId] == _from, "Transfer from incorrect owner");
        require(_to != address(0), "Transfer to the zero address");

        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Approves another address to operate on the specified NFT.
     * @param _approved The address to be approved.
     * @param _tokenId The ID of the NFT to be approved.
     */
    function approveNFT(address _approved, uint256 _tokenId) public whenNotPaused validTokenId(_tokenId) onlyOwnerOfNFT(_tokenId) {
        nftApprovals[_tokenId] = _approved;
        emit NFTApproved(_tokenId, _approved);
    }

    /**
     * @dev Sets or revokes approval for an operator to manage all of the caller's NFTs.
     * @param _operator The address of the operator.
     * @param _approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAllNFT(address _operator, bool _approved) public whenNotPaused {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAllSet(msg.sender, _operator, _approved);
    }

    /**
     * @dev Gets the approved address for a single NFT.
     * @param _tokenId The ID of the NFT to get approval for.
     * @return The approved address, or zero address if no approval set.
     */
    function getApprovedNFT(uint256 _tokenId) public view validTokenId(_tokenId) returns (address) {
        return nftApprovals[_tokenId];
    }

    /**
     * @dev Checks if an operator is approved to manage all NFTs of an owner.
     * @param _owner The address of the NFT owner.
     * @param _operator The address of the operator.
     * @return True if the operator is approved for all, false otherwise.
     */
    function isApprovedForAllNFT(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /**
     * @dev Returns the owner of the specified NFT.
     * @param _tokenId The ID of the NFT to query.
     * @return The address of the owner.
     */
    function ownerOfNFT(uint256 _tokenId) public view validTokenId(_tokenId) returns (address) {
        return ownerOf[_tokenId];
    }

    /**
     * @dev Returns the number of NFTs owned by an address.
     * @param _owner The address to query.
     * @return The number of NFTs owned by _owner.
     */
    function balanceOfNFT(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }

    /**
     * @dev Returns the total number of NFTs minted.
     * @return The total number of NFTs.
     */
    function totalSupplyNFT() public view returns (uint256) {
        return totalSupply;
    }

    /**
     * @dev Returns the URI for the metadata of an NFT, dynamically generated based on evolution.
     * @param _tokenId The ID of the NFT.
     * @return The URI string.
     */
    function tokenURINFT(uint256 _tokenId) public view validTokenId(_tokenId) returns (string memory) {
        // In a real application, this would construct a URI based on NFT data, stage, attributes, etc.
        // For simplicity, we return a basic URI based on baseURI and tokenId.
        // This is a placeholder - in production, use a proper metadata generation service or on-chain metadata storage.
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    // --- 2. Evolution and Staking Functions ---

    /**
     * @dev Stakes an NFT to start accumulating Evolution Points.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public whenNotPaused validTokenId(_tokenId) onlyOwnerOfNFT(_tokenId) {
        require(nftStakeStartTime[_tokenId] == 0, "NFT already staked."); // Prevent double staking
        nftStakeStartTime[_tokenId] = block.timestamp;
        nftData[_tokenId].lastStakeTime = block.timestamp; // Update last stake time on staking
        emit NFTStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an NFT, claiming accumulated Evolution Points.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public whenNotPaused validTokenId(_tokenId) onlyOwnerOfNFT(_tokenId) {
        require(nftStakeStartTime[_tokenId] != 0, "NFT not staked.");
        uint256 earnedEP = _calculateEvolutionPoints(_tokenId);
        nftData[_tokenId].evolutionPoints += earnedEP;
        nftStakeStartTime[_tokenId] = 0; // Reset stake time
        nftData[_tokenId].lastStakeTime = block.timestamp; // Update last stake time on unstaking

        emit NFTUnstaked(_tokenId, _tokenId, msg.sender, earnedEP);
    }

    /**
     * @dev Manually claims accumulated Evolution Points for a staked NFT without unstaking.
     * @param _tokenId The ID of the NFT to claim EP for.
     */
    function claimEvolutionPoints(uint256 _tokenId) public whenNotPaused validTokenId(_tokenId) onlyOwnerOfNFT(_tokenId) {
        require(nftStakeStartTime[_tokenId] != 0, "NFT not staked.");
        uint256 earnedEP = _calculateEvolutionPoints(_tokenId);
        nftData[_tokenId].evolutionPoints += earnedEP;
        nftData[_tokenId].lastStakeTime = block.timestamp; // Update last stake time on claiming
        nftStakeStartTime[_tokenId] = block.timestamp; // Keep staking active, reset start time for continuous earning

        emit EvolutionPointsClaimed(_tokenId, msg.sender, earnedEP);
    }

    /**
     * @dev Evolves an NFT to the next stage, consuming Evolution Points.
     * @param _tokenId The ID of the NFT to evolve.
     * @param _evolutionPath The ID of the chosen evolution path for the current stage.
     */
    function evolveNFT(uint256 _tokenId, uint8 _evolutionPath) public whenNotPaused validTokenId(_tokenId) onlyOwnerOfNFT(_tokenId) {
        NFTStage currentStage = nftData[_tokenId].stage;
        require(currentStage != NFTStage.STAGE_MAX, "NFT already at max stage.");

        EvolutionPath memory path = evolutionPaths[currentStage][_evolutionPath]; // Get the evolution path
        require(path.stage != NFTStage.BASE, "Invalid evolution path for current stage."); // Ensure path is defined for current stage

        require(nftData[_tokenId].evolutionPoints >= path.evolutionPointCost, "Not enough Evolution Points.");

        nftData[_tokenId].evolutionPoints -= path.evolutionPointCost;
        nftData[_tokenId].stage = path.stage; // Evolve to the next stage

        // Apply attribute changes from the evolution path
        for (uint256 i = 0; i < path.attributeChanges.length; i++) {
            AttributeChange memory change = path.attributeChanges[i];
            nftData[_tokenId].attributes[change.attributeName] += change.changeValue;
        }

        emit NFTEvolved(_tokenId, currentStage, path.stage, _evolutionPath);
    }

    /**
     * @dev Gets the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The NFTStage enum representing the current stage.
     */
    function getNFTStage(uint256 _tokenId) public view validTokenId(_tokenId) returns (NFTStage) {
        return nftData[_tokenId].stage;
    }

    /**
     * @dev Gets the current attributes of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return A mapping of attribute names to their values.
     */
    function getNFTAttributes(uint256 _tokenId) public view validTokenId(_tokenId) returns (mapping(string => uint256) memory) {
        return nftData[_tokenId].attributes;
    }

    /**
     * @dev Gets the accumulated Evolution Points for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The number of Evolution Points.
     */
    function getNFTEvolutionPoints(uint256 _tokenId) public view validTokenId(_tokenId) returns (uint256) {
        return nftData[_tokenId].evolutionPoints;
    }

    // --- 3. Decentralized Governance Functions ---

    /**
     * @dev Proposes a new evolution path for a specific stage. Governance function.
     * @param _proposalDescription Description of the proposal.
     * @param _stage The target evolution stage.
     * @param _pathId Unique ID for the evolution path within the stage.
     * @param _attributeChanges Array of attribute changes for this path.
     */
    function proposeEvolutionPath(
        string memory _proposalDescription,
        uint8 _stage,
        uint8 _pathId,
        AttributeChange[] memory _attributeChanges
    ) public whenNotPaused {
        require(_stage > uint8(NFTStage.BASE) && _stage <= uint8(NFTStage.STAGE_MAX), "Invalid evolution stage for proposal.");
        require(_pathId > 0, "Path ID must be greater than 0.");

        governanceProposals[nextProposalId] = GovernanceProposal({
            proposalId: nextProposalId,
            description: _proposalDescription,
            stage: _stage,
            pathId: _pathId,
            attributeChanges: _attributeChanges,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            executionTimestamp: 0
        });

        emit EvolutionPathProposed(nextProposalId, _proposalDescription, _stage, _pathId);
        nextProposalId++;
    }

    /**
     * @dev Allows NFT holders to vote on a governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for 'For' vote, false for 'Against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(governanceProposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");
        require(balanceOfNFT(msg.sender) > 0, "Must own NFTs to vote."); // Simple NFT holder voting

        if (_vote) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes an approved evolution proposal. Admin/Governance executed based on voting.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyAdmin whenNotPaused { // Simple admin execution for demo
        require(governanceProposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");

        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        // Simple approval condition - more 'For' votes than 'Against' (can be more sophisticated in real use)
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved by governance.");

        NFTStage stage = NFTStage(proposal.stage); // Convert uint8 to NFTStage enum
        uint8 pathId = proposal.pathId;
        evolutionPaths[stage][pathId] = EvolutionPath({
            stage: stage,
            pathId: pathId,
            description: proposal.description,
            attributeChanges: proposal.attributeChanges,
            evolutionPointCost: 1000 // Example fixed EP cost for every proposed path (can be dynamic)
        });

        proposal.executed = true;
        proposal.executionTimestamp = block.timestamp;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return GovernanceProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }


    // --- 4. Synergy and Rarity Functions ---

    /**
     * @dev Attempts to perform synergy between two NFTs. Unlocks traits based on NFT combination.
     * @param _tokenId1 ID of the first NFT.
     * @param _tokenId2 ID of the second NFT.
     */
    function performSynergy(uint256 _tokenId1, uint256 _tokenId2) public whenNotPaused validTokenId(_tokenId1) validTokenId(_tokenId2) onlyOwnerOfNFT(_tokenId1) {
        require(ownerOf[_tokenId2] == msg.sender, "Second NFT not owned by caller.");
        require(_tokenId1 != _tokenId2, "Cannot perform synergy with the same NFT.");

        NFTData storage nft1Data = nftData[_tokenId1];
        NFTData storage nft2Data = nftData[_tokenId2];

        // Example Synergy Condition: Both NFTs are at least Stage 2
        if (nft1Data.stage >= NFTStage.STAGE_2 && nft2Data.stage >= NFTStage.STAGE_2) {
            // Example Synergy Trait Unlock: Unlock a trait based on combined attributes (e.g., average of an attribute)
            uint256 combinedAttribute = (nft1Data.attributes["power"] + nft2Data.attributes["power"]) / 2;
            if (combinedAttribute > 150) {
                nft1Data.traits.push("Synergistic Power Boost");
                nft2Data.traits.push("Synergistic Power Boost");
            }
            if (nft1Data.attributes["speed"] > 100 && nft2Data.attributes["speed"] > 100) {
                nft1Data.traits.push("Agile Synergy");
                nft2Data.traits.push("Agile Synergy");
            }
            // Add more synergy conditions and trait unlocks as needed.
        } else {
            revert("NFTs not eligible for synergy at current stage.");
        }
    }

    /**
     * @dev Calculates a dynamic rarity score for an NFT based on its evolution history and attributes.
     * @param _tokenId The ID of the NFT.
     * @return The calculated rarity score.
     */
    function calculateRarityScore(uint256 _tokenId) public view validTokenId(_tokenId) returns (uint256) {
        NFTData memory data = nftData[_tokenId];
        uint256 rarityScore = uint256(data.stage) * 100; // Base score from stage
        rarityScore += data.attributes["power"] * 2; // Attribute weightings
        rarityScore += data.attributes["speed"] * 1;
        rarityScore += data.traits.length * 50; // Trait bonus

        return rarityScore;
    }

    /**
     * @dev Returns the unlocked traits of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return Array of trait strings.
     */
    function getNFTTraits(uint256 _tokenId) public view validTokenId(_tokenId) returns (string[] memory) {
        return nftData[_tokenId].traits;
    }


    // --- 5. Marketplace (Basic) Functions ---

    /**
     * @dev Lists an NFT for sale in the contract's marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in wei for the NFT.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused validTokenId(_tokenId) onlyOwnerOfNFT(_tokenId) {
        require(nftListings[_tokenId].active == false, "NFT already listed.");
        require(_price > 0, "Price must be greater than zero.");
        nftApprovals[_tokenId] = address(this); // Approve contract to handle transfer on sale

        nftListings[_tokenId] = NFTListing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            active: true
        });
        emit NFTListedForSale(_tokenId, msg.sender, _price);
    }

    /**
     * @dev Allows purchasing a listed NFT.
     * @param _tokenId The ID of the NFT to purchase.
     */
    function purchaseNFT(uint256 _tokenId) public payable whenNotPaused validTokenId(_tokenId) {
        require(nftListings[_tokenId].active == true, "NFT not listed for sale.");
        NFTListing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to purchase.");

        address seller = listing.seller;
        uint256 price = listing.price;

        listing.active = false; // Deactivate listing
        delete nftApprovals[_tokenId]; // Remove marketplace approval after sale

        _transfer(seller, msg.sender, _tokenId);

        (bool success, ) = payable(seller).call{value: price}(""); // Send funds to seller
        require(success, "Transfer to seller failed.");

        emit NFTPurchased(_tokenId, msg.sender, seller, price);
    }

    /**
     * @dev Cancels an NFT listing.
     * @param _tokenId The ID of the NFT to cancel the listing for.
     */
    function cancelListing(uint256 _tokenId) public whenNotPaused validTokenId(_tokenId) onlyOwnerOfNFT(_tokenId) {
        require(nftListings[_tokenId].active == true, "NFT not listed.");
        require(nftListings[_tokenId].seller == msg.sender, "Only seller can cancel listing.");

        nftListings[_tokenId].active = false;
        delete nftApprovals[_tokenId]; // Remove marketplace approval after cancelling

        emit ListingCancelled(_tokenId);
    }

    /**
     * @dev Retrieves details of a specific NFT listing.
     * @param _tokenId The ID of the NFT.
     * @return NFTListing struct containing listing details.
     */
    function getListingDetails(uint256 _tokenId) public view validTokenId(_tokenId) returns (NFTListing memory) {
        return nftListings[_tokenId];
    }


    // --- 6. Admin/Utility Functions ---

    /**
     * @dev Admin function to set the rate of Evolution Point accumulation.
     * @param _newRate The new EP rate (EP per time unit).
     */
    function setEvolutionPointRate(uint256 _newRate) public onlyAdmin whenNotPaused {
        evolutionPointRate = _newRate;
        emit EvolutionPointRateUpdated(_newRate);
    }

    /**
     * @dev Admin function to withdraw the contract's ETH balance.
     */
    function withdrawContractBalance() public onlyAdmin whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero.");
        (bool success, ) = payable(admin).call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @dev Admin function to pause core contract functionalities.
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /**
     * @dev Admin function to unpause contract functionalities.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }


    // --- Internal Functions ---

    /**
     * @dev Internal function to perform NFT transfer logic.
     * @param _from The address sending the NFT.
     * @param _to The address receiving the NFT.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        balanceOf[_from]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
        delete nftApprovals[_tokenId]; // Clear approvals on transfer
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /**
     * @dev Internal function to calculate Evolution Points earned since last stake time.
     * @param _tokenId The ID of the NFT.
     * @return The number of Evolution Points earned.
     */
    function _calculateEvolutionPoints(uint256 _tokenId) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - nftData[_tokenId].lastStakeTime;
        return timeElapsed * evolutionPointRate; // Simple time-based EP accumulation
    }

    /**
     * @dev Internal function to initialize base attributes for a newly minted NFT.
     * @return Initial attribute mapping.
     */
    function initializeBaseAttributes() internal pure returns (mapping(string => uint256)) {
        mapping(string => uint256) memory baseAttributes;
        baseAttributes["power"] = 50;
        baseAttributes["speed"] = 60;
        baseAttributes["defense"] = 40;
        // Add more base attributes as needed
        return baseAttributes;
    }
}

// --- Utility Library for String Conversions (Optional, but helpful for tokenURI) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.5.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```