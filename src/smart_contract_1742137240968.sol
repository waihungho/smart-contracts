```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Advanced Concept Smart Contract
 * @author Bard (AI Assistant)
 * @dev This contract implements a Decentralized Autonomous Art Gallery (DAAG) with advanced features
 *      beyond typical NFT marketplaces or DAOs. It focuses on collaborative curation, dynamic NFT displays,
 *      artist reputation, and community governance.
 *
 * **Contract Outline and Function Summary:**
 *
 * **I. Gallery Initialization and Setup:**
 *   1. `initializeGallery(string _galleryName, address _governanceTokenAddress)`: Initializes the gallery with a name and governance token address.
 *   2. `setGalleryName(string _newName)`: Allows the gallery owner to change the gallery name.
 *   3. `setGovernanceTokenAddress(address _newTokenAddress)`: Allows the gallery owner to update the governance token address.
 *   4. `setExhibitionDuration(uint256 _durationInDays)`: Sets the default duration for exhibitions in days.
 *   5. `setSubmissionFee(uint256 _fee)`: Sets the fee for artists to submit artwork to exhibitions.
 *   6. `setCurationFee(uint256 _fee)`: Sets the fee curators receive for successfully curating exhibitions.
 *
 * **II. Curator Management & Decentralized Curation:**
 *   7. `nominateCurator(address _curatorAddress)`: Allows governance token holders to nominate addresses as curators.
 *   8. `voteForCurator(address _curatorAddress, bool _support)`: Governance token holders vote on nominated curators.
 *   9. `removeCurator(address _curatorAddress)`: Allows governance token holders to remove curators.
 *   10. `getActiveCurators()`: Returns a list of currently active curators.
 *
 * **III. Exhibition Management & Dynamic NFT Display:**
 *   11. `createExhibition(string _exhibitionName, string _exhibitionTheme, uint256 _startTime, uint256 _endTime)`: Curators can create new exhibitions with name, theme, and time frame.
 *   12. `submitArtToExhibition(uint256 _exhibitionId, address _nftContract, uint256 _tokenId)`: Artists submit their NFTs to an exhibition.
 *   13. `voteForExhibitionArt(uint256 _exhibitionId, uint256 _submissionId, bool _support)`: Curators vote on submitted artworks for inclusion in the exhibition.
 *   14. `startExhibition(uint256 _exhibitionId)`:  Starts an exhibition, making curated NFTs visible.
 *   15. `endExhibition(uint256 _exhibitionId)`: Ends an exhibition, potentially triggering curator rewards.
 *   16. `getExhibitionDetails(uint256 _exhibitionId)`: Returns detailed information about a specific exhibition.
 *   17. `getExhibitionArtworks(uint256 _exhibitionId)`: Returns a list of NFTs included in a specific exhibition.
 *   18. `dynamicNFTDisplayData(uint256 _exhibitionId, uint256 _artworkIndex)`: Returns dynamic display data for an artwork in an exhibition, potentially based on popularity or curator ranking (placeholder logic).
 *
 * **IV. Artist Reputation & Reward System:**
 *   19. `registerArtist(string _artistName, string _artistBio)`: Artists can register their profiles with the gallery.
 *   20. `getArtistProfile(address _artistAddress)`: Retrieves an artist's profile information.
 *   21. `setArtistProfile(string _artistName, string _artistBio)`: Artists can update their profile information.
 *   22. `claimExhibitionRewards(uint256 _exhibitionId)`: Artists whose NFTs were exhibited can claim rewards (placeholder for reward mechanism).
 *
 * **V. Governance & Parameter Updates:**
 *   23. `proposeGovernanceChange(string _description, bytes memory _calldata)`: Governance token holders can propose changes to the contract parameters or logic.
 *   24. `voteOnGovernanceChange(uint256 _proposalId, bool _support)`: Governance token holders vote on governance proposals.
 *   25. `executeGovernanceChange(uint256 _proposalId)`: Executes a successful governance proposal.
 *
 * **VI. Emergency & Admin Functions:**
 *   26. `emergencyWithdraw(address payable _recipient, uint256 _amount)`: Gallery owner can withdraw accidentally sent tokens.
 *   27. `pauseContract()`: Gallery owner can pause the contract in case of emergency.
 *   28. `unpauseContract()`: Gallery owner can unpause the contract.
 */

contract DecentralizedAutonomousArtGallery {
    // ---- State Variables ----

    string public galleryName;
    address public galleryOwner;
    address public governanceTokenAddress;
    uint256 public exhibitionDurationDays = 30; // Default exhibition duration
    uint256 public submissionFee = 0.1 ether; // Fee for submitting art
    uint256 public curationFee = 0.05 ether;  // Fee for curators per successful exhibition

    mapping(address => bool) public isCurator;
    address[] public activeCurators;
    mapping(address => uint256) public curatorNominationVotes;
    address[] public curatorNominations;

    uint256 public nextExhibitionId = 1;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => uint256) public exhibitionCuratorVotes; // votes needed for exhibition to start
    mapping(uint256 => ExhibitionSubmission[]) public exhibitionSubmissions;
    mapping(uint256 => mapping(uint256 => uint256)) public submissionCuratorVotes; // Exhibition ID -> Submission ID -> votes needed for inclusion

    mapping(address => ArtistProfile) public artistProfiles;

    uint256 public nextGovernanceProposalId = 1;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes;

    bool public paused = false;

    // ---- Structs ----

    struct Exhibition {
        uint256 id;
        string name;
        string theme;
        address curator;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        address[] curatedArtworks; // List of NFT contract addresses and token IDs
    }

    struct ExhibitionSubmission {
        uint256 id;
        address artist;
        address nftContract;
        uint256 tokenId;
        bool isAccepted;
        uint256 curatorVotes;
    }

    struct ArtistProfile {
        string name;
        string bio;
        bool registered;
    }

    struct GovernanceProposal {
        uint256 id;
        string description;
        bytes calldataData;
        bool executed;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    // ---- Events ----

    event GalleryInitialized(string galleryName, address owner, address governanceToken);
    event GalleryNameUpdated(string newName);
    event GovernanceTokenUpdated(address newTokenAddress);
    event ExhibitionDurationSet(uint256 durationInDays);
    event SubmissionFeeSet(uint256 fee);
    event CurationFeeSet(uint256 fee);

    event CuratorNominated(address curatorAddress, address nominator);
    event CuratorVoteCast(address curatorAddress, address voter, bool support);
    event CuratorRemoved(address curatorAddress, address remover);
    event CuratorAdded(address curatorAddress);

    event ExhibitionCreated(uint256 exhibitionId, string exhibitionName, address curator);
    event ArtSubmittedToExhibition(uint256 exhibitionId, uint256 submissionId, address artist, address nftContract, uint256 tokenId);
    event ArtVoteCastForExhibition(uint256 exhibitionId, uint256 submissionId, address curator, bool support);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event ArtIncludedInExhibition(uint256 exhibitionId, uint256 submissionId, address nftContract, uint256 tokenId);
    event ExhibitionRewardsClaimed(uint256 exhibitionId, address artist, uint256 rewardAmount); // Placeholder

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string artistName);

    event GovernanceProposalCreated(uint256 proposalId, string description, address proposer);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);

    event EmergencyWithdrawal(address recipient, uint256 amount);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // ---- Modifiers ----

    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Only curators can call this function.");
        _;
    }

    modifier onlyGovernanceTokenHolders() {
        // Placeholder: In a real implementation, you'd check governance token balance.
        // For simplicity, assuming anyone can vote if governanceTokenAddress is set.
        require(governanceTokenAddress != address(0), "Governance token not set.");
        _;
    }

    modifier exhibitionExists(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].id != 0, "Exhibition does not exist.");
        _;
    }

    modifier exhibitionActive(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        _;
    }

    modifier contractNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }


    // ---- Functions ----

    constructor() {
        galleryOwner = msg.sender;
    }

    /// @notice Initializes the gallery with a name and governance token address.
    /// @param _galleryName The name of the art gallery.
    /// @param _governanceTokenAddress The address of the governance token contract.
    function initializeGallery(string memory _galleryName, address _governanceTokenAddress) external onlyGalleryOwner {
        require(bytes(_galleryName).length > 0, "Gallery name cannot be empty.");
        require(_governanceTokenAddress != address(0), "Governance token address cannot be zero.");
        require(bytes(galleryName).length == 0, "Gallery already initialized."); // Prevent re-initialization

        galleryName = _galleryName;
        governanceTokenAddress = _governanceTokenAddress;
        emit GalleryInitialized(_galleryName, galleryOwner, _governanceTokenAddress);
    }

    /// @notice Allows the gallery owner to change the gallery name.
    /// @param _newName The new name for the gallery.
    function setGalleryName(string memory _newName) external onlyGalleryOwner {
        require(bytes(_newName).length > 0, "Gallery name cannot be empty.");
        galleryName = _newName;
        emit GalleryNameUpdated(_newName);
    }

    /// @notice Allows the gallery owner to update the governance token address.
    /// @param _newTokenAddress The new governance token address.
    function setGovernanceTokenAddress(address _newTokenAddress) external onlyGalleryOwner {
        require(_newTokenAddress != address(0), "Governance token address cannot be zero.");
        governanceTokenAddress = _newTokenAddress;
        emit GovernanceTokenUpdated(_newTokenAddress);
    }

    /// @notice Sets the default duration for exhibitions in days.
    /// @param _durationInDays The duration of exhibitions in days.
    function setExhibitionDuration(uint256 _durationInDays) external onlyGalleryOwner {
        require(_durationInDays > 0, "Exhibition duration must be greater than 0.");
        exhibitionDurationDays = _durationInDays;
        emit ExhibitionDurationSet(_durationInDays);
    }

    /// @notice Sets the fee for artists to submit artwork to exhibitions.
    /// @param _fee The submission fee in wei.
    function setSubmissionFee(uint256 _fee) external onlyGalleryOwner {
        submissionFee = _fee;
        emit SubmissionFeeSet(_fee);
    }

    /// @notice Sets the fee curators receive for successfully curating exhibitions.
    /// @param _fee The curation fee in wei.
    function setCurationFee(uint256 _fee) external onlyGalleryOwner {
        curationFee = _fee;
        emit CurationFeeSet(_fee);
    }

    /// @notice Allows governance token holders to nominate addresses as curators.
    /// @param _curatorAddress The address to be nominated as a curator.
    function nominateCurator(address _curatorAddress) external onlyGovernanceTokenHolders contractNotPaused {
        require(_curatorAddress != address(0), "Invalid curator address.");
        require(!isCurator[_curatorAddress], "Address is already a curator.");
        require(!addressInArray(curatorNominations, _curatorAddress), "Address is already nominated.");

        curatorNominations.push(_curatorAddress);
        curatorNominationVotes[_curatorAddress] = 0; // Initialize votes
        emit CuratorNominated(_curatorAddress, msg.sender);
    }

    /// @notice Governance token holders vote on nominated curators.
    /// @param _curatorAddress The address of the curator nomination.
    /// @param _support True to vote in favor, false to vote against.
    function voteForCurator(address _curatorAddress, bool _support) external onlyGovernanceTokenHolders contractNotPaused {
        require(addressInArray(curatorNominations, _curatorAddress), "Address is not nominated.");
        // In a real scenario, check governance token balance of voter here for voting power.

        if (_support) {
            curatorNominationVotes[_curatorAddress]++;
        } else {
            curatorNominationVotes[_curatorAddress]--; // Allow negative votes for removal consideration
        }
        emit CuratorVoteCast(_curatorAddress, msg.sender, _support);

        // Simple auto-approval mechanism (can be improved with threshold and time limits)
        if (curatorNominationVotes[_curatorAddress] >= 5) { // Example: Need 5 positive votes
            addCurator(_curatorAddress);
        }
    }

    /// @notice Allows governance token holders to remove curators.
    /// @param _curatorAddress The address of the curator to remove.
    function removeCurator(address _curatorAddress) external onlyGovernanceTokenHolders contractNotPaused {
        require(isCurator[_curatorAddress], "Address is not a curator.");

        // In a real scenario, implement a voting mechanism similar to curator nomination for removal.
        // For simplicity, allowing direct removal by governance for now.

        isCurator[_curatorAddress] = false;
        removeAddressFromArray(activeCurators, _curatorAddress);
        emit CuratorRemoved(_curatorAddress, msg.sender);
    }

    /// @notice Adds a curator to the active curator list. Internal function.
    /// @param _curatorAddress The address of the curator to add.
    function addCurator(address _curatorAddress) internal {
        isCurator[_curatorAddress] = true;
        activeCurators.push(_curatorAddress);
        removeAddressFromArray(curatorNominations, _curatorAddress); // Remove from nominations
        emit CuratorAdded(_curatorAddress);
    }

    /// @notice Returns a list of currently active curators.
    /// @return An array of active curator addresses.
    function getActiveCurators() external view returns (address[] memory) {
        return activeCurators;
    }

    /// @notice Curators can create new exhibitions with name, theme, and time frame.
    /// @param _exhibitionName The name of the exhibition.
    /// @param _exhibitionTheme The theme of the exhibition.
    /// @param _startTime The desired start time of the exhibition (timestamp).
    /// @param _endTime The desired end time of the exhibition (timestamp).
    function createExhibition(string memory _exhibitionName, string memory _exhibitionTheme, uint256 _startTime, uint256 _endTime) external onlyCurator contractNotPaused {
        require(bytes(_exhibitionName).length > 0, "Exhibition name cannot be empty.");
        require(bytes(_exhibitionTheme).length > 0, "Exhibition theme cannot be empty.");
        require(_startTime < _endTime, "Start time must be before end time.");
        require(_startTime > block.timestamp, "Start time must be in the future."); // Ensure future start

        exhibitions[nextExhibitionId] = Exhibition({
            id: nextExhibitionId,
            name: _exhibitionName,
            theme: _exhibitionTheme,
            curator: msg.sender,
            startTime: _startTime,
            endTime: _endTime,
            isActive: false,
            curatedArtworks: new address[](0) // Initialize empty artwork list
        });
        exhibitionCuratorVotes[nextExhibitionId] = 0; // Initialize curator votes
        nextExhibitionId++;
        emit ExhibitionCreated(nextExhibitionId - 1, _exhibitionName, msg.sender);
    }

    /// @notice Artists submit their NFTs to an exhibition.
    /// @param _exhibitionId The ID of the exhibition to submit to.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    function submitArtToExhibition(uint256 _exhibitionId, address _nftContract, uint256 _tokenId) external payable contractNotPaused exhibitionExists(_exhibitionId) {
        require(msg.value >= submissionFee, "Submission fee not paid.");
        require(exhibitions[_exhibitionId].startTime > block.timestamp, "Exhibition submission period has ended."); // Submission before start
        require(exhibitions[_exhibitionId].endTime > block.timestamp, "Exhibition is already ended."); // Submission before end

        uint256 submissionId = exhibitionSubmissions[_exhibitionId].length;
        exhibitionSubmissions[_exhibitionId].push(ExhibitionSubmission({
            id: submissionId,
            artist: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            isAccepted: false,
            curatorVotes: 0
        }));
        submissionCuratorVotes[_exhibitionId][submissionId] = 0; // Initialize curator votes for submission

        emit ArtSubmittedToExhibition(_exhibitionId, submissionId, msg.sender, _nftContract, _tokenId);
    }

    /// @notice Curators vote on submitted artworks for inclusion in the exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _submissionId The ID of the artwork submission.
    /// @param _support True to vote for inclusion, false to vote against.
    function voteForExhibitionArt(uint256 _exhibitionId, uint256 _submissionId, bool _support) external onlyCurator contractNotPaused exhibitionExists(_exhibitionId) {
        require(!exhibitions[_exhibitionId].isActive, "Cannot vote on art for active exhibition."); // Voting before exhibition start
        require(_submissionId < exhibitionSubmissions[_exhibitionId].length, "Invalid submission ID.");
        require(!exhibitionSubmissions[_exhibitionId][_submissionId].isAccepted, "Artwork already decided."); // Prevent revote

        if (_support) {
            submissionCuratorVotes[_exhibitionId][_submissionId]++;
        } else {
            submissionCuratorVotes[_exhibitionId][_submissionId]--; // Allow negative votes
        }
        emit ArtVoteCastForExhibition(_exhibitionId, _submissionId, msg.sender, _support);

        // Simple approval mechanism (can be improved with quorum, time limits)
        if (submissionCuratorVotes[_exhibitionId][_submissionId] >= 3) { // Example: Need 3 curator approvals
            exhibitionSubmissions[_exhibitionId][_submissionId].isAccepted = true;
            emit ArtIncludedInExhibition(_exhibitionId, _submissionId, exhibitionSubmissions[_exhibitionId][_submissionId].nftContract, exhibitionSubmissions[_exhibitionId][_submissionId].tokenId);
        }
    }

    /// @notice Starts an exhibition, making curated NFTs visible.
    /// @param _exhibitionId The ID of the exhibition to start.
    function startExhibition(uint256 _exhibitionId) external onlyCurator contractNotPaused exhibitionExists(_exhibitionId) {
        require(!exhibitions[_exhibitionId].isActive, "Exhibition already active.");
        require(exhibitions[_exhibitionId].startTime <= block.timestamp, "Exhibition start time not reached yet.");

        ExhibitionSubmission[] memory submissions = exhibitionSubmissions[_exhibitionId];
        for (uint256 i = 0; i < submissions.length; i++) {
            if (submissions[i].isAccepted) {
                exhibitions[_exhibitionId].curatedArtworks.push(address(uint160(submissions[i].nftContract) | (submissions[i].tokenId << 160))); // Pack contract address and token ID into address
            }
        }

        exhibitions[_exhibitionId].isActive = true;
        emit ExhibitionStarted(_exhibitionId);
    }


    /// @notice Ends an exhibition, potentially triggering curator rewards.
    /// @param _exhibitionId The ID of the exhibition to end.
    function endExhibition(uint256 _exhibitionId) external onlyCurator contractNotPaused exhibitionExists(_exhibitionId) exhibitionActive(_exhibitionId) {
        require(exhibitions[_exhibitionId].endTime <= block.timestamp, "Exhibition end time not reached yet.");

        exhibitions[_exhibitionId].isActive = false;
        // TODO: Implement curator reward distribution mechanism here.
        // Example: Transfer curationFee to the curator.
        // payable(exhibitions[_exhibitionId].curator).transfer(curationFee);

        emit ExhibitionEnded(_exhibitionId);
    }

    /// @notice Returns detailed information about a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @return Exhibition struct containing exhibition details.
    function getExhibitionDetails(uint256 _exhibitionId) external view exhibitionExists(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /// @notice Returns a list of NFTs included in a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @return An array of packed NFT contract addresses and token IDs.
    function getExhibitionArtworks(uint256 _exhibitionId) external view exhibitionExists(_exhibitionId) returns (address[] memory) {
        return exhibitions[_exhibitionId].curatedArtworks;
    }

    /// @notice Returns dynamic display data for an artwork in an exhibition (Placeholder).
    /// @dev This is a placeholder function. In a real implementation, this could fetch data
    ///      from an oracle or use on-chain popularity metrics to dynamically influence
    ///      how NFTs are displayed (e.g., ranking, size, effects).
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _artworkIndex The index of the artwork in the exhibition's curatedArtworks array.
    /// @return A string representing dynamic display data (placeholder).
    function dynamicNFTDisplayData(uint256 _exhibitionId, uint256 _artworkIndex) external view exhibitionExists(_exhibitionId) exhibitionActive(_exhibitionId) returns (string memory) {
        require(_artworkIndex < exhibitions[_exhibitionId].curatedArtworks.length, "Invalid artwork index.");
        // Placeholder logic:  Return "Popular" if artwork index is even, "Emerging" if odd.
        if (_artworkIndex % 2 == 0) {
            return "Popular - Highly Ranked by Curators";
        } else {
            return "Emerging - Newly Curated Artwork";
        }
    }

    /// @notice Artists can register their profiles with the gallery.
    /// @param _artistName The name of the artist.
    /// @param _artistBio A short biography of the artist.
    function registerArtist(string memory _artistName, string memory _artistBio) external contractNotPaused {
        require(bytes(_artistName).length > 0, "Artist name cannot be empty.");
        require(!artistProfiles[msg.sender].registered, "Artist profile already registered.");

        artistProfiles[msg.sender] = ArtistProfile({
            name: _artistName,
            bio: _artistBio,
            registered: true
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    /// @notice Retrieves an artist's profile information.
    /// @param _artistAddress The address of the artist.
    /// @return ArtistProfile struct containing artist information.
    function getArtistProfile(address _artistAddress) external view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    /// @notice Artists can update their profile information.
    /// @param _artistName The new name of the artist.
    /// @param _artistBio The new biography of the artist.
    function setArtistProfile(string memory _artistName, string memory _artistBio) external contractNotPaused {
        require(artistProfiles[msg.sender].registered, "Artist profile not registered yet.");
        require(bytes(_artistName).length > 0, "Artist name cannot be empty.");

        artistProfiles[msg.sender].name = _artistName;
        artistProfiles[msg.sender].bio = _artistBio;
        emit ArtistProfileUpdated(msg.sender, _artistName);
    }

    /// @notice Artists whose NFTs were exhibited can claim rewards (Placeholder reward mechanism).
    /// @param _exhibitionId The ID of the exhibition.
    function claimExhibitionRewards(uint256 _exhibitionId) external contractNotPaused exhibitionExists(_exhibitionId) {
        require(!exhibitions[_exhibitionId].isActive, "Cannot claim rewards during active exhibition.");
        // TODO: Implement reward calculation and distribution logic here.
        // This is a placeholder.  Rewards could be based on exhibition duration, NFT popularity, etc.
        // Example: Transfer a fixed amount to the artist if their art was exhibited.
        // payable(msg.sender).transfer(0.01 ether);
        emit ExhibitionRewardsClaimed(_exhibitionId, msg.sender, 0); // Placeholder reward amount
    }

    /// @notice Governance token holders can propose changes to contract parameters or logic.
    /// @param _description A description of the proposed change.
    /// @param _calldata The calldata to execute the change (function signature and parameters).
    function proposeGovernanceChange(string memory _description, bytes memory _calldata) external onlyGovernanceTokenHolders contractNotPaused {
        require(bytes(_description).length > 0, "Proposal description cannot be empty.");
        require(_calldata.length > 0, "Proposal calldata cannot be empty.");

        governanceProposals[nextGovernanceProposalId] = GovernanceProposal({
            id: nextGovernanceProposalId,
            description: _description,
            calldataData: _calldata,
            executed: false,
            votesFor: 0,
            votesAgainst: 0
        });
        nextGovernanceProposalId++;
        emit GovernanceProposalCreated(nextGovernanceProposalId - 1, _description, msg.sender);
    }

    /// @notice Governance token holders vote on governance proposals.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnGovernanceChange(uint256 _proposalId, bool _support) external onlyGovernanceTokenHolders contractNotPaused {
        require(governanceProposals[_proposalId].id != 0, "Governance proposal does not exist.");
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed.");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true; // Record voter

        if (_support) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);

        // Simple approval mechanism (can be improved with quorum, time limits)
        if (governanceProposals[_proposalId].votesFor > governanceProposals[_proposalId].votesAgainst * 2) { // Example: 2:1 majority
            executeGovernanceChange(_proposalId);
        }
    }

    /// @notice Executes a successful governance proposal.
    /// @param _proposalId The ID of the governance proposal to execute.
    function executeGovernanceChange(uint256 _proposalId) public onlyGovernanceTokenHolders contractNotPaused {
        require(governanceProposals[_proposalId].id != 0, "Governance proposal does not exist.");
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed.");
        require(governanceProposals[_proposalId].votesFor > governanceProposals[_proposalId].votesAgainst * 2, "Proposal not approved yet."); // Re-check approval

        (bool success, ) = address(this).delegatecall(governanceProposals[_proposalId].calldataData);
        require(success, "Governance proposal execution failed.");
        governanceProposals[_proposalId].executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }


    /// @notice Gallery owner can withdraw accidentally sent tokens.
    /// @param _recipient The address to receive the withdrawn tokens.
    /// @param _amount The amount of tokens to withdraw in wei.
    function emergencyWithdraw(address payable _recipient, uint256 _amount) external onlyGalleryOwner {
        require(_recipient != address(0), "Invalid recipient address.");
        require(address(this).balance >= _amount, "Insufficient contract balance.");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Emergency withdrawal failed.");
        emit EmergencyWithdrawal(_recipient, _amount);
    }

    /// @notice Gallery owner can pause the contract in case of emergency.
    function pauseContract() external onlyGalleryOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Gallery owner can unpause the contract.
    function unpauseContract() external onlyGalleryOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // ---- Internal Helper Functions ----

    function addressInArray(address[] memory _array, address _address) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function removeAddressFromArray(address[] storage _array, address _address) internal {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _address) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}
```