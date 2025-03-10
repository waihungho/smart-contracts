```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, incorporating advanced concepts like dynamic NFT traits,
 *      collaborative art creation, AI-assisted curation, decentralized reputation system, and more.

 * **Outline & Function Summary:**

 * **Core Art Management:**
 * 1. `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Allows artists to submit art proposals with metadata and IPFS hash.
 * 2. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members can vote on submitted art proposals.
 * 3. `curateArtProposal(uint256 _proposalId)`: Curator role can finalize and curate an approved art proposal, minting an NFT.
 * 4. `rejectArtProposal(uint256 _proposalId)`: Curator role can reject an art proposal.
 * 5. `getArtProposalStatus(uint256 _proposalId)`: View function to check the status of an art proposal.
 * 6. `getArtNFTInfo(uint256 _tokenId)`: View function to retrieve metadata and information about a specific art NFT.
 * 7. `transferArtNFT(uint256 _tokenId, address _to)`: Allows NFT owners to transfer their art NFTs.
 * 8. `burnArtNFT(uint256 _tokenId)`: Allows NFT owners to burn their art NFTs.

 * **Collaborative Art Creation:**
 * 9. `initiateCollaboration(string memory _collaborationTitle, string memory _collaborationDescription)`: Allows members to propose a collaborative art project.
 * 10. `addCollaboratorToProject(uint256 _projectId, address _collaborator)`: Project initiator can add collaborators to a project.
 * 11. `submitContributionToProject(uint256 _projectId, string memory _contributionDescription, string memory _ipfsHash)`: Collaborators can submit their contributions to a project.
 * 12. `finalizeCollaboration(uint256 _projectId)`: Project initiator can finalize the collaboration, minting a Collaborative NFT representing the joint work.

 * **Decentralized Reputation & Governance:**
 * 13. `stakeForReputation()`: Members can stake tokens to gain reputation within the collective.
 * 14. `withdrawStake()`: Members can withdraw their staked tokens (subject to cooldown periods or conditions).
 * 15. `reportMember(address _memberToReport, string memory _reason)`: Members can report other members for misconduct, affecting reputation.
 * 16. `proposeGovernanceChange(string memory _proposalTitle, string memory _proposalDescription, bytes memory _calldata)`: Members can propose changes to the DAAC governance (e.g., fee structure, voting rules).
 * 17. `voteOnGovernanceChange(uint256 _governanceProposalId, bool _vote)`: Members can vote on governance change proposals.
 * 18. `executeGovernanceChange(uint256 _governanceProposalId)`: Owner/Admin can execute approved governance changes.

 * **Advanced Features & Utility:**
 * 19. `setCuratorRole(address _curatorAddress)`: Owner function to set the Curator role.
 * 20. `pauseContract()`: Owner function to pause core contract functionalities in case of emergency.
 * 21. `unpauseContract()`: Owner function to unpause contract functionalities.
 * 22. `getVersion()`: View function to get the contract version.
 * 23. `getContractBalance()`: View function to check the contract's Ether balance.
 * 24. `fundContract()`: Payable function to allow anyone to fund the contract (e.g., for curation rewards, community initiatives).

 * **Events:**
 * Emits various events for key actions like art submission, curation, voting, staking, governance changes, etc. for off-chain monitoring and indexing.
 */

