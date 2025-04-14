```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev A smart contract for a decentralized art collective enabling collaborative art creation,
 *      governance, exhibitions, and community engagement. This contract explores advanced concepts
 *      like proposal-based workflows, decentralized governance, dynamic royalties, and on-chain reputation.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Collective Functions:**
 *    - `joinCollective()`: Allows artists to request membership to the collective.
 *    - `approveArtistMembership(address _artist)`: Platform owner approves artist membership requests.
 *    - `removeArtistMembership(address _artist)`: Platform owner or governance can remove an artist.
 *    - `getCollectiveMembers()`: Returns a list of current collective member addresses.
 *
 * **2. Artwork Proposal & Creation:**
 *    - `createArtworkProposal(string memory _title, string memory _description, string memory _ipfsHash, address[] memory _collaborators, uint256 _royaltyPercentage)`:
 *      Collective members propose new artwork creation with details, collaborators, and royalty split.
 *    - `voteOnArtworkProposal(uint256 _proposalId, bool _approve)`: Collective members vote on artwork proposals.
 *    - `finalizeArtworkProposal(uint256 _proposalId)`:  Finalizes an approved artwork proposal and mints the artwork NFT.
 *    - `getArtworkProposalDetails(uint256 _proposalId)`: Retrieves details of a specific artwork proposal.
 *    - `getArtworkIds()`: Returns a list of IDs of minted artworks.
 *    - `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a specific artwork.
 *
 * **3. Governance & Proposals:**
 *    - `createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata, address _targetContract)`:
 *      Collective members propose governance actions (contract upgrades, parameter changes, etc.).
 *    - `voteOnGovernanceProposal(uint256 _proposalId, bool _approve)`: Collective members vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: Executes an approved governance proposal (if quorum reached).
 *    - `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
 *    - `getGovernanceProposalIds()`: Returns a list of IDs of active governance proposals.
 *
 * **4. Exhibition & Events:**
 *    - `createExhibitionProposal(string memory _title, string memory _description, uint256 _startTime, uint256 _endTime, uint256[] memory _artworkIds)`:
 *      Collective members propose art exhibitions with details and featured artworks.
 *    - `voteOnExhibitionProposal(uint256 _proposalId, bool _approve)`: Collective members vote on exhibition proposals.
 *    - `finalizeExhibitionProposal(uint256 _proposalId)`: Finalizes an approved exhibition proposal.
 *    - `getExhibitionProposalDetails(uint256 _proposalId)`: Retrieves details of a specific exhibition proposal.
 *    - `getExhibitionProposalIds()`: Returns a list of IDs of active exhibition proposals.
 *    - `attendExhibition(uint256 _exhibitionId)`: Allows users to register attendance for an exhibition (potentially for rewards or reputation).
 *
 * **5. Marketplace & Royalties:**
 *    - `listArtworkForSale(uint256 _artworkId, uint256 _price)`: Allows artwork owners to list their artworks for sale in the collective's marketplace.
 *    - `buyArtwork(uint256 _artworkId)`: Allows users to purchase artworks listed in the marketplace, automatically distributing royalties.
 *    - `unlistArtworkForSale(uint256 _artworkId)`: Removes an artwork listing from the marketplace.
 *    - `getArtworkSalePrice(uint256 _artworkId)`: Retrieves the sale price of a listed artwork.
 *
 * **6. Reputation & Community (Conceptual - Can be expanded):**
 *    - `contributeToCommunity(string memory _activityType, string memory _details)`: (Placeholder) Allows members to log community contributions (e.g., event organization, support).
 *    - `getArtistReputation(address _artist)`: (Conceptual) Could retrieve a reputation score based on contributions and participation.
 *
 * **7. Utility & Platform Management:**
 *    - `setPlatformFee(uint256 _feePercentage)`: Platform owner sets the platform fee percentage on sales.
 *    - `getPlatformFee()`: Returns the current platform fee percentage.
 *    - `withdrawPlatformFees()`: Platform owner withdraws accumulated platform fees.
 *    - `setVotingQuorum(uint256 _quorumPercentage)`: Platform owner or governance sets the voting quorum for proposals.
 *    - `getVotingQuorum()`: Returns the current voting quorum percentage.
 */
contract DecentralizedAutonomousArtCollective {

    // --- State Variables ---

    address public platformOwner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public votingQuorumPercentage = 50; // Default 50% quorum

    uint256 public artworkProposalCounter = 0;
    uint256 public governanceProposalCounter = 0;
    uint256 public exhibitionProposalCounter = 0;
    uint256 public artworkCounter = 0;

    mapping(address => bool) public isCollectiveMember; // Track collective members
    address[] public collectiveMembers;

    struct Artist {
        address artistAddress;
        uint256 reputationScore; // Conceptual reputation score
        bool isActiveMember;
        uint256 joinTimestamp;
    }
    mapping(address => Artist) public artistDetails;

    struct ArtworkProposal {
        uint256 proposalId;
        string title;
        string description;
        string ipfsHash; // IPFS hash for artwork data
        address proposer;
        address[] collaborators;
        uint256 royaltyPercentage;
        uint256 voteCount;
        uint256 againstVoteCount;
        bool isActive;
        bool isApproved;
        mapping(address => bool) votes; // Track votes per member
    }
    mapping(uint256 => ArtworkProposal) public artworkProposals;
    uint256[] public artworkProposalIds;

    struct Artwork {
        uint256 artworkId;
        string title;
        string description;
        string ipfsHash;
        address[] creators; // Collective members who created it
        uint256 royaltyPercentage;
        address owner;
        uint256 mintTimestamp;
    }
    mapping(uint256 => Artwork) public artworks;
    uint256[] public artworkIds;

    struct GovernanceProposal {
        uint256 proposalId;
        string title;
        string description;
        bytes calldataData; // Calldata for contract function
        address targetContract; // Contract to call
        address proposer;
        uint256 voteCount;
        uint256 againstVoteCount;
        bool isActive;
        bool isApproved;
        mapping(address => bool) votes;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256[] public governanceProposalIds;


    struct ExhibitionProposal {
        uint256 proposalId;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        address proposer;
        uint256[] artworkIds;
        uint256 voteCount;
        uint256 againstVoteCount;
        bool isActive;
        bool isApproved;
        mapping(address => bool) votes;
    }
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    uint256[] public exhibitionProposalIds;

    mapping(uint256 => uint256) public artworkForSalePrice; // Artwork ID => Price (in wei)

    // --- Events ---
    event ArtistJoinedCollective(address artistAddress);
    event ArtistMembershipApproved(address artistAddress, address approvedBy);
    event ArtistMembershipRemoved(address artistAddress, address removedBy);

    event ArtworkProposalCreated(uint256 proposalId, string title, address proposer);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool approved);
    event ArtworkProposalFinalized(uint256 proposalId, uint256 artworkId);
    event ArtworkMinted(uint256 artworkId, string title, address owner);

    event GovernanceProposalCreated(uint256 proposalId, string title, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool approved);
    event GovernanceProposalExecuted(uint256 proposalId);

    event ExhibitionProposalCreated(uint256 proposalId, string title, address proposer);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool approved);
    event ExhibitionProposalFinalized(uint256 proposalId, uint256 exhibitionId);
    event ExhibitionAttendanceRecorded(uint256 exhibitionId, address attendee);

    event ArtworkListedForSale(uint256 artworkId, uint256 price, address seller);
    event ArtworkSold(uint256 artworkId, address buyer, uint256 price);
    event ArtworkUnlistedFromSale(uint256 artworkId, address seller);

    event PlatformFeeSet(uint256 feePercentage, address setBy);
    event PlatformFeesWithdrawn(uint256 amount, address withdrawnBy);
    event VotingQuorumSet(uint256 quorumPercentage, address setBy);


    // --- Modifiers ---
    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier onlyCollectiveMember() {
        require(isCollectiveMember[msg.sender], "Only collective members can call this function.");
        _;
    }

    modifier validArtworkProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= artworkProposalCounter, "Invalid artwork proposal ID.");
        require(artworkProposals[_proposalId].isActive, "Artwork proposal is not active.");
        _;
    }

    modifier validGovernanceProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= governanceProposalCounter, "Invalid governance proposal ID.");
        require(governanceProposals[_proposalId].isActive, "Governance proposal is not active.");
        _;
    }

    modifier validExhibitionProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= exhibitionProposalCounter, "Invalid exhibition proposal ID.");
        require(exhibitionProposals[_proposalId].isActive, "Exhibition proposal is not active.");
        _;
    }

    modifier validArtwork(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkCounter, "Invalid artwork ID.");
        _;
    }

    modifier artworkOwner(uint256 _artworkId) {
        require(artworks[_artworkId].owner == msg.sender, "You are not the owner of this artwork.");
        _;
    }


    // --- Constructor ---
    constructor() {
        platformOwner = msg.sender;
    }


    // --- 1. Core Collective Functions ---

    function joinCollective() public {
        require(!isCollectiveMember[msg.sender], "Already a member or membership requested.");
        artistDetails[msg.sender] = Artist({
            artistAddress: msg.sender,
            reputationScore: 0, // Initial reputation
            isActiveMember: false, // Initially not active, needs approval
            joinTimestamp: block.timestamp
        });
        emit ArtistJoinedCollective(msg.sender);
    }

    function approveArtistMembership(address _artist) public onlyPlatformOwner {
        require(!isCollectiveMember[_artist], "Artist is already a member.");
        require(artistDetails[_artist].artistAddress != address(0), "Artist has not requested membership.");
        isCollectiveMember[_artist] = true;
        collectiveMembers.push(_artist);
        artistDetails[_artist].isActiveMember = true;
        emit ArtistMembershipApproved(_artist, msg.sender);
    }

    function removeArtistMembership(address _artist) public onlyPlatformOwner {
        require(isCollectiveMember[_artist], "Artist is not a member.");
        isCollectiveMember[_artist] = false;
        artistDetails[_artist].isActiveMember = false;

        // Remove from collectiveMembers array (inefficient for large arrays, consider optimization if needed)
        for (uint256 i = 0; i < collectiveMembers.length; i++) {
            if (collectiveMembers[i] == _artist) {
                collectiveMembers[i] = collectiveMembers[collectiveMembers.length - 1];
                collectiveMembers.pop();
                break;
            }
        }
        emit ArtistMembershipRemoved(_artist, msg.sender);
    }

    function getCollectiveMembers() public view returns (address[] memory) {
        return collectiveMembers;
    }


    // --- 2. Artwork Proposal & Creation ---

    function createArtworkProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        address[] memory _collaborators,
        uint256 _royaltyPercentage
    ) public onlyCollectiveMember {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        require(_collaborators.length <= 10, "Maximum 10 collaborators allowed."); // Limit collaborators for simplicity

        artworkProposalCounter++;
        ArtworkProposal storage proposal = artworkProposals[artworkProposalCounter];
        proposal.proposalId = artworkProposalCounter;
        proposal.title = _title;
        proposal.description = _description;
        proposal.ipfsHash = _ipfsHash;
        proposal.proposer = msg.sender;
        proposal.collaborators = _collaborators;
        proposal.royaltyPercentage = _royaltyPercentage;
        proposal.isActive = true;
        artworkProposalIds.push(artworkProposalCounter);

        emit ArtworkProposalCreated(artworkProposalCounter, _title, msg.sender);
    }

    function voteOnArtworkProposal(uint256 _proposalId, bool _approve) public onlyCollectiveMember validArtworkProposal(_proposalId) {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(!proposal.votes[msg.sender], "Already voted on this proposal.");

        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.voteCount++;
        } else {
            proposal.againstVoteCount++;
        }
        emit ArtworkProposalVoted(_proposalId, msg.sender, _approve);
    }

    function finalizeArtworkProposal(uint256 _proposalId) public validArtworkProposal(_proposalId) {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(!proposal.isApproved, "Artwork proposal already finalized.");

        uint256 quorum = (collectiveMembers.length * votingQuorumPercentage) / 100;
        require(proposal.voteCount >= quorum, "Quorum not reached for approval.");

        proposal.isApproved = true;
        proposal.isActive = false;
        emit ArtworkProposalFinalized(_proposalId, artworkCounter + 1);

        _mintArtworkFromProposal(proposal);
    }

    function _mintArtworkFromProposal(ArtworkProposal storage _proposal) private {
        artworkCounter++;
        Artwork storage artwork = artworks[artworkCounter];
        artwork.artworkId = artworkCounter;
        artwork.title = _proposal.title;
        artwork.description = _proposal.description;
        artwork.ipfsHash = _proposal.ipfsHash;
        artwork.creators = _proposal.collaborators;
        artwork.creators.push(_proposal.proposer); // Add proposer to creators
        artwork.royaltyPercentage = _proposal.royaltyPercentage;
        artwork.owner = address(this); // Initially owned by the contract (collective)
        artwork.mintTimestamp = block.timestamp;
        artworkIds.push(artworkCounter);

        emit ArtworkMinted(artworkCounter, _proposal.title, address(this));
    }

    function getArtworkProposalDetails(uint256 _proposalId) public view validArtworkProposal(_proposalId) returns (ArtworkProposal memory) {
        return artworkProposals[_proposalId];
    }

    function getArtworkIds() public view returns (uint256[] memory) {
        return artworkIds;
    }

    function getArtworkDetails(uint256 _artworkId) public view validArtwork(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }


    // --- 3. Governance & Proposals ---

    function createGovernanceProposal(
        string memory _title,
        string memory _description,
        bytes memory _calldata,
        address _targetContract
    ) public onlyCollectiveMember {
        governanceProposalCounter++;
        GovernanceProposal storage proposal = governanceProposals[governanceProposalCounter];
        proposal.proposalId = governanceProposalCounter;
        proposal.title = _title;
        proposal.description = _description;
        proposal.calldataData = _calldata;
        proposal.targetContract = _targetContract;
        proposal.proposer = msg.sender;
        proposal.isActive = true;
        governanceProposalIds.push(governanceProposalCounter);

        emit GovernanceProposalCreated(governanceProposalCounter, _title, msg.sender);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _approve) public onlyCollectiveMember validGovernanceProposal(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.votes[msg.sender], "Already voted on this proposal.");

        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.voteCount++;
        } else {
            proposal.againstVoteCount++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _approve);
    }

    function executeGovernanceProposal(uint256 _proposalId) public validGovernanceProposal(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.isApproved == false, "Governance proposal already executed or finalized."); // Ensure it's not already executed

        uint256 quorum = (collectiveMembers.length * votingQuorumPercentage) / 100;
        require(proposal.voteCount >= quorum, "Quorum not reached for execution.");

        proposal.isApproved = true; // Mark as executed
        proposal.isActive = false;
        emit GovernanceProposalExecuted(_proposalId);

        // Execute the proposal - BE CAREFUL, POTENTIAL SECURITY RISK if not properly validated
        (bool success, ) = proposal.targetContract.call(proposal.calldataData);
        require(success, "Governance proposal execution failed.");
    }

    function getGovernanceProposalDetails(uint256 _proposalId) public view validGovernanceProposal(_proposalId) returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    function getGovernanceProposalIds() public view returns (uint256[] memory) {
        return governanceProposalIds;
    }


    // --- 4. Exhibition & Events ---

    function createExhibitionProposal(
        string memory _title,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime,
        uint256[] memory _artworkIds
    ) public onlyCollectiveMember {
        require(_startTime < _endTime, "Exhibition start time must be before end time.");
        require(_artworkIds.length > 0 && _artworkIds.length <= 20, "Exhibition must include 1-20 artworks."); // Limit artwork count

        exhibitionProposalCounter++;
        ExhibitionProposal storage proposal = exhibitionProposals[exhibitionProposalCounter];
        proposal.proposalId = exhibitionProposalCounter;
        proposal.title = _title;
        proposal.description = _description;
        proposal.startTime = _startTime;
        proposal.endTime = _endTime;
        proposal.artworkIds = _artworkIds;
        proposal.proposer = msg.sender;
        proposal.isActive = true;
        exhibitionProposalIds.push(exhibitionProposalCounter);

        emit ExhibitionProposalCreated(exhibitionProposalCounter, _title, msg.sender);
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _approve) public onlyCollectiveMember validExhibitionProposal(_proposalId) {
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        require(!proposal.votes[msg.sender], "Already voted on this proposal.");

        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.voteCount++;
        } else {
            proposal.againstVoteCount++;
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _approve);
    }

    function finalizeExhibitionProposal(uint256 _proposalId) public validExhibitionProposal(_proposalId) {
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        require(!proposal.isApproved, "Exhibition proposal already finalized.");

        uint256 quorum = (collectiveMembers.length * votingQuorumPercentage) / 100;
        require(proposal.voteCount >= quorum, "Quorum not reached for approval.");

        proposal.isApproved = true;
        proposal.isActive = false;
        emit ExhibitionProposalFinalized(_proposalId, _proposalId); // Using proposalId as exhibitionId for simplicity.

        // Future: Can add logic to set exhibition details, virtual space, etc.
    }

    function getExhibitionProposalDetails(uint256 _proposalId) public view validExhibitionProposal(_proposalId) returns (ExhibitionProposal memory) {
        return exhibitionProposals[_proposalId];
    }

    function getExhibitionProposalIds() public view returns (uint256[] memory) {
        return exhibitionProposalIds;
    }

    function attendExhibition(uint256 _exhibitionId) public {
        // Placeholder for exhibition attendance tracking.
        // Could be expanded to issue attendance tokens or update reputation.
        emit ExhibitionAttendanceRecorded(_exhibitionId, msg.sender);
        // Future: Implement logic to reward attendees, provide access, etc.
    }


    // --- 5. Marketplace & Royalties ---

    function listArtworkForSale(uint256 _artworkId, uint256 _price) public validArtwork(_artworkId) artworkOwner(_artworkId) {
        require(_price > 0, "Price must be greater than zero.");
        artworkForSalePrice[_artworkId] = _price;
        emit ArtworkListedForSale(_artworkId, _price, msg.sender);
    }

    function buyArtwork(uint256 _artworkId) public payable validArtwork(_artworkId) {
        require(artworkForSalePrice[_artworkId] > 0, "Artwork is not listed for sale.");
        uint256 price = artworkForSalePrice[_artworkId];
        require(msg.value >= price, "Insufficient funds sent.");

        address seller = artworks[_artworkId].owner;
        require(seller != address(this), "Collective owned artworks cannot be bought directly. (Transfer from collective needed first)"); // Example restriction

        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 artistRoyalty = (price * artworks[_artworkId].royaltyPercentage) / 100;
        uint256 sellerProceeds = price - platformFee - artistRoyalty;

        // Transfer funds
        payable(platformOwner).transfer(platformFee);
        _distributeRoyalties(_artworkId, artistRoyalty);
        payable(seller).transfer(sellerProceeds);

        // Update artwork ownership
        artworks[_artworkId].owner = msg.sender;
        delete artworkForSalePrice[_artworkId]; // Remove from sale
        emit ArtworkSold(_artworkId, msg.sender, price);
    }

    function _distributeRoyalties(uint256 _artworkId, uint256 _royaltyAmount) private {
        address[] memory creators = artworks[_artworkId].creators;
        uint256 creatorsCount = creators.length;
        if (creatorsCount > 0) {
            uint256 royaltyPerCreator = _royaltyAmount / creatorsCount;
            uint256 remainder = _royaltyAmount % creatorsCount; // Handle remainder

            for (uint256 i = 0; i < creatorsCount; i++) {
                uint256 amountToTransfer = royaltyPerCreator;
                if (i == 0) { // Give remainder to the first creator (can adjust logic)
                    amountToTransfer += remainder;
                }
                payable(creators[i]).transfer(amountToTransfer);
            }
        }
        // If no creators, royalties are lost to the ether (or handle differently)
    }


    function unlistArtworkForSale(uint256 _artworkId) public validArtwork(_artworkId) artworkOwner(_artworkId) {
        require(artworkForSalePrice[_artworkId] > 0, "Artwork is not listed for sale.");
        delete artworkForSalePrice[_artworkId];
        emit ArtworkUnlistedFromSale(_artworkId, msg.sender);
    }

    function getArtworkSalePrice(uint256 _artworkId) public view validArtwork(_artworkId) returns (uint256) {
        return artworkForSalePrice[_artworkId];
    }


    // --- 6. Reputation & Community (Conceptual) ---

    function contributeToCommunity(string memory _activityType, string memory _details) public onlyCollectiveMember {
        // Conceptual function - can be expanded to track community contributions
        // and update reputation scores.
        // Examples: _activityType = "Event Organization", _details = "Organized a virtual exhibition opening event"
        // Could store contributions, implement voting on contributions, etc.
        // For now, just a placeholder.
    }

    function getArtistReputation(address _artist) public view returns (uint256) {
        // Conceptual function - returns the reputation score of an artist.
        // Reputation system needs to be designed and implemented.
        return artistDetails[_artist].reputationScore; // Returns current score (initially 0)
    }


    // --- 7. Utility & Platform Management ---

    function setPlatformFee(uint256 _feePercentage) public onlyPlatformOwner {
        require(_feePercentage <= 20, "Platform fee percentage cannot exceed 20%."); // Example limit
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage, msg.sender);
    }

    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    function withdrawPlatformFees() public onlyPlatformOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance; // For clarity, assuming all balance is platform fees.
        require(contractBalance > 0, "No platform fees to withdraw.");

        payable(platformOwner).transfer(contractBalance);
        emit PlatformFeesWithdrawn(contractBalance, msg.sender);
    }

    function setVotingQuorum(uint256 _quorumPercentage) public onlyPlatformOwner {
        require(_quorumPercentage >= 10 && _quorumPercentage <= 90, "Voting quorum must be between 10% and 90%."); // Example range
        votingQuorumPercentage = _quorumPercentage;
        emit VotingQuorumSet(_quorumPercentage, msg.sender);
    }

    function getVotingQuorum() public view returns (uint256) {
        return votingQuorumPercentage;
    }

    // --- Fallback & Receive (Optional - for accepting ETH) ---
    receive() external payable {}
    fallback() external payable {}
}
```