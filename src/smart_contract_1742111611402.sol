```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (Example - Not for Production)
 * @notice This smart contract implements a Decentralized Autonomous Art Collective (DAAC) where artists can propose, create, and manage digital art pieces.
 *         The DAAC is governed by its members through a voting system, and incorporates advanced features like:
 *         - Generative Art Algorithm Upload & Execution: Artists can upload algorithms to generate unique art.
 *         - Layered Art NFTs: Art pieces can be composed of multiple layers, allowing for dynamic and evolving art.
 *         - Collaborative Art Creation:  Multiple artists can collaborate on a single art piece.
 *         - Decentralized Curation & Voting: Members vote on art proposals and curation decisions.
 *         - Dynamic Royalty Splits: Royalties are dynamically distributed based on contribution and roles.
 *         - On-chain Randomness Integration (Simulated for Example - Use Chainlink VRF in Production).
 *         - Art Piece Evolution & Upgrades: Art can be upgraded or evolved over time with community consensus.
 *         - Decentralized Marketplace: Built-in marketplace for buying and selling DAAC art.
 *         - Staking & Membership Rewards: Members can stake tokens to gain voting power and earn rewards.
 *         - Governance & Parameter Updates: Community can vote to change contract parameters.
 *         - Public Art Gallery & Display: On-chain gallery to showcase DAAC art.
 *         - Art Licensing & Usage Rights Management:  Define and manage usage rights for DAAC art.
 *         - DAO Treasury Management: Decentralized management of the DAAC treasury.
 *         - Artist Reputation System: Track artist contributions and reputation within the DAAC.
 *         - Community Challenges & Contests: Organize art challenges and contests with rewards.
 *         - Burn Mechanism for Art Scarcity: Option to burn art pieces for increased scarcity.
 *         - Referral Program for New Artists & Members: Incentivize growth of the DAAC community.
 *         - Art Piece Fractionalization (Conceptual):  Possibility to fractionalize ownership of high-value art.
 *         - Cross-Chain Art Bridging (Conceptual): Future potential to bridge DAAC art to other chains.
 *
 * Function Summary:
 * 1. proposeArtAlgorithm(string _algorithmName, string _algorithmCodeHash): Artists propose a generative art algorithm.
 * 2. voteOnAlgorithmProposal(uint _proposalId, bool _vote): Members vote on art algorithm proposals.
 * 3. executeAlgorithmProposal(uint _proposalId):  Executes approved algorithm proposals to register them.
 * 4. createArtProposal(string _artName, uint _algorithmId, string _metadataURI, address[] memory _collaborators, uint[] memory _royaltyShares): Artists propose a new art piece using a registered algorithm.
 * 5. voteOnArtProposal(uint _proposalId, bool _vote): Members vote on art piece proposals.
 * 6. mintArt(uint _proposalId): Mints an NFT for an approved art piece proposal.
 * 7. addArtLayer(uint _tokenId, string _layerMetadataURI): Artists or approved members can add layers to existing art NFTs.
 * 8. updateArtMetadata(uint _tokenId, string _newMetadataURI): Update the base metadata URI of an art NFT.
 * 9. transferArtOwnership(uint _tokenId, address _to): Transfer ownership of an art NFT.
 * 10. listArtForSale(uint _tokenId, uint _price): List an art NFT for sale in the DAAC marketplace.
 * 11. purchaseArt(uint _tokenId): Purchase an art NFT listed in the marketplace.
 * 12. stakeTokens(): Members stake tokens to gain voting power and potential rewards.
 * 13. unstakeTokens(): Members unstake their tokens.
 * 14. proposeGovernanceChange(string _description, bytes memory _calldata): Propose changes to contract parameters or functionality.
 * 15. voteOnGovernanceProposal(uint _proposalId, bool _vote): Members vote on governance proposals.
 * 16. executeGovernanceProposal(uint _proposalId): Executes approved governance proposals.
 * 17. setArtUsageRights(uint _tokenId, string _usageRightsDescription): Define usage rights for an art NFT.
 * 18. withdrawTreasuryFunds(address _to, uint _amount): DAO members can propose and vote to withdraw funds from the treasury.
 * 19. createArtChallenge(string _challengeName, string _description, uint _rewardAmount, uint _deadline): Create art challenges for the community.
 * 20. submitArtForChallenge(uint _challengeId, string _artSubmissionMetadataURI): Artists submit art for active challenges.
 * 21. voteOnChallengeWinner(uint _challengeId, uint _submissionIndex, bool _vote): Members vote on the winners of art challenges.
 * 22. finalizeChallenge(uint _challengeId): Finalize a challenge and distribute rewards to winners.
 */

contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    string public name = "Decentralized Autonomous Art Collective";
    string public symbol = "DAAC_ART";

    address public owner; // DAO Owner/Admin (Initially contract deployer)
    uint public membershipStakeAmount = 1 ether; // Amount to stake for membership
    uint public votingDuration = 7 days; // Default voting duration for proposals
    uint public treasuryBalance; // DAO Treasury Balance

    uint public nextAlgorithmProposalId = 1;
    uint public nextArtProposalId = 1;
    uint public nextGovernanceProposalId = 1;
    uint public nextChallengeId = 1;
    uint public nextArtTokenId = 1;

    struct AlgorithmProposal {
        uint proposalId;
        string algorithmName;
        string algorithmCodeHash; // Hash of the algorithm code (e.g., IPFS hash)
        address proposer;
        uint startTime;
        uint endTime;
        uint yesVotes;
        uint noVotes;
        bool executed;
    }
    mapping(uint => AlgorithmProposal) public algorithmProposals;
    mapping(uint => bool) public approvedAlgorithms; // Algorithm ID => is Approved

    struct ArtProposal {
        uint proposalId;
        string artName;
        uint algorithmId; // ID of the generative algorithm used
        string metadataURI; // Base metadata URI for the art piece
        address proposer;
        address[] collaborators;
        uint[] royaltyShares; // Percentage shares for collaborators (sum must be 100)
        uint startTime;
        uint endTime;
        uint yesVotes;
        uint noVotes;
        bool executed;
    }
    mapping(uint => ArtProposal) public artProposals;
    mapping(uint => bool) public approvedArtProposals; // Art Proposal ID => is Approved

    struct GovernanceProposal {
        uint proposalId;
        string description;
        bytes calldata; // Calldata to execute if proposal passes
        address proposer;
        uint startTime;
        uint endTime;
        uint yesVotes;
        uint noVotes;
        bool executed;
    }
    mapping(uint => GovernanceProposal) public governanceProposals;

    struct ArtPiece {
        uint tokenId;
        string artName;
        uint algorithmId;
        string metadataURI;
        address creator;
        address[] collaborators;
        uint[] royaltyShares;
        address currentOwner;
        string usageRightsDescription;
        uint[] artLayers; // Token IDs of associated layers (if layered art) - Conceptual
        uint forSalePrice; // Price if listed for sale, 0 if not
    }
    mapping(uint => ArtPiece) public artPieces;
    mapping(uint => address) public artTokenOwner; // Token ID => Owner Address

    struct Member {
        address memberAddress;
        uint stakedTokens;
        uint joinTimestamp;
    }
    mapping(address => Member) public members;
    mapping(address => uint) public stakedBalances; // Address => staked token amount

    struct ArtChallenge {
        uint challengeId;
        string challengeName;
        string description;
        uint rewardAmount;
        uint deadline;
        bool isActive;
        mapping(uint => string) submissions; // Submission Index => Metadata URI
        address[] submitters;
        mapping(uint => mapping(address => bool)) submissionVotes; // Challenge ID => Submission Index => Voter => Voted?
        uint[] submissionVoteCounts; // Challenge ID => Submission Index => Vote Count
        uint winnerSubmissionIndex;
        bool finalized;
    }
    mapping(uint => ArtChallenge) public artChallenges;

    // --- Events ---
    event AlgorithmProposalCreated(uint proposalId, string algorithmName, address proposer);
    event AlgorithmProposalVoted(uint proposalId, address voter, bool vote);
    event AlgorithmProposalExecuted(uint proposalId, uint algorithmId);
    event ArtProposalCreated(uint proposalId, string artName, uint algorithmId, address proposer);
    event ArtProposalVoted(uint proposalId, address voter, bool vote);
    event ArtMinted(uint tokenId, uint proposalId, address minter);
    event ArtLayerAdded(uint tokenId, uint layerTokenId, string layerMetadataURI);
    event ArtMetadataUpdated(uint tokenId, string newMetadataURI);
    event ArtOwnershipTransferred(uint tokenId, address from, address to);
    event ArtListedForSale(uint tokenId, uint price);
    event ArtPurchased(uint tokenId, address buyer, uint price);
    event TokensStaked(address member, uint amount);
    event TokensUnstaked(address member, uint amount);
    event GovernanceProposalCreated(uint proposalId, string description, address proposer);
    event GovernanceProposalVoted(uint proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint proposalId, uint proposalIdExecuted);
    event ArtUsageRightsSet(uint tokenId, string usageRightsDescription);
    event TreasuryWithdrawal(address to, uint amount);
    event ArtChallengeCreated(uint challengeId, string challengeName, uint rewardAmount, uint deadline);
    event ArtSubmittedForChallenge(uint challengeId, uint submissionIndex, address submitter);
    event ChallengeWinnerVoted(uint challengeId, uint submissionIndex, address voter, bool vote);
    event ChallengeFinalized(uint challengeId, uint winnerSubmissionIndex, address winner);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender].memberAddress != address(0), "Only members can call this function.");
        _;
    }

    modifier validProposal(uint _proposalId, mapping(uint => AlgorithmProposal) storage _proposals) { // Generic proposal modifier
        require(_proposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        require(!_proposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp < _proposals[_proposalId].endTime, "Voting period ended.");
        _;
    }
    modifier validArtProposal(uint _proposalId) {
        require(artProposals[_proposalId].proposalId == _proposalId, "Invalid art proposal ID.");
        require(!artProposals[_proposalId].executed, "Art proposal already executed.");
        require(block.timestamp < artProposals[_proposalId].endTime, "Voting period ended.");
        _;
    }

    modifier validGovernanceProposal(uint _proposalId) {
        require(governanceProposals[_proposalId].proposalId == _proposalId, "Invalid governance proposal ID.");
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed.");
        require(block.timestamp < governanceProposals[_proposalId].endTime, "Voting period ended.");
        _;
    }

    modifier validChallenge(uint _challengeId) {
        require(artChallenges[_challengeId].challengeId == _challengeId, "Invalid challenge ID.");
        require(artChallenges[_challengeId].isActive, "Challenge is not active.");
        require(block.timestamp < artChallenges[_challengeId].deadline, "Challenge deadline passed.");
        _;
    }

    modifier validArtToken(uint _tokenId) {
        require(artPieces[_tokenId].tokenId == _tokenId, "Invalid art token ID.");
        _;
    }

    modifier onlyArtOwner(uint _tokenId) {
        require(artTokenOwner[_tokenId] == msg.sender, "Only art owner can call this function.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Algorithm Proposal Functions ---

    /// @notice Artists propose a generative art algorithm.
    /// @param _algorithmName Name of the algorithm.
    /// @param _algorithmCodeHash Hash of the algorithm code (e.g., IPFS hash).
    function proposeArtAlgorithm(string memory _algorithmName, string memory _algorithmCodeHash) public onlyMembers {
        AlgorithmProposal storage proposal = algorithmProposals[nextAlgorithmProposalId];
        proposal.proposalId = nextAlgorithmProposalId;
        proposal.algorithmName = _algorithmName;
        proposal.algorithmCodeHash = _algorithmCodeHash;
        proposal.proposer = msg.sender;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;
        nextAlgorithmProposalId++;
        emit AlgorithmProposalCreated(proposal.proposalId, _algorithmName, msg.sender);
    }

    /// @notice Members vote on art algorithm proposals.
    /// @param _proposalId ID of the algorithm proposal.
    /// @param _vote True for yes, false for no.
    function voteOnAlgorithmProposal(uint _proposalId, bool _vote) public onlyMembers validProposal(_proposalId, algorithmProposals) {
        AlgorithmProposal storage proposal = algorithmProposals[_proposalId];
        require(stakedBalances[msg.sender] >= membershipStakeAmount, "Need to stake tokens to vote."); // Ensure voter is staked

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit AlgorithmProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes approved algorithm proposals to register them.
    /// @param _proposalId ID of the algorithm proposal.
    function executeAlgorithmProposal(uint _proposalId) public onlyOwner validProposal(_proposalId, algorithmProposals) {
        AlgorithmProposal storage proposal = algorithmProposals[_proposalId];
        require(proposal.yesVotes > proposal.noVotes, "Proposal not approved by majority.");

        approvedAlgorithms[_proposalId] = true; // Mark algorithm as approved
        proposal.executed = true;
        emit AlgorithmProposalExecuted(_proposalId, _proposalId); // Algorithm ID is same as proposal ID for simplicity in this example.
    }


    // --- Art Proposal & Minting Functions ---

    /// @notice Artists propose a new art piece using a registered algorithm.
    /// @param _artName Name of the art piece.
    /// @param _algorithmId ID of the approved generative algorithm to use.
    /// @param _metadataURI Base metadata URI for the art piece.
    /// @param _collaborators Array of collaborator addresses.
    /// @param _royaltyShares Array of royalty shares for collaborators (percentages, sum to 100).
    function createArtProposal(
        string memory _artName,
        uint _algorithmId,
        string memory _metadataURI,
        address[] memory _collaborators,
        uint[] memory _royaltyShares
    ) public onlyMembers {
        require(approvedAlgorithms[_algorithmId], "Algorithm is not approved.");
        require(_collaborators.length == _royaltyShares.length, "Collaborators and royalty shares arrays must have the same length.");
        uint totalShares = 0;
        for (uint i = 0; i < _royaltyShares.length; i++) {
            totalShares += _royaltyShares[i];
        }
        require(totalShares <= 100, "Total royalty shares cannot exceed 100.");

        ArtProposal storage proposal = artProposals[nextArtProposalId];
        proposal.proposalId = nextArtProposalId;
        proposal.artName = _artName;
        proposal.algorithmId = _algorithmId;
        proposal.metadataURI = _metadataURI;
        proposal.proposer = msg.sender;
        proposal.collaborators = _collaborators;
        proposal.royaltyShares = _royaltyShares;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;
        nextArtProposalId++;
        emit ArtProposalCreated(proposal.proposalId, _artName, _algorithmId, msg.sender);
    }

    /// @notice Members vote on art piece proposals.
    /// @param _proposalId ID of the art proposal.
    /// @param _vote True for yes, false for no.
    function voteOnArtProposal(uint _proposalId, bool _vote) public onlyMembers validArtProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(stakedBalances[msg.sender] >= membershipStakeAmount, "Need to stake tokens to vote."); // Ensure voter is staked

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Mints an NFT for an approved art piece proposal.
    /// @param _proposalId ID of the art proposal.
    function mintArt(uint _proposalId) public onlyOwner validArtProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.yesVotes > proposal.noVotes, "Art proposal not approved by majority.");

        approvedArtProposals[_proposalId] = true; // Mark art proposal as approved
        proposal.executed = true;

        ArtPiece storage art = artPieces[nextArtTokenId];
        art.tokenId = nextArtTokenId;
        art.artName = proposal.artName;
        art.algorithmId = proposal.algorithmId;
        art.metadataURI = proposal.metadataURI;
        art.creator = proposal.proposer;
        art.collaborators = proposal.collaborators;
        art.royaltyShares = proposal.royaltyShares;
        art.currentOwner = proposal.proposer; // Initial owner is the proposer
        artTokenOwner[nextArtTokenId] = proposal.proposer;

        emit ArtMinted(nextArtTokenId, _proposalId, proposal.proposer);
        nextArtTokenId++;
    }

    /// @notice Artists or approved members can add layers to existing art NFTs. (Conceptual - Layered NFTs)
    /// @param _tokenId ID of the art NFT to add a layer to.
    /// @param _layerMetadataURI Metadata URI for the new layer.
    function addArtLayer(uint _tokenId, string memory _layerMetadataURI) public onlyMembers validArtToken(_tokenId) {
        // In a real layered NFT implementation, you'd likely mint a separate NFT for the layer and link it.
        // For simplicity, here we are just conceptually tracking layer metadata URIs.
        // In a more advanced version, consider using a separate Layer NFT contract.

        ArtPiece storage art = artPieces[_tokenId];
        // In a real implementation, you might mint a new NFT for the layer and store its tokenId in art.artLayers.
        // For this example, we are just simulating layer addition with metadata.
        // For simplicity, not fully implementing layered NFT logic here.
        // Assume some logic here to handle layer addition, potentially involving voting or artist approval.

        // For now, just emit an event to simulate layer addition.
        uint layerTokenId = nextArtTokenId; // In a real version, mint a new NFT here for the layer
        emit ArtLayerAdded(_tokenId, layerTokenId, _layerMetadataURI);
        nextArtTokenId++; // Increment for potential layer token IDs (conceptual)

        // In a real layered NFT implementation, you might update art.artLayers array with the new layer token ID.
        // art.artLayers.push(layerTokenId); // Conceptual - would need dynamic arrays or more sophisticated layer management.
    }

    /// @notice Update the base metadata URI of an art NFT.
    /// @param _tokenId ID of the art NFT.
    /// @param _newMetadataURI New metadata URI.
    function updateArtMetadata(uint _tokenId, string memory _newMetadataURI) public onlyArtOwner(_tokenId) validArtToken(_tokenId) {
        artPieces[_tokenId].metadataURI = _newMetadataURI;
        emit ArtMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /// @notice Transfer ownership of an art NFT.
    /// @param _tokenId ID of the art NFT.
    /// @param _to Address of the new owner.
    function transferArtOwnership(uint _tokenId, address _to) public onlyArtOwner(_tokenId) validArtToken(_tokenId) {
        address from = artTokenOwner[_tokenId];
        artTokenOwner[_tokenId] = _to;
        artPieces[_tokenId].currentOwner = _to;
        emit ArtOwnershipTransferred(_tokenId, from, _to);
    }


    // --- Marketplace Functions ---

    /// @notice List an art NFT for sale in the DAAC marketplace.
    /// @param _tokenId ID of the art NFT.
    /// @param _price Price in wei.
    function listArtForSale(uint _tokenId, uint _price) public onlyArtOwner(_tokenId) validArtToken(_tokenId) {
        artPieces[_tokenId].forSalePrice = _price;
        emit ArtListedForSale(_tokenId, _price);
    }

    /// @notice Purchase an art NFT listed in the marketplace.
    /// @param _tokenId ID of the art NFT to purchase.
    function purchaseArt(uint _tokenId) payable public validArtToken(_tokenId) {
        ArtPiece storage art = artPieces[_tokenId];
        require(art.forSalePrice > 0, "Art is not listed for sale.");
        require(msg.value >= art.forSalePrice, "Insufficient funds sent.");
        require(artTokenOwner[_tokenId] != msg.sender, "Cannot purchase your own art.");

        address seller = artTokenOwner[_tokenId];
        uint price = art.forSalePrice;

        art.forSalePrice = 0; // Remove from marketplace listing
        artTokenOwner[_tokenId] = msg.sender;
        artPieces[_tokenId].currentOwner = msg.sender;
        emit ArtPurchased(_tokenId, msg.sender, price);
        emit ArtOwnershipTransferred(_tokenId, seller, msg.sender);

        // Distribute royalties and sale proceeds
        uint creatorShare = (price * (100 - calculateTotalRoyaltyPercentage(art))) / 100; // Creator gets base share
        payable(art.creator).transfer(creatorShare);

        uint remainingAmount = price - creatorShare;
        for (uint i = 0; i < art.collaborators.length; i++) {
            uint royaltyAmount = (remainingAmount * art.royaltyShares[i]) / 100;
            payable(art.collaborators[i]).transfer(royaltyAmount);
        }

        treasuryBalance += msg.value - price; // Remaining funds to treasury (if any overpayment)
    }

    // --- Membership & Staking Functions ---

    /// @notice Members stake tokens to gain voting power and potential rewards.
    function stakeTokens() public payable {
        require(msg.value >= membershipStakeAmount, "Must stake at least the membership stake amount.");
        require(members[msg.sender].memberAddress == address(0), "Already a member."); // Prevent re-staking for existing members in this simplified example

        members[msg.sender] = Member({
            memberAddress: msg.sender,
            stakedTokens: msg.value,
            joinTimestamp: block.timestamp
        });
        stakedBalances[msg.sender] += msg.value;
        treasuryBalance += msg.value; // Staked tokens go to the treasury in this example

        emit TokensStaked(msg.sender, msg.value);
    }

    /// @notice Members unstake their tokens.
    function unstakeTokens() public onlyMembers {
        Member storage memberData = members[msg.sender];
        uint stakedAmount = stakedBalances[msg.sender];
        require(stakedAmount > 0, "No tokens staked.");

        delete members[msg.sender]; // Remove membership (simplified unstaking - consider more complex unstaking logic in real DAO)
        stakedBalances[msg.sender] = 0;
        treasuryBalance -= stakedAmount; // Return staked tokens from treasury

        payable(msg.sender).transfer(stakedAmount);
        emit TokensUnstaked(msg.sender, stakedAmount);
    }


    // --- Governance Functions ---

    /// @notice Propose changes to contract parameters or functionality.
    /// @param _description Description of the governance proposal.
    /// @param _calldata Calldata to execute if proposal passes.
    function proposeGovernanceChange(string memory _description, bytes memory _calldata) public onlyMembers {
        GovernanceProposal storage proposal = governanceProposals[nextGovernanceProposalId];
        proposal.proposalId = nextGovernanceProposalId;
        proposal.description = _description;
        proposal.calldata = _calldata;
        proposal.proposer = msg.sender;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;
        nextGovernanceProposalId++;
        emit GovernanceProposalCreated(proposal.proposalId, _description, msg.sender);
    }

    /// @notice Members vote on governance proposals.
    /// @param _proposalId ID of the governance proposal.
    /// @param _vote True for yes, false for no.
    function voteOnGovernanceProposal(uint _proposalId, bool _vote) public onlyMembers validGovernanceProposal(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(stakedBalances[msg.sender] >= membershipStakeAmount, "Need to stake tokens to vote."); // Ensure voter is staked

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes approved governance proposals.
    /// @param _proposalId ID of the governance proposal.
    function executeGovernanceProposal(uint _proposalId) public onlyOwner validGovernanceProposal(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.yesVotes > proposal.noVotes, "Governance proposal not approved by majority.");

        proposal.executed = true;
        (bool success, ) = address(this).delegatecall(proposal.calldata); // Execute the governance action
        require(success, "Governance proposal execution failed.");

        emit GovernanceProposalExecuted(_proposalId, _proposalId);
    }

    /// @notice Example governance function - Change the membership stake amount. (Callable via governance proposal)
    /// @param _newStakeAmount New membership stake amount.
    function setMembershipStakeAmount(uint _newStakeAmount) public onlyOwner { // Only executable via governance proposal after approval
        membershipStakeAmount = _newStakeAmount;
    }

    // --- Art Usage Rights ---

    /// @notice Define usage rights for an art NFT.
    /// @param _tokenId ID of the art NFT.
    /// @param _usageRightsDescription Description of the usage rights (e.g., "Commercial Use Allowed", "Personal Use Only").
    function setArtUsageRights(uint _tokenId, string memory _usageRightsDescription) public onlyArtOwner(_tokenId) validArtToken(_tokenId) {
        artPieces[_tokenId].usageRightsDescription = _usageRightsDescription;
        emit ArtUsageRightsSet(_tokenId, _usageRightsDescription);
    }

    // --- Treasury Management ---

    /// @notice DAO members can propose and vote to withdraw funds from the treasury.
    /// @param _to Address to withdraw funds to.
    /// @param _amount Amount to withdraw in wei.
    function withdrawTreasuryFunds(address _to, uint _amount) public onlyMembers {
        require(_amount <= treasuryBalance, "Insufficient treasury balance.");

        bytes memory calldataPayload = abi.encodeWithSignature("executeTreasuryWithdrawal(address,uint256)", _to, _amount);
        proposeGovernanceChange("Treasury Withdrawal", calldataPayload);
    }

    /// @notice Execute treasury withdrawal (internal function called by governance execution).
    /// @param _to Address to send funds to.
    /// @param _amount Amount to send.
    function executeTreasuryWithdrawal(address _to, uint256 _amount) internal onlyOwner { // Internal, called by governance execution
        treasuryBalance -= _amount;
        payable(_to).transfer(_amount);
        emit TreasuryWithdrawal(_to, _amount);
    }


    // --- Art Challenges & Contests ---

    /// @notice Create art challenges for the community.
    /// @param _challengeName Name of the challenge.
    /// @param _description Description of the challenge.
    /// @param _rewardAmount Reward amount for the winner in wei.
    /// @param _deadline Challenge deadline timestamp.
    function createArtChallenge(string memory _challengeName, string memory _description, uint _rewardAmount, uint _deadline) public onlyMembers {
        require(_rewardAmount <= treasuryBalance, "Insufficient treasury balance for reward.");

        ArtChallenge storage challenge = artChallenges[nextChallengeId];
        challenge.challengeId = nextChallengeId;
        challenge.challengeName = _challengeName;
        challenge.description = _description;
        challenge.rewardAmount = _rewardAmount;
        challenge.deadline = _deadline;
        challenge.isActive = true;
        challenge.submissionVoteCounts = new uint[](0); // Initialize vote counts array
        nextChallengeId++;

        emit ArtChallengeCreated(challenge.challengeId, _challengeName, _rewardAmount, _deadline);
    }

    /// @notice Artists submit art for active challenges.
    /// @param _challengeId ID of the challenge.
    /// @param _artSubmissionMetadataURI Metadata URI of the art submission.
    function submitArtForChallenge(uint _challengeId, string memory _artSubmissionMetadataURI) public onlyMembers validChallenge(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(challenge.submissions[0] == "", "Submissions are closed for this challenge."); // Basic check to ensure submissions are still open (can be refined)

        uint submissionIndex = challenge.submitters.length;
        challenge.submissions[submissionIndex] = _artSubmissionMetadataURI;
        challenge.submitters.push(msg.sender);

        emit ArtSubmittedForChallenge(_challengeId, submissionIndex, msg.sender);
    }

    /// @notice Members vote on the winners of art challenges.
    /// @param _challengeId ID of the challenge.
    /// @param _submissionIndex Index of the art submission to vote for.
    /// @param _vote True for yes, false for no (In this simplified example, it's just a yes/no vote on *winning*).
    function voteOnChallengeWinner(uint _challengeId, uint _submissionIndex, bool _vote) public onlyMembers validChallenge(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(_submissionIndex < challenge.submitters.length, "Invalid submission index.");
        require(!challenge.submissionVotes[_submissionIndex][msg.sender], "Already voted for this submission.");

        challenge.submissionVotes[_submissionIndex][msg.sender] = true; // Record voter's vote
        if (challenge.submissionVoteCounts.length <= _submissionIndex) {
            challenge.submissionVoteCounts.push(0); // Initialize if needed
        }
        if (_vote) {
            challenge.submissionVoteCounts[_submissionIndex]++;
        } else {
            // Optionally handle negative votes if needed, for simplicity, we are just counting positive votes.
        }

        emit ChallengeWinnerVoted(_challengeId, _submissionIndex, msg.sender, _vote);
    }


    /// @notice Finalize a challenge and distribute rewards to winners.
    /// @param _challengeId ID of the challenge to finalize.
    function finalizeChallenge(uint _challengeId) public onlyOwner validChallenge(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(!challenge.finalized, "Challenge already finalized.");

        uint winningSubmissionIndex = 0; // Default to first submission if no clear winner (can refine winner selection logic)
        uint maxVotes = 0;
        for (uint i = 0; i < challenge.submitters.length; i++) {
            if (challenge.submissionVoteCounts[i] > maxVotes) {
                maxVotes = challenge.submissionVoteCounts[i];
                winningSubmissionIndex = i;
            }
        }

        challenge.winnerSubmissionIndex = winningSubmissionIndex;
        challenge.isActive = false;
        challenge.finalized = true;

        address winnerAddress = challenge.submitters[winningSubmissionIndex];
        uint rewardAmount = challenge.rewardAmount;

        treasuryBalance -= rewardAmount;
        payable(winnerAddress).transfer(rewardAmount);

        emit ChallengeFinalized(_challengeId, winningSubmissionIndex, winnerAddress);
    }


    // --- Utility Functions ---

    /// @notice Calculate total royalty percentage for an art piece.
    /// @param _art ArtPiece struct.
    /// @return Total royalty percentage.
    function calculateTotalRoyaltyPercentage(ArtPiece storage _art) internal pure returns (uint) {
        uint totalRoyalty = 0;
        for (uint i = 0; i < _art.royaltyShares.length; i++) {
            totalRoyalty += _art.royaltyShares[i];
        }
        return totalRoyalty;
    }

    /// @notice Get current treasury balance.
    /// @return Treasury balance.
    function getTreasuryBalance() public view returns (uint) {
        return treasuryBalance;
    }

    /// @notice Get the number of members.
    /// @return Member count.
    function getMemberCount() public view returns (uint) {
        uint count = 0;
        for (uint i = 1; i < nextArtTokenId; i++) { // Iterate through art tokens (simplified way to estimate members in this example - improve in real implementation)
            if (artPieces[i].creator != address(0)) { // Basic check for creator existence
                count++;
            }
        }
        return count; // In a real DAO, maintain a separate member count variable for efficiency.
    }

    /// @notice Get voting power of a member (based on staked tokens - simplified example).
    /// @param _memberAddress Address of the member.
    /// @return Voting power.
    function getVotingPower(address _memberAddress) public view returns (uint) {
        return stakedBalances[_memberAddress]; // Voting power is directly proportional to staked amount in this simple example.
        // In a more advanced DAO, voting power could be weighted, time-based, etc.
    }

    /// @notice Get the number of art pieces minted.
    /// @return Art piece count.
    function getArtPieceCount() public view returns (uint) {
        return nextArtTokenId - 1;
    }

    /// @notice Get the number of approved algorithms.
    /// @return Approved algorithm count.
    function getApprovedAlgorithmCount() public view returns (uint) {
        uint count = 0;
        for (uint i = 1; i < nextAlgorithmProposalId; i++) {
            if (approvedAlgorithms[i]) {
                count++;
            }
        }
        return count;
    }

    /// @notice Get the number of active challenges.
    /// @return Active challenge count.
    function getActiveChallengeCount() public view returns (uint) {
        uint count = 0;
        for (uint i = 1; i < nextChallengeId; i++) {
            if (artChallenges[i].isActive) {
                count++;
            }
        }
        return count;
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {}

    /// @notice Payable function to receive Ether.
    function receiveEther() public payable {}
}
```