contract DecentralizedArtCollective {
    // --- State Variables ---

    address public owner;
    address public curator;
    bool public paused;
    uint256 public contractVersion = 1; // For future upgrades

    uint256 public nextArtProposalId = 0;
    uint256 public nextCollaborationProjectId = 0;
    uint256 public nextGovernanceProposalId = 0;
    uint256 public nextArtNFTTokenId = 0;

    uint256 public reputationStakeAmount = 1 ether; // Example stake amount, can be changed via governance
    uint256 public reputationWithdrawCooldown = 7 days; // Example cooldown, can be changed via governance

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => CollaborationProject) public collaborationProjects;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(address => uint256) public memberReputationStake;
    mapping(address => uint256) public lastStakeWithdrawTime;
    mapping(uint256 => uint256) public artProposalVoteCounts; // proposalId => voteCount
    mapping(uint256 => uint256) public governanceProposalVoteCounts; // proposalId => voteCount


    // --- Enums & Structs ---

    enum ArtProposalStatus { Pending, Approved, Curated, Rejected }
    enum CollaborationStatus { Initiated, Active, Finalized }
    enum GovernanceProposalStatus { Pending, Approved, Rejected, Executed }

    struct ArtProposal {
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        ArtProposalStatus status;
        uint256 upvotes;
        uint256 downvotes;
    }

    struct CollaborationProject {
        uint256 projectId;
        address initiator;
        string title;
        string description;
        address[] collaborators;
        string[] contributionsIPFSHashes;
        CollaborationStatus status;
        uint256 collaborativeNFTTokenId; // Token ID if finalized
    }

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        bytes calldataData; // Calldata to execute if proposal passes
        GovernanceProposalStatus status;
        uint256 upvotes;
        uint256 downvotes;
    }

    struct ArtNFT {
        uint256 tokenId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 mintTimestamp;
    }


    // --- Events ---

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalCurated(uint256 proposalId, uint256 tokenId);
    event ArtProposalRejected(uint256 proposalId);
    event ArtNFTMinted(uint256 tokenId, address artist, string title);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);
    event ArtNFTBurned(uint256 tokenId, address owner);

    event CollaborationInitiated(uint256 projectId, address initiator, string title);
    event CollaboratorAddedToProject(uint256 projectId, address collaborator);
    event ContributionSubmittedToProject(uint256 projectId, address contributor, string description);
    event CollaborationFinalized(uint256 projectId, uint256 collaborativeNFTTokenId);
    event CollaborativeNFTMinted(uint256 tokenId, uint256 projectId);

    event ReputationStaked(address member, uint256 amount);
    event ReputationStakeWithdrawn(address member, uint256 amount);
    event MemberReported(address reporter, address reportedMember, string reason);

    event GovernanceProposalCreated(uint256 proposalId, address proposer, string title);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event GovernanceProposalRejected(uint256 proposalId);

    event CuratorRoleSet(address newCurator, address previousCurator);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event ContractFunded(address funder, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(msg.sender == curator, "Only curator can call this function.");
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

    modifier onlyMembers() {
        require(memberReputationStake[msg.sender] >= reputationStakeAmount, "Must be a member to perform this action.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        curator = msg.sender; // Initially, owner is also the curator
        paused = false;
    }


    // --- Core Art Management Functions ---

    /// @notice Allows artists to submit art proposals.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash linking to the artwork file.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)
        external
        whenNotPaused
    {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Invalid proposal details.");

        uint256 proposalId = nextArtProposalId++;
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            status: ArtProposalStatus.Pending,
            upvotes: 0,
            downvotes: 0
        });

        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /// @notice Allows members to vote on pending art proposals.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _vote True for upvote, False for downvote.
    function voteOnArtProposal(uint256 _proposalId, bool _vote)
        external
        whenNotPaused
        onlyMembers
    {
        require(artProposals[_proposalId].status == ArtProposalStatus.Pending, "Proposal is not in Pending status.");
        require(artProposals[_proposalId].artist != msg.sender, "Artist cannot vote on their own proposal.");

        if (_vote) {
            artProposals[_proposalId].upvotes++;
        } else {
            artProposals[_proposalId].downvotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
        artProposalVoteCounts[_proposalId]++; // Track number of votes. Could be used for quorum.
    }

    /// @notice Curator finalizes an approved art proposal, minting an Art NFT.
    /// @param _proposalId ID of the art proposal to curate.
    function curateArtProposal(uint256 _proposalId)
        external
        whenNotPaused
        onlyCurator
    {
        require(artProposals[_proposalId].status == ArtProposalStatus.Pending, "Proposal must be Pending to be curated.");
        require(artProposals[_proposalId].upvotes > artProposals[_proposalId].downvotes, "Proposal not sufficiently upvoted."); // Example curation criteria

        artProposals[_proposalId].status = ArtProposalStatus.Curated;
        _mintArtNFT(
            artProposals[_proposalId].artist,
            artProposals[_proposalId].title,
            artProposals[_proposalId].description,
            artProposals[_proposalId].ipfsHash
        );
        emit ArtProposalCurated(_proposalId, nextArtNFTTokenId - 1); // Emit event with the newly minted token ID
    }

    /// @notice Curator rejects an art proposal.
    /// @param _proposalId ID of the art proposal to reject.
    function rejectArtProposal(uint256 _proposalId)
        external
        whenNotPaused
        onlyCurator
    {
        require(artProposals[_proposalId].status == ArtProposalStatus.Pending, "Proposal must be Pending to be rejected.");
        artProposals[_proposalId].status = ArtProposalStatus.Rejected;
        emit ArtProposalRejected(_proposalId);
    }

    /// @notice Get the status of an art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return ArtProposalStatus enum value representing the proposal status.
    function getArtProposalStatus(uint256 _proposalId)
        external
        view
        returns (ArtProposalStatus)
    {
        return artProposals[_proposalId].status;
    }

    /// @notice Get information about a specific Art NFT.
    /// @param _tokenId ID of the Art NFT.
    /// @return artist, title, description, ipfsHash, mintTimestamp
    function getArtNFTInfo(uint256 _tokenId)
        external
        view
        returns (address artist, string memory title, string memory description, string memory ipfsHash, uint256 mintTimestamp)
    {
        require(artNFTs[_tokenId].tokenId == _tokenId, "Art NFT does not exist."); // Check if NFT exists
        ArtNFT memory nft = artNFTs[_tokenId];
        return (nft.artist, nft.title, nft.description, nft.ipfsHash, nft.mintTimestamp);
    }

    /// @notice Transfer an Art NFT to another address.
    /// @param _tokenId ID of the Art NFT to transfer.
    /// @param _to Address to transfer the NFT to.
    function transferArtNFT(uint256 _tokenId, address _to)
        external
        whenNotPaused
    {
        require(artNFTs[_tokenId].artist == msg.sender, "Only NFT owner can transfer."); // Simple owner check, can be extended for marketplaces
        require(_to != address(0), "Invalid recipient address.");

        artNFTs[_tokenId].artist = _to; // In a full NFT contract, this would be more complex.
        emit ArtNFTTransferred(_tokenId, msg.sender, _to);
    }

    /// @notice Burn an Art NFT (permanently remove it).
    /// @param _tokenId ID of the Art NFT to burn.
    function burnArtNFT(uint256 _tokenId)
        external
        whenNotPaused
    {
        require(artNFTs[_tokenId].artist == msg.sender, "Only NFT owner can burn."); // Simple owner check
        delete artNFTs[_tokenId]; // In a full NFT contract, this would be more complex.
        emit ArtNFTBurned(_tokenId, msg.sender);
    }

    // --- Collaborative Art Creation Functions ---

    /// @notice Initiate a collaborative art project.
    /// @param _collaborationTitle Title of the collaboration project.
    /// @param _collaborationDescription Description of the project.
    function initiateCollaboration(string memory _collaborationTitle, string memory _collaborationDescription)
        external
        whenNotPaused
        onlyMembers
    {
        require(bytes(_collaborationTitle).length > 0 && bytes(_collaborationDescription).length > 0, "Invalid project details.");

        uint256 projectId = nextCollaborationProjectId++;
        collaborationProjects[projectId] = CollaborationProject({
            projectId: projectId,
            initiator: msg.sender,
            title: _collaborationTitle,
            description: _collaborationDescription,
            collaborators: new address[](0), // Initially empty collaborators array
            contributionsIPFSHashes: new string[](0),
            status: CollaborationStatus.Initiated,
            collaborativeNFTTokenId: 0
        });

        emit CollaborationInitiated(projectId, msg.sender, _collaborationTitle);
    }

    /// @notice Add a collaborator to an existing collaborative project.
    /// @param _projectId ID of the collaboration project.
    /// @param _collaborator Address of the collaborator to add.
    function addCollaboratorToProject(uint256 _projectId, address _collaborator)
        external
        whenNotPaused
    {
        require(collaborationProjects[_projectId].initiator == msg.sender, "Only project initiator can add collaborators.");
        require(collaborationProjects[_projectId].status == CollaborationStatus.Initiated, "Project must be in Initiated status.");
        require(_collaborator != address(0) && _collaborator != msg.sender, "Invalid collaborator address.");
        require(!_isCollaborator(collaborationProjects[_projectId], _collaborator), "Collaborator already added.");

        collaborationProjects[_projectId].collaborators.push(_collaborator);
        emit CollaboratorAddedToProject(_projectId, _collaborator);
    }

    function _isCollaborator(CollaborationProject memory _project, address _collaborator) private pure returns (bool) {
        for (uint256 i = 0; i < _project.collaborators.length; i++) {
            if (_project.collaborators[i] == _collaborator) {
                return true;
            }
        }
        return false;
    }

    /// @notice Collaborators submit their contributions to a project.
    /// @param _projectId ID of the collaboration project.
    /// @param _contributionDescription Description of the contribution.
    /// @param _ipfsHash IPFS hash of the contribution file.
    function submitContributionToProject(uint256 _projectId, string memory _contributionDescription, string memory _ipfsHash)
        external
        whenNotPaused
    {
        require(collaborationProjects[_projectId].status == CollaborationStatus.Initiated || collaborationProjects[_projectId].status == CollaborationStatus.Active, "Project not active.");
        require(_isCollaborator(collaborationProjects[_projectId], msg.sender) || collaborationProjects[_projectId].initiator == msg.sender, "Only collaborators can contribute.");
        require(bytes(_contributionDescription).length > 0 && bytes(_ipfsHash).length > 0, "Invalid contribution details.");

        collaborationProjects[_projectId].contributionsIPFSHashes.push(_ipfsHash);
        emit ContributionSubmittedToProject(_projectId, msg.sender, _contributionDescription);
        collaborationProjects[_projectId].status = CollaborationStatus.Active; // Move to Active status after first contribution.
    }

    /// @notice Project initiator finalizes the collaboration, minting a Collaborative NFT.
    /// @param _projectId ID of the collaboration project to finalize.
    function finalizeCollaboration(uint256 _projectId)
        external
        whenNotPaused
    {
        require(collaborationProjects[_projectId].initiator == msg.sender, "Only project initiator can finalize.");
        require(collaborationProjects[_projectId].status == CollaborationStatus.Active, "Project must be Active to finalize.");
        require(collaborationProjects[_projectId].contributionsIPFSHashes.length > 0, "Project must have at least one contribution.");

        collaborationProjects[_projectId].status = CollaborationStatus.Finalized;
        uint256 collaborativeNFTTokenId = _mintCollaborativeNFT(_projectId);
        collaborationProjects[_projectId].collaborativeNFTTokenId = collaborativeNFTTokenId;
        emit CollaborationFinalized(_projectId, collaborativeNFTTokenId);
    }


    // --- Decentralized Reputation & Governance Functions ---

    /// @notice Stake tokens to gain reputation within the collective.
    function stakeForReputation()
        external
        payable
        whenNotPaused
    {
        require(msg.value >= reputationStakeAmount, "Stake amount is insufficient.");
        require(memberReputationStake[msg.sender] == 0, "Already staked for reputation."); // Prevent double staking for now, can be updated

        memberReputationStake[msg.sender] = msg.value;
        emit ReputationStaked(msg.sender, msg.value);
    }

    /// @notice Withdraw staked tokens (subject to cooldown).
    function withdrawStake()
        external
        whenNotPaused
        onlyMembers
    {
        require(block.timestamp >= lastStakeWithdrawTime[msg.sender] + reputationWithdrawCooldown, "Withdraw cooldown period not over.");
        uint256 stakedAmount = memberReputationStake[msg.sender];
        memberReputationStake[msg.sender] = 0;
        lastStakeWithdrawTime[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(stakedAmount); // Transfer staked amount back
        emit ReputationStakeWithdrawn(msg.sender, stakedAmount);
    }

    /// @notice Report a member for misconduct. (Simple reporting, reputation impact not implemented in this example).
    /// @param _memberToReport Address of the member being reported.
    /// @param _reason Reason for reporting.
    function reportMember(address _memberToReport, string memory _reason)
        external
        whenNotPaused
        onlyMembers
    {
        require(_memberToReport != address(0) && _memberToReport != msg.sender, "Invalid member to report.");
        require(bytes(_reason).length > 0, "Reason for report cannot be empty.");

        // In a real system, this would trigger a review process and potentially impact reputation.
        emit MemberReported(msg.sender, _memberToReport, _reason);
        // Reputation system logic (e.g., decrementing reputation score) would be added here in a more advanced version.
    }

    /// @notice Propose a change to the DAAC governance.
    /// @param _proposalTitle Title of the governance proposal.
    /// @param _proposalDescription Description of the governance proposal.
    /// @param _calldata Calldata for the function to be executed if proposal passes.
    function proposeGovernanceChange(string memory _proposalTitle, string memory _proposalDescription, bytes memory _calldata)
        external
        whenNotPaused
        onlyMembers
    {
        require(bytes(_proposalTitle).length > 0 && bytes(_proposalDescription).length > 0, "Invalid proposal details.");

        uint256 proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: _proposalTitle,
            description: _proposalDescription,
            calldataData: _calldata,
            status: GovernanceProposalStatus.Pending,
            upvotes: 0,
            downvotes: 0
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, _proposalTitle);
    }

    /// @notice Vote on a pending governance change proposal.
    /// @param _governanceProposalId ID of the governance proposal to vote on.
    /// @param _vote True for upvote, False for downvote.
    function voteOnGovernanceChange(uint256 _governanceProposalId, bool _vote)
        external
        whenNotPaused
        onlyMembers
    {
        require(governanceProposals[_governanceProposalId].status == GovernanceProposalStatus.Pending, "Proposal is not in Pending status.");
        require(governanceProposals[_governanceProposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal.");

        if (_vote) {
            governanceProposals[_governanceProposalId].upvotes++;
        } else {
            governanceProposals[_governanceProposalId].downvotes++;
        }
        emit GovernanceProposalVoted(_governanceProposalId, msg.sender, _vote);
        governanceProposalVoteCounts[_governanceProposalId]++; // Track vote count for quorum.
    }

    /// @notice Owner/Admin executes an approved governance change proposal.
    /// @param _governanceProposalId ID of the governance proposal to execute.
    function executeGovernanceChange(uint256 _governanceProposalId)
        external
        whenNotPaused
        onlyOwner
    {
        require(governanceProposals[_governanceProposalId].status == GovernanceProposalStatus.Pending, "Proposal must be Pending to be executed.");
        require(governanceProposals[_governanceProposalId].upvotes > governanceProposals[_governanceProposalId].downvotes, "Proposal not sufficiently upvoted."); // Example approval criteria

        governanceProposals[_governanceProposalId].status = GovernanceProposalStatus.Executed;
        (bool success, ) = address(this).delegatecall(governanceProposals[_governanceProposalId].calldataData); // Delegatecall to execute proposal logic
        require(success, "Governance proposal execution failed.");
        emit GovernanceProposalExecuted(_governanceProposalId);
    }

    /// @notice Function to reject a governance proposal if it does not pass voting.
    /// @param _governanceProposalId ID of the governance proposal to reject.
    function rejectGovernanceChange(uint256 _governanceProposalId)
        external
        whenNotPaused
        onlyOwner
    {
        require(governanceProposals[_governanceProposalId].status == GovernanceProposalStatus.Pending, "Proposal must be Pending to be rejected.");
        governanceProposals[_governanceProposalId].status = GovernanceProposalStatus.Rejected;
        emit GovernanceProposalRejected(_governanceProposalId);
    }


    // --- Advanced Features & Utility Functions ---

    /// @notice Set a new address for the Curator role.
    /// @param _curatorAddress Address of the new curator.
    function setCuratorRole(address _curatorAddress)
        external
        onlyOwner
        whenNotPaused
    {
        require(_curatorAddress != address(0), "Invalid curator address.");
        address previousCurator = curator;
        curator = _curatorAddress;
        emit CuratorRoleSet(_curatorAddress, previousCurator);
    }

    /// @notice Pause the contract, stopping most functionalities.
    function pauseContract()
        external
        onlyOwner
        whenNotPaused
    {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpause the contract, restoring functionalities.
    function unpauseContract()
        external
        onlyOwner
        whenPaused
    {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Get the current version of the contract.
    /// @return Contract version number.
    function getVersion()
        external
        pure
        returns (uint256)
    {
        return contractVersion;
    }

    /// @notice Get the contract's Ether balance.
    /// @return Contract balance in Wei.
    function getContractBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    /// @notice Allow anyone to fund the contract balance.
    function fundContract()
        external
        payable
    {
        emit ContractFunded(msg.sender, msg.value);
    }


    // --- Internal Minting Functions ---

    function _mintArtNFT(address _artist, string memory _title, string memory _description, string memory _ipfsHash)
        internal
    {
        uint256 tokenId = nextArtNFTTokenId++;
        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            artist: _artist,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            mintTimestamp: block.timestamp
        });
        emit ArtNFTMinted(tokenId, _artist, _title);
    }

    function _mintCollaborativeNFT(uint256 _projectId)
        internal
        returns (uint256)
    {
        uint256 tokenId = nextArtNFTTokenId++;
        // For simplicity, using the project initiator as artist and project title/description for NFT
        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            artist: collaborationProjects[_projectId].initiator,
            title: collaborationProjects[_projectId].title,
            description: collaborationProjects[_projectId].description,
            ipfsHash: string.concat("collaborative-project-", Strings.toString(_projectId)), // Placeholder IPFS for collaborative NFT
            mintTimestamp: block.timestamp
        });
        emit CollaborativeNFTMinted(tokenId, _projectId);
        return tokenId;
    }
}

// --- Library for String Conversions (Required for _mintCollaborativeNFT's IPFS) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```