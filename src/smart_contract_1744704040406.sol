```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to collaborate,
 * curate exhibitions, manage a treasury, and govern the collective through on-chain voting and reputation.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1.  `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Artists submit art proposals with title, description, and IPFS hash.
 * 2.  `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members vote on submitted art proposals.
 * 3.  `approveArtProposal(uint256 _proposalId)`: Owner function to finalize and approve a proposal after voting threshold is met.
 * 4.  `rejectArtProposal(uint256 _proposalId)`: Owner function to reject a proposal if needed.
 * 5.  `mintArtNFT(uint256 _proposalId)`: Mints an NFT representing the approved artwork to the submitting artist.
 * 6.  `createExhibition(string memory _exhibitionName, uint256[] memory _artNftIds)`: Curators propose and create exhibitions featuring selected Art NFTs.
 * 7.  `voteOnExhibitionProposal(uint256 _exhibitionId, bool _vote)`: Members vote on proposed exhibitions.
 * 8.  `approveExhibition(uint256 _exhibitionId)`: Owner function to approve an exhibition after voting.
 * 9.  `contributeToTreasury()`: Members or anyone can contribute ETH to the collective's treasury.
 * 10. `proposeGrant(address _artistAddress, uint256 _amount, string memory _grantReason)`: Members can propose grants for artists from the treasury.
 * 11. `voteOnGrantProposal(uint256 _grantId, bool _vote)`: Members vote on grant proposals.
 * 12. `approveGrant(uint256 _grantId)`: Owner function to approve and execute a grant after voting.
 * 13. `proposeNewCurator(address _newCuratorAddress, string memory _reason)`: Members can propose new curators.
 * 14. `voteOnCuratorProposal(uint256 _curatorProposalId, bool _vote)`: Members vote on curator proposals.
 * 15. `approveCurator(uint256 _curatorProposalId)`: Owner function to approve a new curator after voting.
 * 16. `removeCurator(address _curatorAddress)`: Owner function to remove a curator.
 * 17. `setVotingThreshold(uint256 _newThreshold)`: Owner function to adjust the voting threshold for proposals.
 * 18. `setMembershipNFT(address _nftContractAddress)`: Owner function to set the Membership NFT contract address.
 * 19. `awardReputationPoints(address _member, uint256 _points, string memory _reason)`: Owner/Curator function to award reputation points to members for contributions.
 * 20. `getMemberReputation(address _member)`: Public function to view a member's reputation points.
 * 21. `withdrawTreasury(address _recipient, uint256 _amount)`: Owner function to withdraw funds from the treasury (for operational costs, etc.).
 * 22. `pauseContract()`: Owner function to pause core functionalities of the contract in case of emergency.
 * 23. `unpauseContract()`: Owner function to resume contract functionalities.

 * **Advanced Concepts Implemented:**
 * - **DAO Governance:**  Utilizes on-chain voting for art proposals, exhibitions, grants, and curator selection, embodying DAO principles.
 * - **Reputation System:**  Implements a basic reputation system to incentivize participation and potentially influence voting power in future iterations (can be expanded).
 * - **Curated Exhibitions:**  Enables the creation of curated digital art exhibitions within the smart contract framework, going beyond simple NFT marketplaces.
 * - **Treasury Management:**  Manages a collective treasury funded by contributions and used for grants, supporting the art ecosystem.
 * - **Membership NFT Integration (Extensible):**  Uses a Membership NFT contract to define collective members, allowing for potentially complex membership models.
 * - **Pause Functionality:**  Includes a pause mechanism for security and emergency situations.
 */

contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    address public owner;
    address public membershipNFTContract;
    address[] public curators;

    uint256 public proposalCounter;
    uint256 public exhibitionCounter;
    uint256 public grantCounter;
    uint256 public curatorProposalCounter;

    uint256 public votingThresholdPercent = 51; // Default voting threshold: 51%

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => GrantProposal) public grantProposals;
    mapping(uint256 => CuratorProposal) public curatorProposals;
    mapping(uint256 => mapping(address => bool)) public artProposalVotes;
    mapping(uint256 => mapping(address => bool)) public exhibitionProposalVotes;
    mapping(uint256 => mapping(address => bool)) public grantProposalVotes;
    mapping(uint256 => mapping(address => bool)) public curatorProposalVotes;
    mapping(address => uint256) public memberReputation;

    bool public paused = false;

    // --- Structs ---

    struct ArtProposal {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool rejected;
        bool exists;
    }

    struct ExhibitionProposal {
        uint256 id;
        address curator;
        string exhibitionName;
        uint256[] artNftIds;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool rejected;
        bool exists;
    }

    struct GrantProposal {
        uint256 id;
        address proposer;
        address artistAddress;
        uint256 amount;
        string grantReason;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool rejected;
        bool exists;
    }

    struct CuratorProposal {
        uint256 id;
        address proposer;
        address newCuratorAddress;
        string reason;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool rejected;
        bool exists;
    }


    // --- Events ---

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId);
    event ArtProposalRejected(uint256 proposalId);
    event ArtNFTMinted(uint256 proposalId, address artist, uint256 nftId);
    event ExhibitionProposed(uint256 exhibitionId, address curator, string exhibitionName);
    event ExhibitionVoted(uint256 exhibitionId, address voter, bool vote);
    event ExhibitionApproved(uint256 exhibitionId);
    event GrantProposed(uint256 grantId, address proposer, address artistAddress, uint256 amount);
    event GrantVoted(uint256 grantId, address voter, bool vote);
    event GrantApproved(uint256 grantId, address artistAddress, uint256 amount);
    event TreasuryContribution(address contributor, uint256 amount);
    event CuratorProposed(uint256 curatorProposalId, address proposer, address newCuratorAddress);
    event CuratorVoted(uint256 curatorProposalId, address voter, bool vote);
    event CuratorApproved(address newCuratorAddress);
    event CuratorRemoved(address curatorAddress);
    event ReputationPointsAwarded(address member, uint256 points, string reason);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "You are not a member of the collective.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator(msg.sender) || msg.sender == owner, "Only curators or owner can call this function.");
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

    constructor(address _membershipNFT) payable {
        owner = msg.sender;
        membershipNFTContract = _membershipNFT;
        curators.push(msg.sender); // Owner is the initial curator
    }

    // --- External Functions ---

    /**
     * @dev Submit an art proposal to the collective.
     * @param _title Title of the artwork.
     * @param _description Description of the artwork.
     * @param _ipfsHash IPFS hash of the artwork's digital asset.
     */
    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash
    ) external onlyMember whenNotPaused {
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            id: proposalCounter,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            rejected: false,
            exists: true
        });
        emit ArtProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    /**
     * @dev Vote on an art proposal.
     * @param _proposalId ID of the art proposal to vote on.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(artProposals[_proposalId].exists, "Proposal does not exist.");
        require(!artProposals[_proposalId].approved && !artProposals[_proposalId].rejected, "Proposal already finalized.");
        require(!artProposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");

        artProposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            artProposals[_proposalId].upvotes++;
        } else {
            artProposals[_proposalId].downvotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Owner function to approve an art proposal after voting threshold is met.
     * @param _proposalId ID of the art proposal to approve.
     */
    function approveArtProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(artProposals[_proposalId].exists, "Proposal does not exist.");
        require(!artProposals[_proposalId].approved && !artProposals[_proposalId].rejected, "Proposal already finalized.");

        uint256 totalVotes = artProposals[_proposalId].upvotes + artProposals[_proposalId].downvotes;
        require(totalVotes > 0, "No votes cast yet."); // To prevent division by zero if no votes are cast
        uint256 approvalPercentage = (artProposals[_proposalId].upvotes * 100) / totalVotes;

        require(approvalPercentage >= votingThresholdPercent, "Voting threshold not met.");

        artProposals[_proposalId].approved = true;
        emit ArtProposalApproved(_proposalId);
    }

    /**
     * @dev Owner function to reject an art proposal.
     * @param _proposalId ID of the art proposal to reject.
     */
    function rejectArtProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(artProposals[_proposalId].exists, "Proposal does not exist.");
        require(!artProposals[_proposalId].approved && !artProposals[_proposalId].rejected, "Proposal already finalized.");

        artProposals[_proposalId].rejected = true;
        emit ArtProposalRejected(_proposalId);
    }

    /**
     * @dev Mints an NFT representing the approved artwork to the submitting artist.
     *      (Placeholder - requires external NFT contract integration or internal NFT logic)
     * @param _proposalId ID of the approved art proposal.
     */
    function mintArtNFT(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(artProposals[_proposalId].exists, "Proposal does not exist.");
        require(artProposals[_proposalId].approved, "Proposal is not approved.");
        require(!artProposals[_proposalId].rejected, "Proposal is rejected.");
        // --- Placeholder for NFT Minting Logic ---
        // In a real application, this would interact with an NFT contract
        // or implement NFT minting within this contract itself.
        // Example:
        // uint256 nftId = _mintNFT(artProposals[_proposalId].artist, artProposals[_proposalId].ipfsHash);
        uint256 nftId = _mockMintNFT(artProposals[_proposalId].artist, artProposals[_proposalId].ipfsHash); // Mock mint for demonstration
        emit ArtNFTMinted(_proposalId, artProposals[_proposalId].artist, nftId);
        // --- End Placeholder ---
    }

    // Mock NFT Minting (for demonstration - replace with actual NFT logic)
    uint256 private mockNFTCounter = 1;
    mapping(uint256 => address) public nftOwners;
    function _mockMintNFT(address _recipient, string memory _ipfsHash) private returns (uint256) {
        uint256 nftId = mockNFTCounter++;
        nftOwners[nftId] = _recipient;
        return nftId;
    }


    /**
     * @dev Propose a new exhibition featuring selected Art NFTs.
     * @param _exhibitionName Name of the exhibition.
     * @param _artNftIds Array of Art NFT IDs to be included in the exhibition.
     */
    function createExhibition(string memory _exhibitionName, uint256[] memory _artNftIds) external onlyCurator whenNotPaused {
        exhibitionCounter++;
        exhibitionProposals[exhibitionCounter] = ExhibitionProposal({
            id: exhibitionCounter,
            curator: msg.sender,
            exhibitionName: _exhibitionName,
            artNftIds: _artNftIds,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            rejected: false,
            exists: true
        });
        emit ExhibitionProposed(exhibitionCounter, msg.sender, _exhibitionName);
    }

    /**
     * @dev Vote on an exhibition proposal.
     * @param _exhibitionId ID of the exhibition proposal.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnExhibitionProposal(uint256 _exhibitionId, bool _vote) external onlyMember whenNotPaused {
        require(exhibitionProposals[_exhibitionId].exists, "Exhibition proposal does not exist.");
        require(!exhibitionProposals[_exhibitionId].approved && !exhibitionProposals[_exhibitionId].rejected, "Exhibition proposal already finalized.");
        require(!exhibitionProposalVotes[_exhibitionId][msg.sender], "You have already voted on this exhibition proposal.");

        exhibitionProposalVotes[_exhibitionId][msg.sender] = true;
        if (_vote) {
            exhibitionProposals[_exhibitionId].upvotes++;
        } else {
            exhibitionProposals[_exhibitionId].downvotes++;
        }
        emit ExhibitionVoted(_exhibitionId, msg.sender, _vote);
    }

    /**
     * @dev Owner function to approve an exhibition proposal after voting threshold is met.
     * @param _exhibitionId ID of the exhibition proposal to approve.
     */
    function approveExhibition(uint256 _exhibitionId) external onlyOwner whenNotPaused {
        require(exhibitionProposals[_exhibitionId].exists, "Exhibition proposal does not exist.");
        require(!exhibitionProposals[_exhibitionId].approved && !exhibitionProposals[_exhibitionId].rejected, "Exhibition proposal already finalized.");

        uint256 totalVotes = exhibitionProposals[_exhibitionId].upvotes + exhibitionProposals[_exhibitionId].downvotes;
        require(totalVotes > 0, "No votes cast yet."); // To prevent division by zero if no votes are cast
        uint256 approvalPercentage = (exhibitionProposals[_exhibitionId].upvotes * 100) / totalVotes;

        require(approvalPercentage >= votingThresholdPercent, "Voting threshold not met.");

        exhibitionProposals[_exhibitionId].approved = true;
        emit ExhibitionApproved(_exhibitionId);
    }


    /**
     * @dev Allows anyone to contribute ETH to the collective's treasury.
     */
    function contributeToTreasury() external payable whenNotPaused {
        emit TreasuryContribution(msg.sender, msg.value);
    }

    /**
     * @dev Propose a grant for an artist from the treasury.
     * @param _artistAddress Address of the artist receiving the grant.
     * @param _amount Amount of ETH to grant.
     * @param _grantReason Reason for the grant.
     */
    function proposeGrant(address _artistAddress, uint256 _amount, string memory _grantReason) external onlyMember whenNotPaused {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        grantCounter++;
        grantProposals[grantCounter] = GrantProposal({
            id: grantCounter,
            proposer: msg.sender,
            artistAddress: _artistAddress,
            amount: _amount,
            grantReason: _grantReason,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            rejected: false,
            exists: true
        });
        emit GrantProposed(grantCounter, msg.sender, _artistAddress, _amount);
    }

    /**
     * @dev Vote on a grant proposal.
     * @param _grantId ID of the grant proposal.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnGrantProposal(uint256 _grantId, bool _vote) external onlyMember whenNotPaused {
        require(grantProposals[_grantId].exists, "Grant proposal does not exist.");
        require(!grantProposals[_grantId].approved && !grantProposals[_grantId].rejected, "Grant proposal already finalized.");
        require(!grantProposalVotes[_grantId][msg.sender], "You have already voted on this grant proposal.");

        grantProposalVotes[_grantId][msg.sender] = true;
        if (_vote) {
            grantProposals[_grantId].upvotes++;
        } else {
            grantProposals[_grantId].downvotes++;
        }
        emit GrantVoted(_grantId, msg.sender, _vote);
    }

    /**
     * @dev Owner function to approve a grant proposal and send ETH to the artist.
     * @param _grantId ID of the grant proposal to approve.
     */
    function approveGrant(uint256 _grantId) external onlyOwner whenNotPaused {
        require(grantProposals[_grantId].exists, "Grant proposal does not exist.");
        require(!grantProposals[_grantId].approved && !grantProposals[_grantId].rejected, "Grant proposal already finalized.");

        uint256 totalVotes = grantProposals[_grantId].upvotes + grantProposals[_grantId].downvotes;
        require(totalVotes > 0, "No votes cast yet."); // To prevent division by zero if no votes are cast
        uint256 approvalPercentage = (grantProposals[_grantId].upvotes * 100) / totalVotes;

        require(approvalPercentage >= votingThresholdPercent, "Voting threshold not met.");
        require(address(this).balance >= grantProposals[_grantId].amount, "Insufficient treasury balance to execute grant.");

        grantProposals[_grantId].approved = true;
        payable(grantProposals[_grantId].artistAddress).transfer(grantProposals[_grantId].amount);
        emit GrantApproved(grantProposals[_grantId].artistAddress, grantProposals[_grantId].amount);
    }

    /**
     * @dev Propose a new curator to be added to the collective.
     * @param _newCuratorAddress Address of the new curator to propose.
     * @param _reason Reason for proposing the new curator.
     */
    function proposeNewCurator(address _newCuratorAddress, string memory _reason) external onlyMember whenNotPaused {
        require(_newCuratorAddress != address(0), "Invalid curator address.");
        require(!isCurator(_newCuratorAddress), "Address is already a curator.");
        curatorProposalCounter++;
        curatorProposals[curatorProposalCounter] = CuratorProposal({
            id: curatorProposalCounter,
            proposer: msg.sender,
            newCuratorAddress: _newCuratorAddress,
            reason: _reason,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            rejected: false,
            exists: true
        });
        emit CuratorProposed(curatorProposalCounter, msg.sender, _newCuratorAddress);
    }

    /**
     * @dev Vote on a curator proposal.
     * @param _curatorProposalId ID of the curator proposal.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnCuratorProposal(uint256 _curatorProposalId, bool _vote) external onlyMember whenNotPaused {
        require(curatorProposals[_curatorProposalId].exists, "Curator proposal does not exist.");
        require(!curatorProposals[_curatorProposalId].approved && !curatorProposals[_curatorId].rejected, "Curator proposal already finalized.");
        require(!curatorProposalVotes[_curatorProposalId][msg.sender], "You have already voted on this curator proposal.");

        curatorProposalVotes[_curatorProposalId][msg.sender] = true;
        if (_vote) {
            curatorProposals[_curatorProposalId].upvotes++;
        } else {
            curatorProposals[_curatorProposalId].downvotes++;
        }
        emit CuratorVoted(_curatorProposalId, msg.sender, _vote);
    }

    /**
     * @dev Owner function to approve a curator proposal and add the new curator.
     * @param _curatorProposalId ID of the curator proposal to approve.
     */
    function approveCurator(uint256 _curatorProposalId) external onlyOwner whenNotPaused {
        require(curatorProposals[_curatorProposalId].exists, "Curator proposal does not exist.");
        require(!curatorProposals[_curatorProposalId].approved && !curatorProposals[_curatorProposalId].rejected, "Curator proposal already finalized.");

        uint256 totalVotes = curatorProposals[_curatorProposalId].upvotes + curatorProposals[_curatorProposalId].downvotes;
        require(totalVotes > 0, "No votes cast yet."); // To prevent division by zero if no votes are cast
        uint256 approvalPercentage = (curatorProposals[_curatorProposalId].upvotes * 100) / totalVotes;

        require(approvalPercentage >= votingThresholdPercent, "Voting threshold not met.");

        curatorProposals[_curatorProposalId].approved = true;
        curators.push(curatorProposals[_curatorProposalId].newCuratorAddress);
        emit CuratorApproved(curatorProposals[_curatorProposalId].newCuratorAddress);
    }

    /**
     * @dev Owner function to remove a curator from the collective.
     * @param _curatorAddress Address of the curator to remove.
     */
    function removeCurator(address _curatorAddress) external onlyOwner whenNotPaused {
        require(_curatorAddress != owner, "Cannot remove the owner as curator.");
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _curatorAddress) {
                delete curators[i];
                // To maintain array integrity, shift elements after removal (less gas efficient for large arrays, consider linked list in real scenarios)
                for (uint256 j = i; j < curators.length - 1; j++) {
                    curators[j] = curators[j + 1];
                }
                curators.pop(); // Remove the last element (which is now a duplicate or zero address)
                emit CuratorRemoved(_curatorAddress);
                return;
            }
        }
        revert("Curator address not found.");
    }

    /**
     * @dev Owner function to set the voting threshold percentage.
     * @param _newThreshold New voting threshold percentage (e.g., 51 for 51%).
     */
    function setVotingThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0 && _newThreshold <= 100, "Voting threshold must be between 1 and 100.");
        votingThresholdPercent = _newThreshold;
    }

    /**
     * @dev Owner function to set the Membership NFT contract address.
     * @param _nftContractAddress Address of the Membership NFT contract.
     */
    function setMembershipNFT(address _nftContractAddress) external onlyOwner {
        require(_nftContractAddress != address(0), "Invalid NFT contract address.");
        membershipNFTContract = _nftContractAddress;
    }

    /**
     * @dev Owner or Curator function to award reputation points to a member.
     * @param _member Address of the member to award points to.
     * @param _points Number of reputation points to award.
     * @param _reason Reason for awarding reputation points.
     */
    function awardReputationPoints(address _member, uint256 _points, string memory _reason) external onlyCurator {
        memberReputation[_member] += _points;
        emit ReputationPointsAwarded(_member, _points, _reason);
    }

    /**
     * @dev Public function to get a member's reputation points.
     * @param _member Address of the member.
     * @return Reputation points of the member.
     */
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /**
     * @dev Owner function to withdraw funds from the treasury.
     * @param _recipient Address to receive the withdrawn funds.
     * @param _amount Amount of ETH to withdraw.
     */
    function withdrawTreasury(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address.");
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /**
     * @dev Owner function to pause the contract, disabling core functionalities.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Owner function to unpause the contract, resuming core functionalities.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }


    // --- View/Pure Functions ---

    /**
     * @dev Checks if an address is a member of the collective based on Membership NFT ownership.
     *      (Placeholder - requires external Membership NFT contract interaction)
     * @param _address Address to check for membership.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _address) public view returns (bool) {
        // --- Placeholder for Membership NFT Check ---
        // In a real application, this would interact with the Membership NFT contract
        // to check if the address holds a Membership NFT.
        // Example (assuming a simple ERC721-like contract with balanceOf function):
        // IERC721 membershipNFT = IERC721(membershipNFTContract);
        // return membershipNFT.balanceOf(_address) > 0;
        return _mockIsMember(_address); // Mock membership check for demonstration
        // --- End Placeholder ---
    }

    // Mock Membership Check (for demonstration - replace with actual NFT check)
    function _mockIsMember(address _address) private pure returns (bool) {
        // For this example, we'll just mock membership as true for any non-zero address
        return _address != address(0);
    }


    /**
     * @dev Checks if an address is a curator.
     * @param _address Address to check.
     * @return True if the address is a curator, false otherwise.
     */
    function isCurator(address _address) public view returns (bool) {
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _address) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Gets the current treasury balance of the contract.
     * @return Current treasury balance in ETH.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the details of an art proposal.
     * @param _proposalId ID of the art proposal.
     * @return ArtProposal struct containing proposal details.
     */
    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        require(artProposals[_proposalId].exists, "Proposal does not exist.");
        return artProposals[_proposalId];
    }

    /**
     * @dev Gets the details of an exhibition proposal.
     * @param _exhibitionId ID of the exhibition proposal.
     * @return ExhibitionProposal struct containing proposal details.
     */
    function getExhibitionProposalDetails(uint256 _exhibitionId) external view returns (ExhibitionProposal memory) {
        require(exhibitionProposals[_exhibitionId].exists, "Exhibition proposal does not exist.");
        return exhibitionProposals[_exhibitionId];
    }

    /**
     * @dev Gets the details of a grant proposal.
     * @param _grantId ID of the grant proposal.
     * @return GrantProposal struct containing grant proposal details.
     */
    function getGrantProposalDetails(uint256 _grantId) external view returns (GrantProposal memory) {
        require(grantProposals[_grantId].exists, "Grant proposal does not exist.");
        return grantProposals[_grantId];
    }

    /**
     * @dev Gets the details of a curator proposal.
     * @param _curatorProposalId ID of the curator proposal.
     * @return CuratorProposal struct containing curator proposal details.
     */
    function getCuratorProposalDetails(uint256 _curatorProposalId) external view returns (CuratorProposal memory) {
        require(curatorProposals[_curatorProposalId].exists, "Curator proposal does not exist.");
        return curatorProposals[_curatorProposalId];
    }
}

// --- Optional Interface for Membership NFT (Example - Replace with your actual NFT contract interface if needed) ---
// interface IERC721 {
//     function balanceOf(address owner) external view returns (uint256 balance);
//     // ... other relevant ERC721 functions ...
// }
```