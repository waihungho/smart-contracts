```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery - "ArtVerse DAO Gallery"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery, enabling artists to showcase their work,
 *      collectors to purchase and support art, and a DAO to govern the gallery's operations and exhibitions.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Gallery Management:**
 *    - `createExhibition(string _exhibitionName, string _description, uint256 _startTime, uint256 _endTime)`: Allows the DAO to create a new art exhibition with name, description, and time frame.
 *    - `submitArtToExhibition(uint256 _exhibitionId, address _nftContract, uint256 _tokenId)`: Artists can submit their NFTs to an active exhibition.
 *    - `voteOnArtSubmission(uint256 _exhibitionId, uint256 _submissionId, bool _approve)`: DAO members vote on submitted artwork for inclusion in the exhibition.
 *    - `finalizeExhibition(uint256 _exhibitionId)`:  Finalizes an exhibition, selecting approved artworks and potentially distributing rewards to participating artists.
 *    - `purchaseArt(uint256 _exhibitionId, uint256 _submissionId)`:  Collectors can purchase artwork directly from the exhibition (if enabled by the DAO).
 *    - `withdrawArtistFunds(uint256 _exhibitionId, uint256 _submissionId)`: Artists can withdraw funds earned from sales or rewards related to their exhibited artwork.
 *    - `setGalleryCommission(uint256 _commissionPercentage)`: DAO can set the commission percentage charged on art sales within the gallery.
 *    - `setGovernanceTokenAddress(address _governanceToken)`:  Owner can set the address of the governance token used for DAO voting and decisions.
 *
 * **2. Artist Management & Curation:**
 *    - `registerArtist(string _artistName, string _artistBio)`: Artists can register with the gallery providing their name and bio.
 *    - `updateArtistProfile(string _newBio)`: Registered artists can update their profile information.
 *    - `getArtistProfile(address _artistAddress)`:  View artist profile information.
 *    - `nominateCurator(address _curatorAddress)`: DAO members can nominate addresses to become curators.
 *    - `voteOnCuratorNomination(address _curatorAddress, bool _approve)`: DAO members vote on nominated curators.
 *    - `removeCurator(address _curatorAddress)`: DAO can remove a curator if necessary.
 *
 * **3. DAO Governance & Proposals:**
 *    - `createProposal(string _title, string _description, bytes _calldata)`: DAO members can create proposals for gallery changes or actions.
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: DAO members vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: If a proposal passes, authorized roles can execute the proposed action.
 *    - `delegateVote(address _delegatee)`: Governance token holders can delegate their voting power to another address.
 *    - `stakeGovernanceTokens(uint256 _amount)`: DAO members can stake governance tokens to participate in voting and potentially earn rewards.
 *    - `unstakeGovernanceTokens(uint256 _amount)`: DAO members can unstake their governance tokens.
 *
 * **4. Utility & Information:**
 *    - `viewExhibitionDetails(uint256 _exhibitionId)`: View details of a specific exhibition.
 *    - `viewArtDetails(uint256 _exhibitionId, uint256 _submissionId)`: View details of a submitted artwork within an exhibition.
 *    - `getExhibitionArtworks(uint256 _exhibitionId)`: Get a list of artwork IDs in a specific exhibition.
 *    - `getAllExhibitions()`: Get a list of all exhibition IDs.
 *    - `getGalleryBalance()`: View the contract's ETH balance.
 *    - `emergencyWithdraw(address _recipient, uint256 _amount)`: Owner-controlled emergency withdrawal function for unforeseen circumstances.
 */

contract ArtVerseDAOGallery {
    // --- State Variables ---

    address public owner;
    address public governanceTokenAddress;

    uint256 public galleryCommissionPercentage = 5; // Default commission

    uint256 public exhibitionCounter;
    mapping(uint256 => Exhibition) public exhibitions;

    uint256 public artistCounter;
    mapping(address => ArtistProfile) public artistProfiles;

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;

    mapping(address => bool) public curators;
    address[] public curatorList;

    struct Exhibition {
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isFinalized;
        uint256 submissionCounter;
        mapping(uint256 => ArtSubmission) artSubmissions;
        uint256[] approvedSubmissionIds;
    }

    struct ArtSubmission {
        address artistAddress;
        address nftContract;
        uint256 tokenId;
        bool isApproved;
        uint256 upVotes;
        uint256 downVotes;
        uint256 purchasePrice; // Set by DAO if for sale, 0 if not
        bool isSold;
    }

    struct ArtistProfile {
        string name;
        string bio;
        bool isRegistered;
    }

    struct Proposal {
        string title;
        string description;
        address proposer;
        bytes calldataData; // Data for contract call if proposal passes
        bool isActive;
        uint256 upVotes;
        uint256 downVotes;
        bool isExecuted;
    }

    // --- Events ---
    event ExhibitionCreated(uint256 exhibitionId, string name, uint256 startTime, uint256 endTime);
    event ArtSubmitted(uint256 exhibitionId, uint256 submissionId, address artistAddress, address nftContract, uint256 tokenId);
    event ArtSubmissionVoted(uint256 exhibitionId, uint256 submissionId, address voter, bool approve);
    event ExhibitionFinalized(uint256 exhibitionId);
    event ArtPurchased(uint256 exhibitionId, uint256 submissionId, address buyer, uint256 price);
    event ArtistRegistered(address artistAddress, string name);
    event ArtistProfileUpdated(address artistAddress);
    event CuratorNominated(address curatorAddress, address nominator);
    event CuratorVotedOn(address curatorAddress, address voter, bool approve);
    event CuratorAdded(address curatorAddress);
    event CuratorRemoved(address curatorAddress);
    event ProposalCreated(uint256 proposalId, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event GovernanceTokenAddressSet(address governanceToken);
    event GalleryCommissionSet(uint256 commissionPercentage);
    event GovernanceTokensStaked(address staker, uint256 amount);
    event GovernanceTokensUnstaked(address unstaker, uint256 amount);
    event EmergencyWithdrawal(address recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can call this function.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].isRegistered, "Only registered artists can call this function.");
        _;
    }

    modifier onlyGovernanceTokenHolders() {
        require(governanceTokenAddress != address(0), "Governance token address not set.");
        // In a real DAO, you'd interface with the governance token contract to check for holdings.
        // For simplicity in this example, we'll assume any address with governance tokens can participate.
        // You'd typically use a library like OpenZeppelin's ERC20Votes or a similar mechanism.
        _;
    }

    modifier exhibitionExists(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].startTime != 0, "Exhibition does not exist.");
        _;
    }

    modifier validExhibitionTime(uint256 _exhibitionId) {
        require(block.timestamp >= exhibitions[_exhibitionId].startTime && block.timestamp <= exhibitions[_exhibitionId].endTime, "Exhibition is not active yet or has ended.");
        _;
    }

    modifier submissionExists(uint256 _exhibitionId, uint256 _submissionId) {
        require(exhibitions[_exhibitionId].artSubmissions[_submissionId].artistAddress != address(0), "Submission does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposer != address(0), "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].isActive, "Proposal is not active.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].isExecuted, "Proposal already executed.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- 1. Core Gallery Management Functions ---

    /// @dev Allows the DAO to create a new art exhibition.
    /// @param _exhibitionName Name of the exhibition.
    /// @param _description Description of the exhibition.
    /// @param _startTime Unix timestamp for exhibition start.
    /// @param _endTime Unix timestamp for exhibition end.
    function createExhibition(
        string memory _exhibitionName,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyCurator {
        exhibitionCounter++;
        exhibitions[exhibitionCounter] = Exhibition({
            name: _exhibitionName,
            description: _description,
            startTime: _startTime,
            endTime: _endTime,
            isActive: true,
            isFinalized: false,
            submissionCounter: 0,
            approvedSubmissionIds: new uint256[](0)
        });
        emit ExhibitionCreated(exhibitionCounter, _exhibitionName, _startTime, _endTime);
    }

    /// @dev Artists can submit their NFTs to an active exhibition.
    /// @param _exhibitionId ID of the exhibition to submit to.
    /// @param _nftContract Address of the NFT contract.
    /// @param _tokenId Token ID of the NFT.
    function submitArtToExhibition(
        uint256 _exhibitionId,
        address _nftContract,
        uint256 _tokenId
    ) external onlyRegisteredArtist exhibitionExists(_exhibitionId) validExhibitionTime(_exhibitionId) {
        require(!exhibitions[_exhibitionId].isFinalized, "Exhibition is finalized, submissions are closed.");
        exhibitions[_exhibitionId].submissionCounter++;
        uint256 submissionId = exhibitions[_exhibitionId].submissionCounter;
        exhibitions[_exhibitionId].artSubmissions[submissionId] = ArtSubmission({
            artistAddress: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            isApproved: false,
            upVotes: 0,
            downVotes: 0,
            purchasePrice: 0, // Default not for sale, DAO can set later
            isSold: false
        });
        emit ArtSubmitted(_exhibitionId, submissionId, msg.sender, _nftContract, _tokenId);
    }

    /// @dev DAO members vote on submitted artwork for inclusion in the exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @param _submissionId ID of the artwork submission.
    /// @param _approve True to approve, false to reject.
    function voteOnArtSubmission(
        uint256 _exhibitionId,
        uint256 _submissionId,
        bool _approve
    ) external onlyGovernanceTokenHolders exhibitionExists(_exhibitionId) validExhibitionTime(_exhibitionId) submissionExists(_exhibitionId, _submissionId) {
        require(!exhibitions[_exhibitionId].isFinalized, "Exhibition is finalized, voting is closed.");
        ArtSubmission storage submission = exhibitions[_exhibitionId].artSubmissions[_submissionId];
        if (_approve) {
            submission.upVotes++;
        } else {
            submission.downVotes++;
        }
        emit ArtSubmissionVoted(_exhibitionId, _submissionId, msg.sender, _approve);
    }

    /// @dev Finalizes an exhibition, selecting approved artworks based on votes and potentially distributing rewards.
    /// @param _exhibitionId ID of the exhibition to finalize.
    function finalizeExhibition(uint256 _exhibitionId) external onlyCurator exhibitionExists(_exhibitionId) validExhibitionTime(_exhibitionId) {
        require(!exhibitions[_exhibitionId].isFinalized, "Exhibition is already finalized.");
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        exhibition.isFinalized = true;
        exhibition.isActive = false; // Mark as inactive after finalization

        // Example Approval Logic:  Artwork approved if upVotes > downVotes (can be customized by DAO)
        for (uint256 i = 1; i <= exhibition.submissionCounter; i++) {
            ArtSubmission storage submission = exhibition.artSubmissions[i];
            if (submission.upVotes > submission.downVotes) {
                submission.isApproved = true;
                exhibition.approvedSubmissionIds.push(i);
            }
        }
        emit ExhibitionFinalized(_exhibitionId);
        // Future: Implement reward distribution logic to artists of approved artwork.
    }

    /// @dev Collectors can purchase artwork directly from the exhibition (if enabled by the DAO).
    /// @param _exhibitionId ID of the exhibition.
    /// @param _submissionId ID of the artwork submission to purchase.
    function purchaseArt(uint256 _exhibitionId, uint256 _submissionId) external payable exhibitionExists(_exhibitionId) submissionExists(_exhibitionId, _submissionId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        ArtSubmission storage submission = exhibition.artSubmissions[_submissionId];
        require(exhibition.isFinalized, "Exhibition must be finalized before purchasing.");
        require(submission.isApproved, "Artwork is not approved for exhibition and sale.");
        require(submission.purchasePrice > 0, "Artwork is not for sale.");
        require(!submission.isSold, "Artwork is already sold.");
        require(msg.value >= submission.purchasePrice, "Insufficient funds sent.");

        uint256 commissionAmount = (submission.purchasePrice * galleryCommissionPercentage) / 100;
        uint256 artistPayout = submission.purchasePrice - commissionAmount;

        submission.isSold = true;

        // Transfer funds: Commission to gallery, payout to artist
        payable(owner).transfer(commissionAmount); // Gallery commission goes to contract owner (can be DAO controlled wallet in real scenario)
        payable(submission.artistAddress).transfer(artistPayout);

        emit ArtPurchased(_exhibitionId, _submissionId, msg.sender, submission.purchasePrice);

        // Refund any excess ETH sent
        if (msg.value > submission.purchasePrice) {
            payable(msg.sender).transfer(msg.value - submission.purchasePrice);
        }
    }

    /// @dev Artists can withdraw funds earned from sales or rewards related to their exhibited artwork.
    /// @param _exhibitionId ID of the exhibition.
    /// @param _submissionId ID of the artwork submission.
    function withdrawArtistFunds(uint256 _exhibitionId, uint256 _submissionId) external onlyRegisteredArtist exhibitionExists(_exhibitionId) submissionExists(_exhibitionId, _submissionId) {
        ArtSubmission storage submission = exhibitions[_exhibitionId].artSubmissions[_submissionId];
        require(submission.artistAddress == msg.sender, "Only the artist of this artwork can withdraw funds.");
        // In a real application, you'd track artist balances separately and manage withdrawals more robustly.
        // This simplified example assumes funds are directly transferred upon purchase in `purchaseArt`.
        // For demonstration, we'll assume artists can "withdraw" any funds the gallery might owe them (simplified).

        // **Important:** In a real-world scenario, you would need to implement a more sophisticated system
        // for tracking artist earnings and managing withdrawals, potentially using a separate accounting mechanism.

        // Placeholder - In a real system, this would trigger the actual withdrawal logic.
        // For now, we'll just emit an event to indicate a withdrawal attempt.
        emit EmergencyWithdrawal(msg.sender, 0); // Placeholder amount, actual amount would be calculated in a real system.
    }

    /// @dev DAO can set the commission percentage charged on art sales within the gallery.
    /// @param _commissionPercentage New commission percentage (0-100).
    function setGalleryCommission(uint256 _commissionPercentage) external onlyCurator {
        require(_commissionPercentage <= 100, "Commission percentage must be between 0 and 100.");
        galleryCommissionPercentage = _commissionPercentage;
        emit GalleryCommissionSet(_commissionPercentage);
    }

    /// @dev Owner can set the address of the governance token used for DAO voting and decisions.
    /// @param _governanceToken Address of the governance token contract.
    function setGovernanceTokenAddress(address _governanceToken) external onlyOwner {
        governanceTokenAddress = _governanceToken;
        emit GovernanceTokenAddressSet(_governanceToken);
    }

    // --- 2. Artist Management & Curation Functions ---

    /// @dev Artists can register with the gallery providing their name and bio.
    /// @param _artistName Artist's name.
    /// @param _artistBio Artist's biography.
    function registerArtist(string memory _artistName, string memory _artistBio) external {
        require(!artistProfiles[msg.sender].isRegistered, "Artist is already registered.");
        artistCounter++;
        artistProfiles[msg.sender] = ArtistProfile({
            name: _artistName,
            bio: _artistBio,
            isRegistered: true
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    /// @dev Registered artists can update their profile information.
    /// @param _newBio New artist biography.
    function updateArtistProfile(string memory _newBio) external onlyRegisteredArtist {
        artistProfiles[msg.sender].bio = _newBio;
        emit ArtistProfileUpdated(msg.sender);
    }

    /// @dev View artist profile information.
    /// @param _artistAddress Address of the artist.
    /// @return Artist profile details (name, bio, registration status).
    function getArtistProfile(address _artistAddress) external view returns (string memory name, string memory bio, bool isRegistered) {
        ArtistProfile memory profile = artistProfiles[_artistAddress];
        return (profile.name, profile.bio, profile.isRegistered);
    }

    /// @dev DAO members can nominate addresses to become curators.
    /// @param _curatorAddress Address to nominate as curator.
    function nominateCurator(address _curatorAddress) external onlyGovernanceTokenHolders {
        require(!curators[_curatorAddress], "Address is already a curator.");
        // In a real DAO, you might use a proposal system for curator nomination.
        // For simplicity, we'll directly nominate and then vote.
        emit CuratorNominated(_curatorAddress, msg.sender);
        // Future: Automatically create a proposal to vote on this nomination.
    }

    /// @dev DAO members vote on nominated curators.
    /// @param _curatorAddress Address of the nominated curator.
    /// @param _approve True to approve, false to reject.
    function voteOnCuratorNomination(address _curatorAddress, bool _approve) external onlyGovernanceTokenHolders {
        require(!curators[_curatorAddress], "Address is already a curator.");
        // In a real DAO, voting would be tied to governance token holdings.
        // For simplicity, any governance token holder can vote.
        emit CuratorVotedOn(_curatorAddress, msg.sender, _approve);
        // Future: Implement voting logic based on token holdings and thresholds for approval.
        if (_approve) {
            addCurator(_curatorAddress); // For simplicity, direct addition on approval. Real DAO would use proposal execution.
        }
    }

    /// @dev DAO can remove a curator if necessary.
    /// @param _curatorAddress Address of the curator to remove.
    function removeCurator(address _curatorAddress) external onlyCurator { // For simplicity, only curators can remove curators. Real DAO would have a different mechanism.
        require(curators[_curatorAddress], "Address is not a curator.");
        require(_curatorAddress != msg.sender, "Curator cannot remove themselves."); // Prevent self-removal in this example.
        removeCuratorInternal(_curatorAddress);
    }


    // --- 3. DAO Governance & Proposals Functions ---

    /// @dev DAO members can create proposals for gallery changes or actions.
    /// @param _title Title of the proposal.
    /// @param _description Description of the proposal.
    /// @param _calldata Calldata to be executed if proposal passes (e.g., function call and parameters).
    function createProposal(string memory _title, string memory _description, bytes memory _calldata) external onlyGovernanceTokenHolders {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            title: _title,
            description: _description,
            proposer: msg.sender,
            calldataData: _calldata,
            isActive: true,
            upVotes: 0,
            downVotes: 0,
            isExecuted: false
        });
        emit ProposalCreated(proposalCounter, _title, msg.sender);
    }

    /// @dev DAO members vote on active proposals.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _support True to support (upvote), false to oppose (downvote).
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyGovernanceTokenHolders proposalExists(_proposalId) proposalActive(_proposalId) proposalNotExecuted(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (_support) {
            proposal.upVotes++;
        } else {
            proposal.downVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @dev If a proposal passes (e.g., more upvotes than downvotes after a voting period), authorized roles can execute the proposed action.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyCurator proposalExists(_proposalId) proposalActive(_proposalId) proposalNotExecuted(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.upVotes > proposal.downVotes, "Proposal does not have enough support to be executed."); // Example passing condition
        proposal.isActive = false;
        proposal.isExecuted = true;
        (bool success, ) = address(this).call(proposal.calldataData); // Execute the calldata on this contract.
        require(success, "Proposal execution failed.");
        emit ProposalExecuted(_proposalId);
    }

    /// @dev Governance token holders can delegate their voting power to another address.
    /// @param _delegatee Address to delegate voting power to.
    function delegateVote(address _delegatee) external onlyGovernanceTokenHolders {
        // In a real DAO, delegation would be managed by the governance token contract itself.
        // This is a placeholder function to demonstrate the concept.
        // You would typically interact with the governance token contract here to delegate.
        // For this example, we'll just emit an event.
        emit EmergencyWithdrawal(_delegatee, 0); // Placeholder event to represent delegation.
    }

    /// @dev DAO members can stake governance tokens to participate in voting and potentially earn rewards.
    /// @param _amount Amount of governance tokens to stake.
    function stakeGovernanceTokens(uint256 _amount) external onlyGovernanceTokenHolders {
        // In a real DAO, staking would be managed by a separate staking contract or within the governance token contract.
        // This is a placeholder function to demonstrate the concept.
        // You would typically interact with the governance token contract here to transfer and stake tokens.
        // For this example, we'll just emit an event.
        emit GovernanceTokensStaked(msg.sender, _amount);
    }

    /// @dev DAO members can unstake governance tokens.
    /// @param _amount Amount of governance tokens to unstake.
    function unstakeGovernanceTokens(uint256 _amount) external onlyGovernanceTokenHolders {
        // In a real DAO, unstaking would be managed by a separate staking contract or within the governance token contract.
        // This is a placeholder function to demonstrate the concept.
        // You would typically interact with the governance token contract here to unstake and transfer back tokens.
        // For this example, we'll just emit an event.
        emit GovernanceTokensUnstaked(msg.sender, _amount);
    }


    // --- 4. Utility & Information Functions ---

    /// @dev View details of a specific exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @return Exhibition details (name, description, start/end times, active status, finalized status).
    function viewExhibitionDetails(uint256 _exhibitionId) external view exhibitionExists(_exhibitionId) returns (
        string memory name,
        string memory description,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        bool isFinalized
    ) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        return (exhibition.name, exhibition.description, exhibition.startTime, exhibition.endTime, exhibition.isActive, exhibition.isFinalized);
    }

    /// @dev View details of a submitted artwork within an exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @param _submissionId ID of the artwork submission.
    /// @return Artwork submission details (artist, NFT contract, token ID, approval status, votes, purchase price, sold status).
    function viewArtDetails(uint256 _exhibitionId, uint256 _submissionId) external view exhibitionExists(_exhibitionId) submissionExists(_exhibitionId, _submissionId) returns (
        address artistAddress,
        address nftContract,
        uint256 tokenId,
        bool isApproved,
        uint256 upVotes,
        uint256 downVotes,
        uint256 purchasePrice,
        bool isSold
    ) {
        ArtSubmission storage submission = exhibitions[_exhibitionId].artSubmissions[_submissionId];
        return (submission.artistAddress, submission.nftContract, submission.tokenId, submission.isApproved, submission.upVotes, submission.downVotes, submission.purchasePrice, submission.isSold);
    }

    /// @dev Get a list of artwork IDs in a specific exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @return Array of submission IDs.
    function getExhibitionArtworks(uint256 _exhibitionId) external view exhibitionExists(_exhibitionId) returns (uint256[] memory) {
        return exhibitions[_exhibitionId].approvedSubmissionIds; // Returns only approved artworks for simplicity. Can be adjusted to return all if needed.
    }

    /// @dev Get a list of all exhibition IDs.
    /// @return Array of exhibition IDs.
    function getAllExhibitions() external view returns (uint256[] memory) {
        uint256[] memory allExhibitionIds = new uint256[](exhibitionCounter);
        for (uint256 i = 1; i <= exhibitionCounter; i++) {
            allExhibitionIds[i - 1] = i;
        }
        return allExhibitionIds;
    }

    /// @dev View the contract's ETH balance.
    /// @return Contract's ETH balance.
    function getGalleryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Owner-controlled emergency withdrawal function for unforeseen circumstances.
    /// @param _recipient Address to receive the withdrawn ETH.
    /// @param _amount Amount of ETH to withdraw.
    function emergencyWithdraw(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount <= address(this).balance, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
        emit EmergencyWithdrawal(_recipient, _amount);
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to add a curator.
    /// @param _curatorAddress Address to add as curator.
    function addCurator(address _curatorAddress) internal {
        if (!curators[_curatorAddress]) {
            curators[_curatorAddress] = true;
            curatorList.push(_curatorAddress);
            emit CuratorAdded(_curatorAddress);
        }
    }

    /// @dev Internal function to remove a curator.
    /// @param _curatorAddress Address to remove as curator.
    function removeCuratorInternal(address _curatorAddress) internal {
        if (curators[_curatorAddress]) {
            curators[_curatorAddress] = false;
            // Remove from curatorList - (less efficient for large lists, consider optimization if needed)
            for (uint256 i = 0; i < curatorList.length; i++) {
                if (curatorList[i] == _curatorAddress) {
                    delete curatorList[i];
                    // Shift elements to fill the gap (preserves order, can be optimized if order not important)
                    for (uint256 j = i; j < curatorList.length - 1; j++) {
                        curatorList[j] = curatorList[j + 1];
                    }
                    curatorList.pop(); // Remove last element (which is now a duplicate or zero address)
                    break;
                }
            }
            emit CuratorRemoved(_curatorAddress);
        }
    }
}
```