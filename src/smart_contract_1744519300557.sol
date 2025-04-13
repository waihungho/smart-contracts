```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery
 * @author Bard (Example Smart Contract - Not for Production)
 * @notice This smart contract implements a Decentralized Autonomous Art Gallery where the community governs the artwork displayed and exhibitions.
 *
 * **Outline & Function Summary:**
 *
 * **Gallery Management & Setup:**
 * 1. `constructor(address _galleryToken)`: Initializes the gallery with a governance token address.
 * 2. `setGovernanceParameters(uint256 _minStakeForProposal, uint256 _proposalVoteDuration, uint256 _exhibitionVoteDuration, uint256 _minQuorum)`: Allows the gallery owner to set governance parameters.
 * 3. `setGalleryToken(address _newGalleryToken)`: Allows the gallery owner to change the governance token address.
 * 4. `withdrawGalleryFunds(address payable _recipient)`: Allows the gallery owner to withdraw any ETH balance in the contract (for maintenance, etc.).
 *
 * **Artwork Submission & Curation:**
 * 5. `submitArtworkProposal(string memory _title, string memory _artist, string memory _description, string memory _ipfsHash)`: Allows token holders to propose new artworks for display.
 * 6. `voteOnArtworkProposal(uint256 _proposalId, bool _support)`: Allows token holders to vote on artwork proposals.
 * 7. `finalizeArtworkProposal(uint256 _proposalId)`:  Finalizes an artwork proposal after voting, adds artwork if approved.
 * 8. `removeArtwork(uint256 _artworkId)`: Allows the gallery owner to remove an artwork (e.g., for content policy reasons).
 * 9. `getArtworkDetails(uint256 _artworkId) view returns (string memory title, string memory artist, string memory description, string memory ipfsHash, bool isDisplayed)`: Retrieves details of a specific artwork.
 * 10. `getAllArtworkIDs() view returns (uint256[] memory)`: Returns a list of all artwork IDs currently in the gallery.
 * 11. `getRandomArtwork() view returns (uint256)`: Returns a random artwork ID from the displayed artworks (demonstrates on-chain randomness concept).
 *
 * **Exhibition Management & Scheduling:**
 * 12. `proposeExhibition(string memory _exhibitionTitle, string memory _theme, uint256 _startTime, uint256 _endTime, uint256[] memory _artworkIds)`: Allows token holders to propose exhibitions.
 * 13. `voteOnExhibitionProposal(uint256 _proposalId, bool _support)`: Allows token holders to vote on exhibition proposals.
 * 14. `finalizeExhibitionProposal(uint256 _proposalId)`: Finalizes an exhibition proposal, schedules the exhibition if approved.
 * 15. `cancelExhibition(uint256 _exhibitionId)`: Allows the gallery owner to cancel a scheduled exhibition (emergency case).
 * 16. `getActiveExhibitionIds() view returns (uint256[] memory)`: Returns a list of IDs for currently active exhibitions.
 * 17. `getExhibitionDetails(uint256 _exhibitionId) view returns (string memory title, string memory theme, uint256 startTime, uint256 endTime, uint256[] memory artworkIds, bool isActive)`: Retrieves details of a specific exhibition.
 *
 * **Governance & Token Interaction:**
 * 18. `getVotingPower(address _voter) view returns (uint256)`:  (Placeholder) Returns voting power based on token holdings (in a real system, would interact with the gallery token contract).
 * 19. `stakeTokens(uint256 _amount)`: (Placeholder/Conceptual) Allows users to stake tokens for governance participation (more advanced).
 * 20. `unstakeTokens(uint256 _amount)`: (Placeholder/Conceptual) Allows users to unstake tokens.
 *
 * **Utility & Information:**
 * 21. `getProposalDetails(uint256 _proposalId) view returns (Proposal memory)`: Returns detailed information about a proposal.
 * 22. `getGalleryBalance() view returns (uint256)`: Returns the ETH balance of the contract.
 */
contract DecentralizedAutonomousArtGallery {
    // --- State Variables ---

    address public galleryOwner;
    address public galleryToken; // Address of the governance token contract (ERC20 or similar)

    struct Artwork {
        string title;
        string artist;
        string description;
        string ipfsHash; // IPFS hash for artwork media
        bool isDisplayed;
        uint256 addedTimestamp;
    }
    mapping(uint256 => Artwork) public artworks;
    uint256 public artworkCount;

    struct Proposal {
        enum ProposalType { ARTWORK_SUBMISSION, EXHIBITION }
        ProposalType proposalType;
        address proposer;
        string title; // Proposal title (e.g., Artwork title, Exhibition title)
        string description; // Proposal description
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool approved;
        uint256[] artworkIds; // For exhibition proposals, list of artwork IDs
        string ipfsHash; // For artwork proposals
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => hasVoted

    struct Exhibition {
        string title;
        string theme;
        uint256 startTime;
        uint256 endTime;
        uint256[] artworkIds;
        bool isActive;
    }
    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public exhibitionCount;

    uint256 public minStakeForProposal; // Minimum tokens required to submit a proposal
    uint256 public proposalVoteDuration; // Duration of artwork submission proposal voting in seconds
    uint256 public exhibitionVoteDuration; // Duration of exhibition proposal voting in seconds
    uint256 public minQuorum; // Minimum percentage of total possible votes required for quorum (e.g., 50 for 50%)

    // --- Events ---
    event GovernanceParametersSet(uint256 minStake, uint256 proposalVoteDuration, uint256 exhibitionVoteDuration, uint256 minQuorum);
    event GalleryTokenChanged(address oldToken, address newToken);
    event ArtworkProposed(uint256 proposalId, address proposer, string title);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtworkProposalFinalized(uint256 proposalId, bool approved, uint256 artworkId);
    event ArtworkRemoved(uint256 artworkId);
    event ExhibitionProposed(uint256 proposalId, address proposer, string title);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool support);
    event ExhibitionProposalFinalized(uint256 proposalId, bool approved, uint256 exhibitionId);
    event ExhibitionCancelled(uint256 exhibitionId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == galleryOwner, "Only owner can call this function.");
        _;
    }

    modifier onlyTokenHolders() {
        require(getVotingPower(msg.sender) > 0, "Must hold governance tokens to participate.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].finalized == false, "Proposal is already finalized.");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended.");
        _;
    }

    modifier exhibitionActive(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(block.timestamp >= exhibitions[_exhibitionId].startTime && block.timestamp <= exhibitions[_exhibitionId].endTime, "Exhibition is not currently running.");
        _;
    }

    // --- Constructor ---
    constructor(address _galleryToken) payable {
        galleryOwner = msg.sender;
        galleryToken = _galleryToken;
        minStakeForProposal = 10; // Example initial value
        proposalVoteDuration = 3 days; // Example initial value
        exhibitionVoteDuration = 7 days; // Example initial value
        minQuorum = 50; // Example initial value - 50% quorum
    }

    // --- Gallery Management & Setup Functions ---

    /**
     * @dev Sets governance parameters for proposal submission and voting. Only callable by the gallery owner.
     * @param _minStakeForProposal Minimum tokens required to submit a proposal.
     * @param _proposalVoteDuration Duration of artwork submission proposal voting in seconds.
     * @param _exhibitionVoteDuration Duration of exhibition proposal voting in seconds.
     * @param _minQuorum Minimum percentage of total possible votes required for quorum (e.g., 50 for 50%).
     */
    function setGovernanceParameters(uint256 _minStakeForProposal, uint256 _proposalVoteDuration, uint256 _exhibitionVoteDuration, uint256 _minQuorum) external onlyOwner {
        minStakeForProposal = _minStakeForProposal;
        proposalVoteDuration = _proposalVoteDuration;
        exhibitionVoteDuration = _exhibitionVoteDuration;
        minQuorum = _minQuorum;
        emit GovernanceParametersSet(_minStakeForProposal, _proposalVoteDuration, _exhibitionVoteDuration, _minQuorum);
    }

    /**
     * @dev Allows the gallery owner to change the address of the governance token.
     * @param _newGalleryToken The address of the new governance token contract.
     */
    function setGalleryToken(address _newGalleryToken) external onlyOwner {
        emit GalleryTokenChanged(galleryToken, _newGalleryToken);
        galleryToken = _newGalleryToken;
    }

    /**
     * @dev Allows the gallery owner to withdraw the ETH balance of the contract.
     * @param _recipient The address to which the funds will be transferred.
     */
    function withdrawGalleryFunds(address payable _recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        (bool success, ) = _recipient.call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    // --- Artwork Submission & Curation Functions ---

    /**
     * @dev Allows token holders to submit an artwork proposal.
     * @param _title Title of the artwork.
     * @param _artist Artist of the artwork.
     * @param _description Description of the artwork.
     * @param _ipfsHash IPFS hash pointing to the artwork's media.
     */
    function submitArtworkProposal(string memory _title, string memory _artist, string memory _description, string memory _ipfsHash) external onlyTokenHolders {
        require(getVotingPower(msg.sender) >= minStakeForProposal, "Insufficient stake to propose.");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposalType: Proposal.ProposalType.ARTWORK_SUBMISSION,
            proposer: msg.sender,
            title: _title,
            description: _description,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVoteDuration,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false,
            artworkIds: new uint256[](0), // Not used for artwork proposals
            ipfsHash: _ipfsHash
        });

        emit ArtworkProposed(proposalCount, msg.sender, _title);
    }

    /**
     * @dev Allows token holders to vote on an artwork proposal.
     * @param _proposalId ID of the proposal to vote on.
     * @param _support True for yes vote, false for no vote.
     */
    function voteOnArtworkProposal(uint256 _proposalId, bool _support) external onlyTokenHolders proposalActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true;

        if (_support) {
            proposals[_proposalId].yesVotes += getVotingPower(msg.sender);
        } else {
            proposals[_proposalId].noVotes += getVotingPower(msg.sender);
        }
        emit ArtworkProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Finalizes an artwork proposal after the voting period. Adds the artwork to the gallery if approved.
     * @param _proposalId ID of the proposal to finalize.
     */
    function finalizeArtworkProposal(uint256 _proposalId) external {
        require(proposals[_proposalId].finalized == false, "Proposal already finalized.");
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period is not over yet.");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        uint256 quorumVotesNeeded = (getTotalVotingPower() * minQuorum) / 100; // Example quorum calculation

        if (totalVotes >= quorumVotesNeeded && proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes) {
            proposals[_proposalId].approved = true;
            artworkCount++;
            artworks[artworkCount] = Artwork({
                title: proposals[_proposalId].title,
                artist: proposals[_proposalId].description, // Using description as artist for simplicity in example
                description: proposals[_proposalId].description,
                ipfsHash: proposals[_proposalId].ipfsHash,
                isDisplayed: true,
                addedTimestamp: block.timestamp
            });
            emit ArtworkProposalFinalized(_proposalId, true, artworkCount);
        } else {
            proposals[_proposalId].approved = false;
            emit ArtworkProposalFinalized(_proposalId, false, 0);
        }
        proposals[_proposalId].finalized = true;
    }

    /**
     * @dev Allows the gallery owner to remove an artwork from display.
     * @param _artworkId ID of the artwork to remove.
     */
    function removeArtwork(uint256 _artworkId) external onlyOwner {
        require(artworks[_artworkId].isDisplayed, "Artwork is not currently displayed.");
        artworks[_artworkId].isDisplayed = false;
        emit ArtworkRemoved(_artworkId);
    }

    /**
     * @dev Retrieves details of a specific artwork.
     * @param _artworkId ID of the artwork.
     * @return title Title of the artwork.
     * @return artist Artist of the artwork.
     * @return description Description of the artwork.
     * @return ipfsHash IPFS hash of the artwork media.
     * @return isDisplayed Boolean indicating if the artwork is currently displayed.
     */
    function getArtworkDetails(uint256 _artworkId) public view returns (string memory title, string memory artist, string memory description, string memory ipfsHash, bool isDisplayed) {
        Artwork storage artwork = artworks[_artworkId];
        return (artwork.title, artwork.artist, artwork.description, artwork.ipfsHash, artwork.isDisplayed);
    }

    /**
     * @dev Returns a list of all artwork IDs currently in the gallery.
     * @return An array of artwork IDs.
     */
    function getAllArtworkIDs() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](artworkCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (artworks[i].isDisplayed) {
                ids[index] = i;
                index++;
            }
        }
        // Resize the array to remove extra elements if fewer artworks are displayed than total created.
        assembly {
            mstore(ids, index) // Update the length of the array in memory
        }
        return ids;
    }

    /**
     * @dev Returns a random artwork ID from the currently displayed artworks.
     *      Demonstrates a basic concept of on-chain randomness (for more secure randomness, use Chainlink VRF).
     * @return A random artwork ID or 0 if no artworks are displayed.
     */
    function getRandomArtwork() public view returns (uint256) {
        uint256[] memory displayedArtworkIds = getAllArtworkIDs();
        if (displayedArtworkIds.length == 0) {
            return 0; // No artworks displayed
        }
        uint256 randomIndex = uint256(blockhash(block.number - 1)) % displayedArtworkIds.length; // Basic on-chain randomness (not highly secure)
        return displayedArtworkIds[randomIndex];
    }

    // --- Exhibition Management & Scheduling Functions ---

    /**
     * @dev Allows token holders to propose an exhibition.
     * @param _exhibitionTitle Title of the exhibition.
     * @param _theme Theme of the exhibition.
     * @param _startTime Unix timestamp for the exhibition start time.
     * @param _endTime Unix timestamp for the exhibition end time.
     * @param _artworkIds Array of artwork IDs to be included in the exhibition.
     */
    function proposeExhibition(string memory _exhibitionTitle, string memory _theme, uint256 _startTime, uint256 _endTime, uint256[] memory _artworkIds) external onlyTokenHolders {
        require(getVotingPower(msg.sender) >= minStakeForProposal, "Insufficient stake to propose.");
        require(_startTime < _endTime, "Exhibition start time must be before end time.");
        require(_startTime > block.timestamp, "Exhibition start time must be in the future.");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposalType: Proposal.ProposalType.EXHIBITION,
            proposer: msg.sender,
            title: _exhibitionTitle,
            description: _theme, // Using description for theme for simplicity
            startTime: block.timestamp,
            endTime: block.timestamp + exhibitionVoteDuration,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false,
            artworkIds: _artworkIds,
            ipfsHash: "" // Not used for exhibition proposals
        });

        emit ExhibitionProposed(proposalCount, msg.sender, _exhibitionTitle);
    }

    /**
     * @dev Allows token holders to vote on an exhibition proposal.
     * @param _proposalId ID of the exhibition proposal to vote on.
     * @param _support True for yes vote, false for no vote.
     */
    function voteOnExhibitionProposal(uint256 _proposalId, bool _support) external onlyTokenHolders proposalActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true;

        if (_support) {
            proposals[_proposalId].yesVotes += getVotingPower(msg.sender);
        } else {
            proposals[_proposalId].noVotes += getVotingPower(msg.sender);
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Finalizes an exhibition proposal after the voting period. Schedules the exhibition if approved.
     * @param _proposalId ID of the exhibition proposal to finalize.
     */
    function finalizeExhibitionProposal(uint256 _proposalId) external {
        require(proposals[_proposalId].finalized == false, "Proposal already finalized.");
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period is not over yet.");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        uint256 quorumVotesNeeded = (getTotalVotingPower() * minQuorum) / 100;

        if (totalVotes >= quorumVotesNeeded && proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes) {
            proposals[_proposalId].approved = true;
            exhibitionCount++;
            exhibitions[exhibitionCount] = Exhibition({
                title: proposals[_proposalId].title,
                theme: proposals[_proposalId].description,
                startTime: proposals[_proposalId].artworkIds[0], // Reusing artworkIds[0] for startTime, artworkIds[1] for endTime in proposal struct due to struct limitations in example, ideally use separate fields in Proposal struct for time in real contract.
                endTime: proposals[_proposalId].artworkIds[1],
                artworkIds: proposals[_proposalId].artworkIds,
                isActive: true
            });
            emit ExhibitionProposalFinalized(_proposalId, true, exhibitionCount);
        } else {
            proposals[_proposalId].approved = false;
            emit ExhibitionProposalFinalized(_proposalId, false, 0);
        }
        proposals[_proposalId].finalized = true;
    }

    /**
     * @dev Allows the gallery owner to cancel a scheduled exhibition.
     * @param _exhibitionId ID of the exhibition to cancel.
     */
    function cancelExhibition(uint256 _exhibitionId) external onlyOwner {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not currently active.");
        exhibitions[_exhibitionId].isActive = false;
        emit ExhibitionCancelled(_exhibitionId);
    }

    /**
     * @dev Returns a list of IDs for currently active exhibitions.
     * @return An array of exhibition IDs.
     */
    function getActiveExhibitionIds() public view returns (uint256[] memory) {
        uint256[] memory activeExhibitionIds = new uint256[](exhibitionCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= exhibitionCount; i++) {
            if (exhibitions[i].isActive && block.timestamp >= exhibitions[i].startTime && block.timestamp <= exhibitions[i].endTime) {
                activeExhibitionIds[index] = i;
                index++;
            }
        }
        // Resize array if needed
        assembly {
            mstore(activeExhibitionIds, index)
        }
        return activeExhibitionIds;
    }

    /**
     * @dev Retrieves details of a specific exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @return title Title of the exhibition.
     * @return theme Theme of the exhibition.
     * @return startTime Unix timestamp for exhibition start time.
     * @return endTime Unix timestamp for exhibition end time.
     * @return artworkIds Array of artwork IDs in the exhibition.
     * @return isActive Boolean indicating if the exhibition is currently active.
     */
    function getExhibitionDetails(uint256 _exhibitionId) public view returns (string memory title, string memory theme, uint256 startTime, uint256 endTime, uint256[] memory artworkIds, bool isActive) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        return (exhibition.title, exhibition.theme, exhibition.startTime, exhibition.endTime, exhibition.artworkIds, exhibition.isActive);
    }


    // --- Governance & Token Interaction Functions ---

    /**
     * @dev (Placeholder) Returns the voting power of an address based on their token holdings.
     *      In a real implementation, this would interact with the galleryToken contract to get the balance.
     * @param _voter Address of the voter.
     * @return Voting power of the voter.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        // **Important: In a real application, replace this with actual token balance retrieval from galleryToken contract.**
        // Example: return IERC20(galleryToken).balanceOf(_voter);
        // For this example, assume every token holder has a voting power of 1 (simplified).
        if (address(0) != galleryToken) { // Basic check if token address is set
             // Placeholder - Replace with actual token balance check
             return 1; // Assume token holders have voting power
        } else {
            return 0; // No voting power if no token contract set or not holding tokens (in a real impl)
        }
    }

     /**
     * @dev (Placeholder) Returns the total voting power in the system.
     *      In a real implementation, this would likely be based on the total supply or circulating supply of the governance token.
     * @return Total voting power.
     */
    function getTotalVotingPower() public view returns (uint256) {
        // **Important: In a real application, replace this with actual total voting power calculation based on token supply.**
        // Example: return IERC20(galleryToken).totalSupply();
        // For this example, assuming a simplified estimation.
        return 1000; // Placeholder - Replace with actual total voting power calculation
    }


    /**
     * @dev (Placeholder/Conceptual) Allows users to stake governance tokens for increased governance participation (more advanced feature).
     *      This is a simplified placeholder and would require a more complex implementation in a real system, including token transfer logic and staking state management.
     * @param _amount Amount of tokens to stake.
     */
    function stakeTokens(uint256 _amount) external onlyTokenHolders {
        // In a real implementation, this would involve:
        // 1. Transferring tokens from the user to the contract (using ERC20.transferFrom).
        // 2. Updating the user's staking balance in the contract's state.
        // 3. Potentially increasing voting power based on staked amount and duration.
        require(_amount > 0, "Stake amount must be greater than zero.");
        // Placeholder logic - In a real system, implement token transfer and staking state management.
        // ... (staking logic would go here) ...
        // For now, just emitting an event as a conceptual example:
        // emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev (Placeholder/Conceptual) Allows users to unstake governance tokens.
     *      This is a simplified placeholder and would require a more complex implementation in a real system, including token transfer logic and unstaking state management.
     * @param _amount Amount of tokens to unstake.
     */
    function unstakeTokens(uint256 _amount) external onlyTokenHolders {
        // In a real implementation, this would involve:
        // 1. Checking if the user has sufficient staked tokens.
        // 2. Transferring tokens back to the user from the contract (using ERC20.transfer).
        // 3. Updating the user's staking balance in the contract's state.
        require(_amount > 0, "Unstake amount must be greater than zero.");
        // Placeholder logic - In a real system, implement token transfer and unstaking state management.
        // ... (unstaking logic would go here) ...
        // For now, just emitting an event as a conceptual example:
        // emit TokensUnstaked(msg.sender, _amount);
    }

    // --- Utility & Information Functions ---

    /**
     * @dev Returns detailed information about a proposal.
     * @param _proposalId ID of the proposal.
     * @return Proposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Returns the ETH balance of the contract.
     * @return The ETH balance in wei.
     */
    function getGalleryBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```