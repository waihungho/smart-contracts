```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to submit art,
 * curators to manage exhibitions, community voting on art and proposals, and decentralized revenue sharing.
 *
 * Outline:
 * 1. Art Submission and Curation:
 *    - submitArt: Artists submit their artwork with metadata and price.
 *    - approveArt: Curators approve submitted artwork.
 *    - rejectArt: Curators reject submitted artwork.
 *    - setCurator: Admin function to add or remove curators.
 *    - isApprovedArt: Check if an artwork is approved.
 *
 * 2. Exhibition Management:
 *    - createExhibition: Curators create new exhibitions with a name and timeframe.
 *    - addArtToExhibition: Curators add approved artworks to an exhibition.
 *    - removeArtFromExhibition: Curators remove artworks from an exhibition.
 *    - startExhibition: Curators start an exhibition, making it active.
 *    - endExhibition: Curators end an exhibition, closing it for further additions.
 *    - getExhibitionDetails: View exhibition details by ID.
 *    - getActiveExhibitions: Get a list of IDs of active exhibitions.
 *
 * 3. Community Governance and Proposals:
 *    - proposeParameterChange: Members propose changes to contract parameters (e.g., commission rate).
 *    - voteOnProposal: Members vote for or against a proposal.
 *    - executeProposal: Admin/Timelock function to execute a passed proposal after voting period.
 *    - getProposalDetails: View details of a proposal by ID.
 *
 * 4. Decentralized Revenue and Artist Payouts:
 *    - purchaseArt: Users purchase artwork directly from the contract.
 *    - setPlatformCommissionRate: Admin sets the platform commission rate on sales.
 *    - withdrawArtistEarnings: Artists withdraw their earnings from sold artwork.
 *    - withdrawPlatformEarnings: Admin withdraws platform commission earnings.
 *    - getArtistEarnings: View an artist's pending earnings.
 *
 * 5. Utility and Access Control:
 *    - isAdmin: Check if an address is an admin.
 *    - isCurator: Check if an address is a curator.
 *    - getArtDetails: View artwork details by ID.
 *    - getApprovedArtCount: Get the total count of approved artworks.
 */
contract DecentralizedArtCollective {

    // -------- Structs --------

    struct Art {
        address artist;
        string title;
        string ipfsHash; // IPFS hash for artwork metadata
        uint256 price;   // Price in wei
        bool approved;
        uint256 submissionTimestamp;
    }

    struct Exhibition {
        string name;
        address curator;
        uint256 startTime;
        uint256 endTime;
        uint256[] artIds;
        bool isActive;
    }

    struct Proposal {
        address proposer;
        string description;
        string parameterToChange; // Example: "platformCommissionRate"
        uint256 newValue;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    // -------- State Variables --------

    address public admin;
    mapping(address => bool) public curators;
    mapping(uint256 => Art) public artworks;
    uint256 public artCount;
    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public exhibitionCount;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public platformCommissionRate = 10; // Percentage, e.g., 10%
    mapping(address => uint256) public artistEarnings;
    uint256 public platformEarnings;
    uint256 public proposalVotingPeriod = 7 days; // Default voting period

    // -------- Events --------

    event ArtSubmitted(uint256 artId, address artist, string title);
    event ArtApproved(uint256 artId, address curator);
    event ArtRejected(uint256 artId, address curator);
    event CuratorSet(address curatorAddress, bool isCurator);
    event ExhibitionCreated(uint256 exhibitionId, string name, address curator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event ArtPurchased(uint256 artId, address buyer, address artist, uint256 price);
    event PlatformCommissionRateSet(uint256 newRate);
    event ArtistEarningsWithdrawn(address artist, uint256 amount);
    event PlatformEarningsWithdrawn(address admin, uint256 amount);
    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can call this function.");
        _;
    }

    modifier onlyApprovedArt(uint256 _artId) {
        require(artworks[_artId].approved, "Art must be approved.");
        _;
    }

    modifier exhibitionActive(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        _;
    }

    modifier proposalVotingActive(uint256 _proposalId) {
        require(block.timestamp <= proposals[_proposalId].votingEndTime && !proposals[_proposalId].executed, "Voting period ended or proposal executed.");
        _;
    }

    modifier proposalExecutable(uint256 _proposalId) {
        require(block.timestamp > proposals[_proposalId].votingEndTime && !proposals[_proposalId].executed, "Voting period not ended or already executed.");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not passed.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
    }

    // -------- 1. Art Submission and Curation --------

    /**
     * @dev Artists submit their artwork to the collective.
     * @param _title The title of the artwork.
     * @param _ipfsHash The IPFS hash of the artwork metadata.
     * @param _price The price of the artwork in wei.
     */
    function submitArt(string memory _title, string memory _ipfsHash, uint256 _price) public {
        require(bytes(_title).length > 0 && bytes(_ipfsHash).length > 0 && _price > 0, "Invalid art details.");
        artCount++;
        artworks[artCount] = Art({
            artist: msg.sender,
            title: _title,
            ipfsHash: _ipfsHash,
            price: _price,
            approved: false,
            submissionTimestamp: block.timestamp
        });
        emit ArtSubmitted(artCount, msg.sender, _title);
    }

    /**
     * @dev Curators approve submitted artwork.
     * @param _artId The ID of the artwork to approve.
     */
    function approveArt(uint256 _artId) public onlyCurator {
        require(!artworks[_artId].approved, "Art already approved.");
        require(artworks[_artId].artist != address(0), "Invalid art ID."); // Ensure art exists
        artworks[_artId].approved = true;
        emit ArtApproved(_artId, msg.sender);
    }

    /**
     * @dev Curators reject submitted artwork.
     * @param _artId The ID of the artwork to reject.
     */
    function rejectArt(uint256 _artId) public onlyCurator {
        require(!artworks[_artId].approved, "Art already approved or rejected."); // Can reject only once if not approved yet.
        require(artworks[_artId].artist != address(0), "Invalid art ID."); // Ensure art exists
        artworks[_artId].approved = false; // Still set to false, but event is different
        emit ArtRejected(_artId, msg.sender);
    }

    /**
     * @dev Admin function to set or unset curator status for an address.
     * @param _curatorAddress The address to set as curator.
     * @param _isCurator True to set as curator, false to remove curator status.
     */
    function setCurator(address _curatorAddress, bool _isCurator) public onlyAdmin {
        curators[_curatorAddress] = _isCurator;
        emit CuratorSet(_curatorAddress, _isCurator);
    }

    /**
     * @dev Check if an artwork is approved.
     * @param _artId The ID of the artwork.
     * @return bool True if approved, false otherwise.
     */
    function isApprovedArt(uint256 _artId) public view returns (bool) {
        return artworks[_artId].approved;
    }

    // -------- 2. Exhibition Management --------

    /**
     * @dev Curators create a new exhibition.
     * @param _name The name of the exhibition.
     * @param _startTime Timestamp for when the exhibition starts.
     * @param _endTime Timestamp for when the exhibition ends.
     */
    function createExhibition(string memory _name, uint256 _startTime, uint256 _endTime) public onlyCurator {
        require(bytes(_name).length > 0 && _startTime < _endTime && _startTime > block.timestamp, "Invalid exhibition details.");
        exhibitionCount++;
        exhibitions[exhibitionCount] = Exhibition({
            name: _name,
            curator: msg.sender,
            startTime: _startTime,
            endTime: _endTime,
            artIds: new uint256[](0),
            isActive: false
        });
        emit ExhibitionCreated(exhibitionCount, _name, msg.sender);
    }

    /**
     * @dev Curators add approved artwork to an exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @param _artId The ID of the artwork to add.
     */
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artId) public onlyCurator exhibitionActive(_exhibitionId) {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only exhibition curator can add art.");
        require(isApprovedArt(_artId), "Art is not approved.");
        require(exhibitions[_exhibitionId].startTime > block.timestamp, "Cannot add art to started exhibition."); // Only before start time

        // Check if art is already in the exhibition (optional, for uniqueness)
        bool alreadyInExhibition = false;
        for (uint256 i = 0; i < exhibitions[_exhibitionId].artIds.length; i++) {
            if (exhibitions[_exhibitionId].artIds[i] == _artId) {
                alreadyInExhibition = true;
                break;
            }
        }
        require(!alreadyInExhibition, "Art already in exhibition.");

        exhibitions[_exhibitionId].artIds.push(_artId);
        emit ArtAddedToExhibition(_exhibitionId, _artId);
    }

    /**
     * @dev Curators remove artwork from an exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @param _artId The ID of the artwork to remove.
     */
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId) public onlyCurator exhibitionActive(_exhibitionId) {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only exhibition curator can remove art.");
        require(exhibitions[_exhibitionId].startTime > block.timestamp, "Cannot remove art from started exhibition."); // Only before start time

        uint256[] storage artIds = exhibitions[_exhibitionId].artIds;
        bool found = false;
        for (uint256 i = 0; i < artIds.length; i++) {
            if (artIds[i] == _artId) {
                // Remove element by shifting elements after it to the left
                for (uint256 j = i; j < artIds.length - 1; j++) {
                    artIds[j] = artIds[j + 1];
                }
                artIds.pop();
                found = true;
                break;
            }
        }
        require(found, "Art not found in exhibition.");
        emit ArtRemovedFromExhibition(_exhibitionId, _artId);
    }

    /**
     * @dev Curators start an exhibition, making it active for sales and viewing.
     * @param _exhibitionId The ID of the exhibition to start.
     */
    function startExhibition(uint256 _exhibitionId) public onlyCurator {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only exhibition curator can start.");
        require(!exhibitions[_exhibitionId].isActive, "Exhibition already active.");
        require(exhibitions[_exhibitionId].startTime <= block.timestamp, "Exhibition start time not reached yet.");
        exhibitions[_exhibitionId].isActive = true;
        emit ExhibitionStarted(_exhibitionId);
    }

    /**
     * @dev Curators end an exhibition, closing it for further activity.
     * @param _exhibitionId The ID of the exhibition to end.
     */
    function endExhibition(uint256 _exhibitionId) public onlyCurator exhibitionActive(_exhibitionId) {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only exhibition curator can end.");
        require(exhibitions[_exhibitionId].isActive, "Exhibition not active.");
        require(exhibitions[_exhibitionId].endTime <= block.timestamp, "Exhibition end time not reached yet."); // Allow ending at or after end time
        exhibitions[_exhibitionId].isActive = false;
        emit ExhibitionEnded(_exhibitionId);
    }

    /**
     * @dev Get details of an exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @return Exhibition struct containing exhibition details.
     */
    function getExhibitionDetails(uint256 _exhibitionId) public view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /**
     * @dev Get a list of IDs of active exhibitions.
     * @return uint256[] Array of active exhibition IDs.
     */
    function getActiveExhibitions() public view returns (uint256[] memory) {
        uint256[] memory activeExhibitionIds = new uint256[](exhibitionCount); // Max size
        uint256 count = 0;
        for (uint256 i = 1; i <= exhibitionCount; i++) {
            if (exhibitions[i].isActive) {
                activeExhibitionIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of active exhibitions
        assembly {
            mstore(activeExhibitionIds, count) // Update array length
        }
        return activeExhibitionIds;
    }


    // -------- 3. Community Governance and Proposals --------

    /**
     * @dev Members propose changes to contract parameters.
     * @param _description Description of the proposal.
     * @param _parameterToChange Name of the parameter to change (e.g., "platformCommissionRate").
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(string memory _description, string memory _parameterToChange, uint256 _newValue) public {
        require(bytes(_description).length > 0 && bytes(_parameterToChange).length > 0, "Invalid proposal details.");
        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            description: _description,
            parameterToChange: _parameterToChange,
            newValue: _newValue,
            votingEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    /**
     * @dev Members vote on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for "For", False for "Against".
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) public proposalVotingActive(_proposalId) {
        require(proposals[_proposalId].proposer != address(0), "Invalid proposal ID."); // Proposal exists

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Admin/Timelock function to execute a passed proposal after voting period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyAdmin proposalExecutable(_proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        if (keccak256(abi.encodePacked(proposals[_proposalId].parameterToChange)) == keccak256(abi.encodePacked("platformCommissionRate"))) {
            platformCommissionRate = proposals[_proposalId].newValue;
            emit PlatformCommissionRateSet(platformCommissionRate);
        } else {
            // Add more parameter change logic here for other parameters if needed.
            revert("Unsupported parameter to change.");
        }
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Get details of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }


    // -------- 4. Decentralized Revenue and Artist Payouts --------

    /**
     * @dev Users purchase an artwork.
     * @param _artId The ID of the artwork to purchase.
     */
    function purchaseArt(uint256 _artId) public payable onlyApprovedArt(_artId) exhibitionActive(getActiveExhibitionForArt(_artId)) {
        require(msg.value >= artworks[_artId].price, "Insufficient funds.");

        uint256 artistShare = (artworks[_artId].price * (100 - platformCommissionRate)) / 100;
        uint256 platformShare = artworks[_artId].price - artistShare;

        artistEarnings[artworks[_artId].artist] += artistShare;
        platformEarnings += platformShare;

        payable(artworks[_artId].artist).transfer(artistShare); // Direct transfer for immediate artist payout (can be changed to pending earnings)
        payable(admin).transfer(platformShare); // Direct transfer for platform earnings (can be changed to pending earnings)

        emit ArtPurchased(_artId, msg.sender, artworks[_artId].artist, artworks[_artId].price);
    }

    /**
     * @dev Admin sets the platform commission rate.
     * @param _newRate The new commission rate percentage (e.g., 10 for 10%).
     */
    function setPlatformCommissionRate(uint256 _newRate) public onlyAdmin {
        require(_newRate <= 100, "Commission rate cannot exceed 100%.");
        platformCommissionRate = _newRate;
        emit PlatformCommissionRateSet(_newRate);
    }

    /**
     * @dev Artists withdraw their accumulated earnings.
     */
    function withdrawArtistEarnings() public {
        uint256 amount = artistEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw.");
        artistEarnings[msg.sender] = 0; // Reset earnings to zero before transfer to prevent re-entrancy issues in more complex scenarios
        payable(msg.sender).transfer(amount);
        emit ArtistEarningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Admin withdraws platform commission earnings.
     */
    function withdrawPlatformEarnings() public onlyAdmin {
        uint256 amount = platformEarnings;
        require(amount > 0, "No platform earnings to withdraw.");
        platformEarnings = 0;
        payable(admin).transfer(amount);
        emit PlatformEarningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Get an artist's pending earnings.
     * @param _artistAddress The address of the artist.
     * @return uint256 The artist's pending earnings.
     */
    function getArtistEarnings(address _artistAddress) public view returns (uint256) {
        return artistEarnings[_artistAddress];
    }


    // -------- 5. Utility and Access Control --------

    /**
     * @dev Check if an address is an admin.
     * @param _address The address to check.
     * @return bool True if admin, false otherwise.
     */
    function isAdmin(address _address) public view returns (bool) {
        return _address == admin;
    }

    /**
     * @dev Check if an address is a curator.
     * @param _address The address to check.
     * @return bool True if curator, false otherwise.
     */
    function isCurator(address _address) public view returns (bool) {
        return curators[_address];
    }

    /**
     * @dev Get details of an artwork.
     * @param _artId The ID of the artwork.
     * @return Art struct containing artwork details.
     */
    function getArtDetails(uint256 _artId) public view returns (Art memory) {
        return artworks[_artId];
    }

    /**
     * @dev Get the total count of approved artworks.
     * @return uint256 Count of approved artworks.
     */
    function getApprovedArtCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= artCount; i++) {
            if (artworks[i].approved) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Internal helper function to get the active exhibition ID for an artwork.
     * If art is in multiple active exhibitions, it returns the first one found.
     * @param _artId The ID of the artwork.
     * @return uint256 The ID of the active exhibition containing the art, or 0 if not in any active exhibition.
     */
    function getActiveExhibitionForArt(uint256 _artId) internal view returns (uint256) {
        for (uint256 i = 1; i <= exhibitionCount; i++) {
            if (exhibitions[i].isActive) {
                for (uint256 j = 0; j < exhibitions[i].artIds.length; j++) {
                    if (exhibitions[i].artIds[j] == _artId) {
                        return i;
                    }
                }
            }
        }
        return 0; // Not found in any active exhibition
    }

    /**
     * @dev Function to set the proposal voting period. Only callable by admin.
     * @param _votingPeriodInSeconds Voting period in seconds.
     */
    function setProposalVotingPeriod(uint256 _votingPeriodInSeconds) public onlyAdmin {
        proposalVotingPeriod = _votingPeriodInSeconds;
    }

    /**
     * @dev Function to get the current proposal voting period.
     * @return uint256 Voting period in seconds.
     */
    function getProposalVotingPeriod() public view returns (uint256) {
        return proposalVotingPeriod;
    }
}
```