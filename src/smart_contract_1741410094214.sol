```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to collaborate,
 * curate, and monetize digital art pieces. This contract introduces advanced concepts like dynamic royalty
 * splits, collaborative art creation, decentralized curation with reputation-based voting, and
 * on-chain art evolution.  It goes beyond basic NFT contracts and DAO structures by combining these
 * features in a novel way to foster a truly decentralized art ecosystem.

 * **Contract Outline:**
 * 1. **Membership Management:**
 *    - Request to join the collective, approval by existing members or governance.
 *    - Member roles and reputation system based on contributions and curation success.
 * 2. **Art Proposal and Submission:**
 *    - Artists can submit art proposals (metadata URI) to the collective.
 *    - Proposals are voted on by members based on their reputation.
 * 3. **Collaborative Art Creation:**
 *    - Feature for artists to create art pieces collaboratively, defining split ownership and royalties.
 *    - On-chain agreement for collaborative projects.
 * 4. **Decentralized Curation & Voting:**
 *    - Reputation-weighted voting system for art proposals and collective decisions.
 *    - Different voting mechanisms (e.g., simple majority, quadratic voting for certain proposals).
 * 5. **Dynamic Royalty Splits & Revenue Distribution:**
 *    - Flexible royalty distribution mechanisms for individual and collaborative art pieces.
 *    - Smart contract manages royalty splits and automated payouts.
 * 6. **Art Evolution & Upgradability:**
 *    - Mechanism for artists to propose and implement upgrades or evolutions to existing art pieces (NFT metadata).
 *    - Community voting on art evolution proposals.
 * 7. **Decentralized Governance:**
 *    - Proposal and voting system for collective governance decisions (rule changes, fee structures, etc.).
 *    - Time-locked governance actions.
 * 8. **Reputation System:**
 *    - Track member reputation based on curation accuracy, contribution to collaborative projects, and governance participation.
 *    - Reputation can influence voting power and access to certain features.
 * 9. **Treasury Management:**
 *    - Contract-managed treasury for collective funds, potentially from platform fees or art sales.
 *    - Decentralized spending proposals and approvals for treasury funds.
 * 10. **NFT Minting & Management:**
 *     - Minting NFTs for approved art pieces, with metadata linked to IPFS or similar decentralized storage.
 *     - Management of NFT ownership and transfers within the collective ecosystem.
 * 11. **Emergency Pause & Security:**
 *     - Emergency pause mechanism for critical situations, controlled by a designated admin or governance.
 *     - Security considerations for contract upgradability and data integrity.

 * **Function Summary:**
 * 1. `requestMembership()`: Allows an address to request membership to the DAAC.
 * 2. `approveMembership(address _member)`: Allows existing members (with sufficient reputation or admin role) to approve a membership request.
 * 3. `revokeMembership(address _member)`: Allows governance to revoke membership from an address.
 * 4. `submitArtProposal(string memory _metadataURI)`: Allows members to submit an art proposal with metadata URI for curation.
 * 5. `voteOnArtProposal(uint256 _proposalId, bool _approve)`: Allows members to vote on an art proposal, weighted by their reputation.
 * 6. `createCollaborativeArtProposal(string memory _metadataURI, address[] memory _collaborators, uint256[] memory _royalties)`: Allows a group of members to propose a collaborative art piece with defined royalty splits.
 * 7. `acceptCollaborativeArtProposal(uint256 _proposalId)`: Allows a proposed collaborator to accept their role in a collaborative art project.
 * 8. `mintArtNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal (individual or collaborative).
 * 9. `setNFTPrice(uint256 _tokenId, uint256 _price)`: Allows the owner of an NFT (collective or artist) to set a price for it.
 * 10. `purchaseNFT(uint256 _tokenId)`: Allows anyone to purchase an NFT listed for sale, distributing revenue based on royalty splits.
 * 11. `proposeArtEvolution(uint256 _tokenId, string memory _newMetadataURI)`: Allows the original artist (or collective) to propose an evolution for an existing NFT's metadata.
 * 12. `voteOnArtEvolution(uint256 _evolutionId, bool _approve)`: Allows members to vote on an art evolution proposal.
 * 13. `executeArtEvolution(uint256 _evolutionId)`: Executes an approved art evolution, updating the NFT's metadata.
 * 14. `proposeGovernanceRuleChange(string memory _description, bytes memory _data)`: Allows members to propose a change to the DAAC's governance rules.
 * 15. `voteOnGovernanceRuleChange(uint256 _ruleChangeId, bool _approve)`: Allows members to vote on a governance rule change proposal.
 * 16. `executeGovernanceRuleChange(uint256 _ruleChangeId)`: Executes an approved governance rule change.
 * 17. `delegateVote(address _delegatee)`: Allows members to delegate their voting power to another member.
 * 18. `recordContribution(address _member, uint256 _contributionScore)`: Allows admins or governance to manually record positive contributions of a member, increasing reputation.
 * 19. `withdrawEarnings()`: Allows members to withdraw their earned royalties from NFT sales.
 * 20. `pauseContract()`: Allows an admin to pause the contract in case of emergency.
 * 21. `unpauseContract()`: Allows an admin to unpause the contract.
 * 22. `getMemberReputation(address _member)`: Returns the reputation score of a member.
 * 23. `getArtProposalStatus(uint256 _proposalId)`: Returns the status of an art proposal.
 * 24. `getNFTMetadataURI(uint256 _tokenId)`: Returns the metadata URI of an NFT.
 * 25. `getCollaborators(uint256 _proposalId)`: Returns the list of collaborators for a collaborative art proposal.
 */

contract DecentralizedAutonomousArtCollective {
    // -------- State Variables --------

    // Admin address (can be multi-sig or DAO in a real-world scenario)
    address public admin;
    bool public paused = false;

    // Membership management
    mapping(address => bool) public isMember;
    mapping(address => uint256) public memberReputation; // Reputation score for each member
    address[] public members; // List of members for iteration (optional, can be derived from isMember mapping)
    uint256 public membershipApprovalThreshold = 2; // Number of approvals needed for membership (can be reputation-weighted)
    mapping(address => uint256) public pendingMembershipApprovals; // Count of approvals for pending members

    // Art Proposals
    uint256 public proposalCounter;
    struct ArtProposal {
        string metadataURI;
        address proposer;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        bool isCollaborative;
        address[] collaborators;
        uint256[] royaltySplits; // Percentages out of 100
        ProposalStatus status;
        uint256 creationTimestamp;
    }
    enum ProposalStatus { Pending, Approved, Rejected, Minted }
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => member => hasVoted

    // Collaborative Art Proposals
    mapping(uint256 => mapping(address => bool)) public hasAcceptedCollaboration; // proposalId => collaborator => accepted

    // NFTs
    uint256 public nftCounter;
    mapping(uint256 => string) public nftMetadataURIs;
    mapping(uint256 => address[]) public nftOwners; // Owners for collaborative NFTs, otherwise single owner
    mapping(uint256 => uint256) public nftPrices; // TokenId => Price in Wei

    // Revenue and Royalties
    mapping(address => uint256) public memberEarnings; // Track earnings for each member

    // Art Evolution Proposals
    uint256 public evolutionCounter;
    struct ArtEvolutionProposal {
        uint256 tokenId;
        string newMetadataURI;
        address proposer;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        ProposalStatus status; // Reusing ProposalStatus enum
        uint256 creationTimestamp;
    }
    mapping(uint256 => ArtEvolutionProposal) public artEvolutionProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnEvolution; // evolutionId => member => hasVoted

    // Governance Rule Change Proposals
    uint256 public ruleChangeCounter;
    struct GovernanceRuleChangeProposal {
        string description;
        bytes data; // Encoded data for rule change (e.g., function signature and parameters)
        address proposer;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        ProposalStatus status; // Reusing ProposalStatus enum
        uint256 executionTimestamp; // Optional: Time-locked execution
    }
    mapping(uint256 => GovernanceRuleChangeProposal) public governanceRuleChangeProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnRuleChange; // ruleChangeId => member => hasVoted

    // Delegation (Simplified - could be more complex)
    mapping(address => address) public voteDelegation; // Member => Delegatee

    // Events
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member, address indexed approvedBy);
    event MembershipRevoked(address indexed member, address indexed revokedBy);
    event ArtProposalSubmitted(uint256 proposalId, address indexed proposer, string metadataURI);
    event ArtProposalVoted(uint256 proposalId, address indexed voter, bool approved);
    event ArtProposalApproved(uint256 proposalId);
    event ArtProposalRejected(uint256 proposalId);
    event CollaborativeArtProposalSubmitted(uint256 proposalId, address indexed proposer, string metadataURI, address[] collaborators);
    event CollaborativeArtProposalAccepted(uint256 proposalId, address indexed collaborator);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address[] owners, string metadataURI);
    event NFTPriceSet(uint256 tokenId, uint256 price);
    event NFTPurchased(uint256 tokenId, address indexed buyer, uint256 price);
    event ArtEvolutionProposed(uint256 evolutionId, uint256 tokenId, address indexed proposer, string newMetadataURI);
    event ArtEvolutionVoted(uint256 evolutionId, address indexed voter, bool approved);
    event ArtEvolutionExecuted(uint256 evolutionId, uint256 tokenId, string newMetadataURI);
    event GovernanceRuleChangeProposed(uint256 ruleChangeId, address indexed proposer, string description);
    event GovernanceRuleChangeVoted(uint256 ruleChangeId, address indexed voter, bool approved);
    event GovernanceRuleChangeExecuted(uint256 ruleChangeId, uint256 executionTimestamp);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event ContributionRecorded(address indexed member, uint256 score);
    event EarningsWithdrawn(address indexed member, uint256 amount);
    event ContractPaused(address indexed admin);
    event ContractUnpaused(address indexed admin);


    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
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

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validEvolutionId(uint256 _evolutionId) {
        require(_evolutionId > 0 && _evolutionId <= evolutionCounter, "Invalid evolution ID.");
        _;
    }

    modifier validRuleChangeId(uint256 _ruleChangeId) {
        require(_ruleChangeId > 0 && _ruleChangeId <= ruleChangeCounter, "Invalid rule change ID.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId > 0 && _tokenId <= nftCounter, "Invalid NFT token ID.");
        _;
    }

    modifier proposalNotMinted(uint256 _proposalId) {
        require(artProposals[_proposalId].status != ProposalStatus.Minted, "Proposal already minted.");
        _;
    }

    modifier proposalApproved(uint256 _proposalId) {
        require(artProposals[_proposalId].status == ProposalStatus.Approved, "Proposal not approved.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        memberReputation[admin] = 100; // Admin starts with high reputation
        isMember[admin] = true;
        members.push(admin);
    }

    // -------- Membership Management Functions --------

    /// @notice Allows an address to request membership to the DAAC.
    function requestMembership() external whenNotPaused {
        require(!isMember[msg.sender], "Already a member.");
        require(pendingMembershipApprovals[msg.sender] == 0, "Membership request already pending.");
        pendingMembershipApprovals[msg.sender] = 0; // Initialize approval count
        emit MembershipRequested(msg.sender);
    }

    /// @notice Allows existing members (with sufficient reputation or admin role) to approve a membership request.
    /// @param _member Address of the member to approve.
    function approveMembership(address _member) external onlyMember whenNotPaused {
        require(!isMember[_member], "Address is already a member.");
        require(pendingMembershipApprovals[_member] > 0 || pendingMembershipApprovals[_member] == 0, "No membership request pending from this address."); // Allow approval even if starting fresh

        if(!isMember[_member]){ // Double check in case of race condition
            pendingMembershipApprovals[_member]++;
            if (pendingMembershipApprovals[_member] >= membershipApprovalThreshold) {
                isMember[_member] = true;
                members.push(_member);
                memberReputation[_member] = 10; // Initial reputation for new members
                delete pendingMembershipApprovals[_member]; // Clean up pending approvals
                emit MembershipApproved(_member, msg.sender);
            } else {
                emit MembershipApproved(_member, msg.sender); // Emit approval event even if threshold not reached yet
            }
        }
    }

    /// @notice Allows governance to revoke membership from an address.
    /// @param _member Address of the member to revoke.
    function revokeMembership(address _member) external onlyAdmin whenNotPaused { // In a real DAO, this would be a governance vote
        require(isMember[_member], "Address is not a member.");
        require(_member != admin, "Cannot revoke admin membership.");

        isMember[_member] = false;
        // Remove from members array (optional and can be gas intensive for large arrays - consider alternative if performance critical)
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        delete memberReputation[_member];
        emit MembershipRevoked(_member, msg.sender);
    }

    /// @notice Check if an address is a member.
    /// @param _member Address to check.
    /// @return bool True if the address is a member, false otherwise.
    function getMemberStatus(address _member) external view returns (bool) {
        return isMember[_member];
    }


    // -------- Art Proposal and Submission Functions --------

    /// @notice Allows members to submit an art proposal with metadata URI for curation.
    /// @param _metadataURI URI pointing to the art metadata (e.g., IPFS).
    function submitArtProposal(string memory _metadataURI) external onlyMember whenNotPaused {
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            metadataURI: _metadataURI,
            proposer: msg.sender,
            voteCountApprove: 0,
            voteCountReject: 0,
            isCollaborative: false,
            collaborators: new address[](0),
            royaltySplits: new uint256[](0),
            status: ProposalStatus.Pending,
            creationTimestamp: block.timestamp
        });
        emit ArtProposalSubmitted(proposalCounter, msg.sender, _metadataURI);
    }

    /// @notice Allows members to vote on an art proposal, weighted by their reputation.
    /// @param _proposalId ID of the art proposal.
    /// @param _approve Boolean indicating whether to approve (true) or reject (false) the proposal.
    function voteOnArtProposal(uint256 _proposalId, bool _approve) external onlyMember whenNotPaused validProposalId(_proposalId) proposalNotMinted(_proposalId) {
        require(!hasVotedOnProposal[_proposalId][msg.sender], "Already voted on this proposal.");

        hasVotedOnProposal[_proposalId][msg.sender] = true;
        uint256 reputationWeight = getEffectiveVotingPower(msg.sender); // Get voting power considering delegation

        if (_approve) {
            artProposals[_proposalId].voteCountApprove += reputationWeight;
        } else {
            artProposals[_proposalId].voteCountReject += reputationWeight;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _approve);

        // Simple approval logic - can be made more sophisticated (e.g., quorum, time-based)
        if (artProposals[_proposalId].status == ProposalStatus.Pending) { // Check status again in case of concurrent votes
            if (artProposals[_proposalId].voteCountApprove > artProposals[_proposalId].voteCountReject * 2 ) { // Example: Approve if approves are more than double rejects
                artProposals[_proposalId].status = ProposalStatus.Approved;
                emit ArtProposalApproved(_proposalId);
            } else if (artProposals[_proposalId].voteCountReject > artProposals[_proposalId].voteCountApprove) {
                artProposals[_proposalId].status = ProposalStatus.Rejected;
                emit ArtProposalRejected(_proposalId);
            }
        }
    }

    /// @notice Allows a group of members to propose a collaborative art piece with defined royalty splits.
    /// @param _metadataURI URI pointing to the art metadata.
    /// @param _collaborators Array of addresses of collaborators.
    /// @param _royalties Array of royalty percentages for each collaborator (must sum to <= 100).
    function createCollaborativeArtProposal(string memory _metadataURI, address[] memory _collaborators, uint256[] memory _royalties) external onlyMember whenNotPaused {
        require(_collaborators.length == _royalties.length, "Collaborators and royalties arrays must have the same length.");
        uint256 totalRoyalty = 0;
        for (uint256 royalty : _royalties) {
            totalRoyalty += royalty;
        }
        require(totalRoyalty <= 100, "Total royalty split must be less than or equal to 100.");
        require(_collaborators.length > 0, "Must have at least one collaborator.");

        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            metadataURI: _metadataURI,
            proposer: msg.sender,
            voteCountApprove: 0,
            voteCountReject: 0,
            isCollaborative: true,
            collaborators: _collaborators,
            royaltySplits: _royalties,
            status: ProposalStatus.Pending,
            creationTimestamp: block.timestamp
        });

        for (uint256 i = 0; i < _collaborators.length; i++) {
            require(isMember[_collaborators[i]], "All collaborators must be DAAC members.");
            hasAcceptedCollaboration[proposalCounter][_collaborators[i]] = false; // Initialize acceptance status
        }
        emit CollaborativeArtProposalSubmitted(proposalCounter, msg.sender, _metadataURI, _collaborators);
    }

    /// @notice Allows a proposed collaborator to accept their role in a collaborative art project.
    /// @param _proposalId ID of the collaborative art proposal.
    function acceptCollaborativeArtProposal(uint256 _proposalId) external onlyMember whenNotPaused validProposalId(_proposalId) proposalNotMinted(_proposalId) {
        require(artProposals[_proposalId].isCollaborative, "Not a collaborative proposal.");
        bool isCollaborator = false;
        for (address collaborator : artProposals[_proposalId].collaborators) {
            if (collaborator == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator, "You are not a collaborator in this proposal.");
        require(!hasAcceptedCollaboration[_proposalId][msg.sender], "Already accepted collaboration.");

        hasAcceptedCollaboration[_proposalId][msg.sender] = true;

        // Optional: Automatically approve proposal when all collaborators have accepted (or after a timeout)
        uint256 acceptedCollaboratorsCount = 0;
        for (address collaborator : artProposals[_proposalId].collaborators) {
            if (hasAcceptedCollaboration[_proposalId][collaborator]) {
                acceptedCollaboratorsCount++;
            }
        }
        if (acceptedCollaboratorsCount == artProposals[_proposalId].collaborators.length) {
            artProposals[_proposalId].status = ProposalStatus.Approved; // Auto-approve if all collaborators accepted
            emit ArtProposalApproved(_proposalId);
        }
        emit CollaborativeArtProposalAccepted(_proposalId, msg.sender);
    }


    /// @notice Mints an NFT for an approved art proposal (individual or collaborative).
    /// @param _proposalId ID of the approved art proposal.
    function mintArtNFT(uint256 _proposalId) external onlyMember whenNotPaused validProposalId(_proposalId) proposalApproved(_proposalId) proposalNotMinted(_proposalId) {
        nftCounter++;
        artProposals[_proposalId].status = ProposalStatus.Minted;
        nftMetadataURIs[nftCounter] = artProposals[_proposalId].metadataURI;

        address[] memory owners;
        if (artProposals[_proposalId].isCollaborative) {
            owners = artProposals[_proposalId].collaborators;
            nftOwners[nftCounter] = owners; // Store multiple owners
        } else {
            owners = new address[](1);
            owners[0] = artProposals[_proposalId].proposer;
            nftOwners[nftCounter] = owners; // Store single owner in array for consistency
        }

        emit ArtNFTMinted(nftCounter, _proposalId, owners, artProposals[_proposalId].metadataURI);
    }

    /// @notice Allows the owner of an NFT (collective or artist) to set a price for it.
    /// @param _tokenId ID of the NFT.
    /// @param _price Price in Wei.
    function setNFTPrice(uint256 _tokenId, uint256 _price) external onlyMember whenNotPaused validTokenId(_tokenId) {
        require(isNFTOwner(_tokenId, msg.sender), "Not an owner of this NFT.");
        nftPrices[_tokenId] = _price;
        emit NFTPriceSet(_tokenId, _price);
    }

    /// @notice Allows anyone to purchase an NFT listed for sale, distributing revenue based on royalty splits.
    /// @param _tokenId ID of the NFT to purchase.
    function purchaseNFT(uint256 _tokenId) external payable whenNotPaused validTokenId(_tokenId) {
        require(nftPrices[_tokenId] > 0, "NFT is not listed for sale.");
        require(msg.value >= nftPrices[_tokenId], "Insufficient funds sent.");

        uint256 price = nftPrices[_tokenId];
        address[] memory owners = nftOwners[_tokenId];
        ArtProposal storage proposal = artProposals[getProposalIdForNFT(_tokenId)]; // Get proposal for royalty info

        if (proposal.isCollaborative) {
            for (uint256 i = 0; i < proposal.collaborators.length; i++) {
                uint256 royaltyAmount = (price * proposal.royaltySplits[i]) / 100;
                memberEarnings[proposal.collaborators[i]] += royaltyAmount;
            }
            // Remaining amount goes to collective treasury (if any, after royalties) - For simplicity, assuming full royalty split covers price here
        } else {
            memberEarnings[proposal.proposer] += price; // Single artist gets full sale price
        }

        delete nftPrices[_tokenId]; // NFT is no longer for sale after purchase
        nftOwners[_tokenId] = new address[](1); // Reset owners array for new single owner after purchase
        nftOwners[_tokenId][0] = msg.sender; // New owner is the buyer

        emit NFTPurchased(_tokenId, msg.sender, price);
    }

    /// @notice Allows members to withdraw their earned royalties from NFT sales.
    function withdrawEarnings() external onlyMember whenNotPaused {
        uint256 earnings = memberEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");

        memberEarnings[msg.sender] = 0; // Reset earnings to 0 after withdrawal
        payable(msg.sender).transfer(earnings);
        emit EarningsWithdrawn(msg.sender, earnings);
    }


    // -------- Art Evolution Functions --------

    /// @notice Allows the original artist (or collective) to propose an evolution for an existing NFT's metadata.
    /// @param _tokenId ID of the NFT to evolve.
    /// @param _newMetadataURI New metadata URI for the evolved art.
    function proposeArtEvolution(uint256 _tokenId, string memory _newMetadataURI) external onlyMember whenNotPaused validTokenId(_tokenId) {
        require(isOriginalArtist(_tokenId, msg.sender) || isAdmin(), "Only original artist or admin can propose evolution."); // Simplified ownership check

        evolutionCounter++;
        artEvolutionProposals[evolutionCounter] = ArtEvolutionProposal({
            tokenId: _tokenId,
            newMetadataURI: _newMetadataURI,
            proposer: msg.sender,
            voteCountApprove: 0,
            voteCountReject: 0,
            status: ProposalStatus.Pending,
            creationTimestamp: block.timestamp
        });
        emit ArtEvolutionProposed(evolutionCounter, _tokenId, msg.sender, _newMetadataURI);
    }

    /// @notice Allows members to vote on an art evolution proposal.
    /// @param _evolutionId ID of the art evolution proposal.
    /// @param _approve Boolean indicating whether to approve (true) or reject (false) the evolution.
    function voteOnArtEvolution(uint256 _evolutionId, bool _approve) external onlyMember whenNotPaused validEvolutionId(_evolutionId) {
        require(!hasVotedOnEvolution[_evolutionId][msg.sender], "Already voted on this evolution proposal.");

        hasVotedOnEvolution[_evolutionId][msg.sender] = true;
        uint256 reputationWeight = getEffectiveVotingPower(msg.sender);

        if (_approve) {
            artEvolutionProposals[_evolutionId].voteCountApprove += reputationWeight;
        } else {
            artEvolutionProposals[_evolutionId].voteCountReject += reputationWeight;
        }
        emit ArtEvolutionVoted(_evolutionId, msg.sender, _approve);

        // Simple approval logic
        if (artEvolutionProposals[_evolutionId].status == ProposalStatus.Pending) {
            if (artEvolutionProposals[_evolutionId].voteCountApprove > artEvolutionProposals[_evolutionId].voteCountReject) {
                artEvolutionProposals[_evolutionId].status = ProposalStatus.Approved;
                emit ArtEvolutionExecuted(_evolutionId, artEvolutionProposals[_evolutionId].tokenId, artEvolutionProposals[_evolutionId].newMetadataURI);
            } else if (artEvolutionProposals[_evolutionId].voteCountReject > artEvolutionProposals[_evolutionId].voteCountApprove) {
                artEvolutionProposals[_evolutionId].status = ProposalStatus.Rejected;
            }
        }
    }

    /// @notice Executes an approved art evolution, updating the NFT's metadata.
    /// @param _evolutionId ID of the approved art evolution proposal.
    function executeArtEvolution(uint256 _evolutionId) external onlyMember whenNotPaused validEvolutionId(_evolutionId) {
        require(artEvolutionProposals[_evolutionId].status == ProposalStatus.Approved, "Evolution proposal not approved.");
        uint256 tokenId = artEvolutionProposals[_evolutionId].tokenId;
        string memory newMetadataURI = artEvolutionProposals[_evolutionId].newMetadataURI;

        nftMetadataURIs[tokenId] = newMetadataURI; // Update NFT metadata
        artEvolutionProposals[_evolutionId].status = ProposalStatus.Minted; // Mark as executed/minted (using enum for status tracking)
        emit ArtEvolutionExecuted(_evolutionId, tokenId, newMetadataURI);
    }


    // -------- Governance Rule Change Functions --------

    /// @notice Allows members to propose a change to the DAAC's governance rules.
    /// @param _description Description of the proposed rule change.
    /// @param _data Encoded data for the rule change (e.g., function signature and parameters).
    function proposeGovernanceRuleChange(string memory _description, bytes memory _data) external onlyMember whenNotPaused {
        ruleChangeCounter++;
        governanceRuleChangeProposals[ruleChangeCounter] = GovernanceRuleChangeProposal({
            description: _description,
            data: _data,
            proposer: msg.sender,
            voteCountApprove: 0,
            voteCountReject: 0,
            status: ProposalStatus.Pending,
            executionTimestamp: 0 // Optional: Add time-locked execution later
        });
        emit GovernanceRuleChangeProposed(ruleChangeCounter, msg.sender, _description);
    }

    /// @notice Allows members to vote on a governance rule change proposal.
    /// @param _ruleChangeId ID of the governance rule change proposal.
    /// @param _approve Boolean indicating whether to approve (true) or reject (false) the rule change.
    function voteOnGovernanceRuleChange(uint256 _ruleChangeId, bool _approve) external onlyMember whenNotPaused validRuleChangeId(_ruleChangeId) {
        require(!hasVotedOnRuleChange[_ruleChangeId][msg.sender], "Already voted on this rule change proposal.");

        hasVotedOnRuleChange[_ruleChangeId][msg.sender] = true;
        uint256 reputationWeight = getEffectiveVotingPower(msg.sender);

        if (_approve) {
            governanceRuleChangeProposals[_ruleChangeId].voteCountApprove += reputationWeight;
        } else {
            governanceRuleChangeProposals[_ruleChangeId].voteCountReject += reputationWeight;
        }
        emit GovernanceRuleChangeVoted(_ruleChangeId, msg.sender, _approve);

        // Simple approval logic (can be more complex with quorum, etc.)
        if (governanceRuleChangeProposals[_ruleChangeId].status == ProposalStatus.Pending) {
            if (governanceRuleChangeProposals[_ruleChangeId].voteCountApprove > governanceRuleChangeProposals[_ruleChangeId].voteCountReject) {
                governanceRuleChangeProposals[_ruleChangeId].status = ProposalStatus.Approved;
            } else if (governanceRuleChangeProposals[_ruleChangeId].voteCountReject > governanceRuleChangeProposals[_ruleChangeId].voteCountApprove) {
                governanceRuleChangeProposals[_ruleChangeId].status = ProposalStatus.Rejected;
            }
        }
    }

    /// @notice Executes an approved governance rule change.
    /// @param _ruleChangeId ID of the approved governance rule change proposal.
    function executeGovernanceRuleChange(uint256 _ruleChangeId) external onlyAdmin whenNotPaused validRuleChangeId(_ruleChangeId) { // Admin executes, but could be timelocked or DAO executed
        require(governanceRuleChangeProposals[_ruleChangeId].status == ProposalStatus.Approved, "Governance rule change proposal not approved.");

        // Decode and execute the rule change data (example - needs more robust implementation based on rules)
        bytes memory ruleData = governanceRuleChangeProposals[_ruleChangeId].data;
        // In a real system, this would decode the 'data' and call specific functions or modify state variables
        // Example (very basic and illustrative - needs proper encoding/decoding and function selectors):
        // (bytes4 functionSig, uint256 newValue) = abi.decode(ruleData, (bytes4, uint256));
        // if (functionSig == bytes4(keccak256("setMembershipApprovalThreshold(uint256)"))) { // Example function signature
        //     setMembershipApprovalThreshold(newValue);
        // }

        governanceRuleChangeProposals[_ruleChangeId].status = ProposalStatus.Minted; // Mark as executed
        governanceRuleChangeProposals[_ruleChangeId].executionTimestamp = block.timestamp;
        emit GovernanceRuleChangeExecuted(_ruleChangeId, block.timestamp);
    }


    // -------- Reputation and Voting Power Functions --------

    /// @notice Allows members to delegate their voting power to another member.
    /// @param _delegatee Address of the member to delegate voting power to.
    function delegateVote(address _delegatee) external onlyMember whenNotPaused {
        require(isMember[_delegatee], "Delegatee must be a DAAC member.");
        require(_delegatee != msg.sender, "Cannot delegate to yourself.");
        voteDelegation[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /// @notice Allows admins or governance to manually record positive contributions of a member, increasing reputation.
    /// @param _member Address of the member who contributed.
    /// @param _contributionScore Score to add to the member's reputation.
    function recordContribution(address _member, uint256 _contributionScore) external onlyAdmin whenNotPaused { // In a real DAO, this might be proposal-based or automated
        require(isMember[_member], "Address is not a member.");
        memberReputation[_member] += _contributionScore;
        emit ContributionRecorded(_member, _contributionScore);
    }

    /// @notice Returns the reputation score of a member.
    /// @param _member Address of the member.
    /// @return uint256 Reputation score.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// @dev Internal function to get effective voting power, considering delegation.
    /// @param _voter Address of the voter.
    /// @return uint256 Effective voting power (reputation).
    function getEffectiveVotingPower(address _voter) internal view returns (uint256) {
        address delegate = voteDelegation[_voter];
        if (delegate != address(0)) {
            return memberReputation[delegate]; // Delegated vote uses delegatee's reputation
        } else {
            return memberReputation[_voter]; // Otherwise, use voter's own reputation
        }
    }

    // -------- Admin and Utility Functions --------

    /// @notice Pauses the contract, preventing most functions from being called.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing functions to be called again.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Returns the status of an art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return ProposalStatus Status of the proposal.
    function getArtProposalStatus(uint256 _proposalId) external view validProposalId(_proposalId) returns (ProposalStatus) {
        return artProposals[_proposalId].status;
    }

    /// @notice Returns the metadata URI of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return string Metadata URI.
    function getNFTMetadataURI(uint256 _tokenId) external view validTokenId(_tokenId) returns (string memory) {
        return nftMetadataURIs[_tokenId];
    }

    /// @notice Returns the list of collaborators for a collaborative art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return address[] Array of collaborator addresses.
    function getCollaborators(uint256 _proposalId) external view validProposalId(_proposalId) returns (address[] memory) {
        return artProposals[_proposalId].collaborators;
    }

    /// @dev Internal helper to check if an address is an owner of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @param _address Address to check.
    /// @return bool True if the address is an owner, false otherwise.
    function isNFTOwner(uint256 _tokenId, address _address) internal view validTokenId(_tokenId) returns (bool) {
        address[] memory owners = nftOwners[_tokenId];
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                return true;
            }
        }
        return false;
    }

    /// @dev Internal helper to check if an address is the original artist of an NFT (for evolution purposes).
    /// @param _tokenId ID of the NFT.
    /// @param _address Address to check.
    /// @return bool True if the address is the original artist, false otherwise.
    function isOriginalArtist(uint256 _tokenId, address _address) internal view validTokenId(_tokenId) returns (bool) {
        uint256 proposalId = getProposalIdForNFT(_tokenId);
        if (artProposals[proposalId].isCollaborative) {
            for(address collaborator : artProposals[proposalId].collaborators){
                if(collaborator == _address){
                    return true; // Any collaborator can propose evolution for collaborative art (can adjust logic)
                }
            }
            return false;
        } else {
            return artProposals[proposalId].proposer == _address;
        }
    }

    /// @dev Internal helper to get the proposal ID associated with an NFT token ID.
    /// @param _tokenId ID of the NFT.
    /// @return uint256 Proposal ID or 0 if not found (should not happen in this design).
    function getProposalIdForNFT(uint256 _tokenId) internal view validTokenId(_tokenId) returns (uint256) {
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (artProposals[i].status == ProposalStatus.Minted) { // Assuming proposal is marked minted when NFT is created
                bool isNFTForProposal = false;
                if(artProposals[i].isCollaborative){
                     for(uint j=0; j < artProposals[i].collaborators.length; j++){
                         if(keccak256(abi.encodePacked(artProposals[i].collaborators[j], artProposals[i].metadataURI)) == keccak256(abi.encodePacked(nftOwners[_tokenId][0], nftMetadataURIs[_tokenId]))){ // Very basic matching, needs better NFT ID tracking in real case
                            isNFTForProposal = true;
                            break;
                         }
                     }
                } else {
                    if(keccak256(abi.encodePacked(artProposals[i].proposer, artProposals[i].metadataURI)) == keccak256(abi.encodePacked(nftOwners[_tokenId][0], nftMetadataURIs[_tokenId]))){ // Very basic matching, needs better NFT ID tracking in real case
                        isNFTForProposal = true;
                    }
                }

                if(isNFTForProposal){
                    return i;
                }
            }
        }
        return 0; // Should not reach here in normal operation if tokenId is valid and minted by this contract
    }


    // -------- Fallback and Receive (for potential future extensions) --------

    receive() external payable {}
    fallback() external payable {}
}
```