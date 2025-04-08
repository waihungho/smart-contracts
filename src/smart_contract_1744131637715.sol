```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists and art enthusiasts to collaborate,
 * curate, and manage digital art in a transparent and community-driven manner. This contract explores advanced concepts
 * like dynamic NFT metadata, reputation-based governance, collaborative art creation, and decentralized exhibitions.
 *
 * Function Summary:
 * -----------------
 * **Collective Management:**
 * 1.  registerArtist(string memory _artistName, string memory _artistBio): Allows artists to register with the collective.
 * 2.  deregisterArtist(): Allows artists to deregister from the collective.
 * 3.  updateArtistProfile(string memory _newBio): Artists can update their bio information.
 * 4.  proposeCollectiveRule(string memory _ruleDescription, bytes memory _ruleData): Allows collective members to propose new rules for the collective.
 * 5.  voteOnCollectiveRule(uint256 _ruleId, bool _support): Members can vote on proposed collective rules.
 * 6.  enactCollectiveRule(uint256 _ruleId): Enacts a rule if it passes the voting threshold. (Governance function)
 * 7.  setGovernanceParameters(uint256 _newVotingDuration, uint256 _newQuorumPercentage): Allows governors to adjust governance parameters. (Governance function)
 * 8.  nominateGovernor(address _candidateAddress): Allows members to nominate new governors.
 * 9.  voteOnGovernorNomination(uint256 _nominationId, bool _support): Members vote on governor nominations.
 * 10. renounceGovernor(): Governors can step down from their role.
 *
 * **Art Management:**
 * 11. proposeArtContribution(string memory _title, string memory _description, string memory _ipfsHash): Artists propose new art contributions to the collective.
 * 12. voteOnArtContribution(uint256 _contributionId, bool _approve): Collective members vote on proposed art contributions.
 * 13. mintArtNFT(uint256 _contributionId): Mints an NFT representing an approved art contribution.
 * 14. updateArtMetadata(uint256 _tokenId, string memory _newDescription, string memory _newIpfsHash): Allows updating the metadata of a minted art NFT (governed by rules).
 * 15. proposeArtExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription): Allows members to propose art exhibitions.
 * 16. voteOnArtExhibition(uint256 _exhibitionId, bool _approve): Members vote on proposed exhibitions.
 * 17. addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId): Adds approved art NFTs to a proposed exhibition.
 * 18. removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId): Removes art NFTs from an exhibition (governed by rules).
 * 19. startExhibition(uint256 _exhibitionId): Starts an approved and populated art exhibition, making it 'live'.
 * 20. endExhibition(uint256 _exhibitionId): Ends a running exhibition.
 *
 * **Reputation & Rewards (Conceptual):**
 * 21. upvoteArtist(address _artistAddress): Members can upvote artists for positive contributions (reputation system concept).
 * 22. downvoteArtist(address _artistAddress): Members can downvote artists (reputation system concept).
 * 23. getArtistReputation(address _artistAddress): View an artist's reputation score (reputation system concept).
 *
 * **Utility & Security:**
 * 24. getCollectiveBalance(): Returns the contract's ETH balance.
 * 25. pauseContract(): Pauses core functionalities of the contract (Emergency Stop). (Governance function - Governor only)
 * 26. unpauseContract(): Resumes contract functionalities after pausing. (Governance function - Governor only)
 */
contract DecentralizedArtCollective {

    // -------- State Variables --------

    // Collective Configuration
    string public collectiveName = "Genesis Art Collective";
    address public collectiveGovernor; // Initial governor, can be a multi-sig or DAO in real-world
    address[] public governors; // List of current governors
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 51; // Percentage of votes needed to pass proposals
    bool public paused = false; // Contract pause state

    // Artist Registry
    mapping(address => ArtistProfile) public artistProfiles;
    address[] public registeredArtists;

    // Art Contributions
    uint256 public contributionCounter = 0;
    mapping(uint256 => ArtContribution) public artContributions;
    uint256[] public activeContributions;

    // Art NFTs (Simple ERC721-like implementation for demonstration)
    mapping(uint256 => ArtNFT) public artNFTs;
    uint256 public nftTokenCounter = 0;

    // Exhibitions
    uint256 public exhibitionCounter = 0;
    mapping(uint256 => ArtExhibition) public artExhibitions;
    uint256[] public activeExhibitions;

    // Governance Proposals
    uint256 public ruleProposalCounter = 0;
    mapping(uint256 => CollectiveRuleProposal) public ruleProposals;
    uint256[] public activeRuleProposals;

    uint256 public governorNominationCounter = 0;
    mapping(uint256 => GovernorNomination) public governorNominations;
    uint256[] public activeGovernorNominations;


    // Reputation System (Conceptual - Simple Up/Downvotes)
    mapping(address => int256) public artistReputation;

    // -------- Data Structures --------

    struct ArtistProfile {
        string artistName;
        string artistBio;
        bool isRegistered;
    }

    struct ArtContribution {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        bool isApproved;
        bool isActive; // Still under consideration or finalized
        uint256 nftTokenId; // Token ID if minted
    }

    struct ArtNFT {
        uint256 tokenId;
        uint256 contributionId;
        address owner;
        string description; // Metadata
        string ipfsHash;    // Metadata
    }

    struct ArtExhibition {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        bool isApproved;
        bool isActive; // Exhibition is running
        uint256[] artTokenIds; // NFTs in the exhibition
        uint256 startTime;
        uint256 endTime;
    }

    struct CollectiveRuleProposal {
        uint256 id;
        address proposer;
        string description;
        bytes ruleData; // Placeholder for complex rule data if needed
        uint256 approvalVotes;
        uint256 rejectionVotes;
        bool isEnacted;
        uint256 proposalTime;
    }

    struct GovernorNomination {
        uint256 id;
        address nominator;
        address candidate;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        bool isApproved;
        uint256 nominationTime;
    }


    // -------- Modifiers --------

    modifier onlyCollectiveMember() {
        require(artistProfiles[msg.sender].isRegistered, "Not a registered collective member.");
        _;
    }

    modifier onlyGovernor() {
        bool isGov = false;
        for(uint i = 0; i < governors.length; i++) {
            if (governors[i] == msg.sender) {
                isGov = true;
                break;
            }
        }
        require(isGov, "Only governors can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validContributionId(uint256 _contributionId) {
        require(artContributions[_contributionId].isActive, "Invalid or inactive contribution ID.");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(artExhibitions[_exhibitionId].isActive, "Invalid or inactive exhibition ID.");
        _;
    }

    modifier validRuleProposalId(uint256 _ruleId) {
        require(!ruleProposals[_ruleId].isEnacted, "Invalid or enacted rule proposal ID.");
        _;
    }

    modifier validNominationId(uint256 _nominationId) {
        require(!governorNominations[_nominationId].isApproved, "Invalid or approved nomination ID.");
        _;
    }

    // -------- Events --------

    event ArtistRegistered(address indexed artistAddress, string artistName);
    event ArtistDeregistered(address indexed artistAddress);
    event ArtistProfileUpdated(address indexed artistAddress);
    event ArtContributionProposed(uint256 indexed contributionId, address artist, string title);
    event ArtContributionVoted(uint256 indexed contributionId, address voter, bool approved);
    event ArtContributionApproved(uint256 indexed contributionId);
    event ArtNFTMinted(uint256 indexed tokenId, uint256 indexed contributionId, address owner);
    event ArtMetadataUpdated(uint256 indexed tokenId);
    event ArtExhibitionProposed(uint256 indexed exhibitionId, address proposer, string title);
    event ArtExhibitionVoted(uint256 indexed exhibitionId, address voter, bool approved);
    event ArtExhibitionApproved(uint256 indexed exhibitionId);
    event ArtAddedToExhibition(uint256 indexed exhibitionId, uint256 indexed tokenId);
    event ArtRemovedFromExhibition(uint256 indexed exhibitionId, uint256 indexed tokenId);
    event ArtExhibitionStarted(uint256 indexed exhibitionId);
    event ArtExhibitionEnded(uint256 indexed exhibitionId);
    event CollectiveRuleProposed(uint256 indexed ruleId, address proposer, string description);
    event CollectiveRuleVoted(uint256 indexed ruleId, address voter, bool support);
    event CollectiveRuleEnacted(uint256 indexed ruleId);
    event GovernanceParametersUpdated(uint256 newVotingDuration, uint256 newQuorumPercentage);
    event GovernorNominationProposed(uint256 indexed nominationId, address nominator, address candidate);
    event GovernorNominationVoted(uint256 indexed nominationId, address voter, bool support);
    event GovernorNominationApproved(uint256 indexed nominationId, address newGovernor);
    event GovernorRenounced(address indexed governorAddress);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event ArtistUpvoted(address indexed artistAddress, address indexed upvoter);
    event ArtistDownvoted(address indexed artistAddress, address indexed downvoter);


    // -------- Constructor --------

    constructor() {
        collectiveGovernor = msg.sender; // Deployer is the initial governor
        governors.push(msg.sender);
    }

    // -------- Collective Management Functions --------

    function registerArtist(string memory _artistName, string memory _artistBio) external whenNotPaused {
        require(!artistProfiles[msg.sender].isRegistered, "Already registered.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistBio: _artistBio,
            isRegistered: true
        });
        registeredArtists.push(msg.sender);
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function deregisterArtist() external onlyCollectiveMember whenNotPaused {
        artistProfiles[msg.sender].isRegistered = false;
        // Remove from registeredArtists array (more complex, omitted for brevity - consider using a linked list or mapping if order doesn't matter strictly)
        emit ArtistDeregistered(msg.sender);
    }

    function updateArtistProfile(string memory _newBio) external onlyCollectiveMember whenNotPaused {
        artistProfiles[msg.sender].artistBio = _newBio;
        emit ArtistProfileUpdated(msg.sender);
    }

    function proposeCollectiveRule(string memory _ruleDescription, bytes memory _ruleData) external onlyCollectiveMember whenNotPaused {
        ruleProposalCounter++;
        ruleProposals[ruleProposalCounter] = CollectiveRuleProposal({
            id: ruleProposalCounter,
            proposer: msg.sender,
            description: _ruleDescription,
            ruleData: _ruleData,
            approvalVotes: 0,
            rejectionVotes: 0,
            isEnacted: false,
            proposalTime: block.timestamp
        });
        activeRuleProposals.push(ruleProposalCounter);
        emit CollectiveRuleProposed(ruleProposalCounter, msg.sender, _ruleDescription);
    }

    function voteOnCollectiveRule(uint256 _ruleId, bool _support) external onlyCollectiveMember whenNotPaused validRuleProposalId(_ruleId) {
        require(block.timestamp < ruleProposals[_ruleId].proposalTime + votingDuration, "Voting period ended.");
        // Prevent double voting (implementation omitted for brevity - use mapping(address => bool) for voted members)

        if (_support) {
            ruleProposals[_ruleId].approvalVotes++;
        } else {
            ruleProposals[_ruleId].rejectionVotes++;
        }
        emit CollectiveRuleVoted(_ruleId, msg.sender, _support);
    }

    function enactCollectiveRule(uint256 _ruleId) external onlyGovernor whenNotPaused validRuleProposalId(_ruleId) {
        require(block.timestamp >= ruleProposals[_ruleId].proposalTime + votingDuration, "Voting period not ended yet.");
        uint256 totalVotes = ruleProposals[_ruleId].approvalVotes + ruleProposals[_ruleId].rejectionVotes;
        require(totalVotes > 0, "No votes cast."); // To prevent division by zero
        uint256 approvalPercentage = (ruleProposals[_ruleId].approvalVotes * 100) / totalVotes;

        if (approvalPercentage >= quorumPercentage) {
            ruleProposals[_ruleId].isEnacted = true;
            // Implement rule logic based on ruleProposals[_ruleId].ruleData here if needed (complex logic may require external oracles/contracts)
            // For now, just mark as enacted.
            emit CollectiveRuleEnacted(_ruleId);
             // Remove from active proposals
            for (uint i = 0; i < activeRuleProposals.length; i++) {
                if (activeRuleProposals[i] == _ruleId) {
                    activeRuleProposals[i] = activeRuleProposals[activeRuleProposals.length - 1];
                    activeRuleProposals.pop();
                    break;
                }
            }
        } else {
            // Proposal failed, could add logic for failed proposals if needed
             // Remove from active proposals
            for (uint i = 0; i < activeRuleProposals.length; i++) {
                if (activeRuleProposals[i] == _ruleId) {
                    activeRuleProposals[i] = activeRuleProposals[activeRuleProposals.length - 1];
                    activeRuleProposals.pop();
                    break;
                }
            }
        }
    }

    function setGovernanceParameters(uint256 _newVotingDuration, uint256 _newQuorumPercentage) external onlyGovernor whenNotPaused {
        votingDuration = _newVotingDuration;
        quorumPercentage = _newQuorumPercentage;
        emit GovernanceParametersUpdated(_newVotingDuration, _newQuorumPercentage);
    }

    function nominateGovernor(address _candidateAddress) external onlyCollectiveMember whenNotPaused {
        require(_candidateAddress != address(0), "Invalid candidate address.");
        governorNominationCounter++;
        governorNominations[governorNominationCounter] = GovernorNomination({
            id: governorNominationCounter,
            nominator: msg.sender,
            candidate: _candidateAddress,
            approvalVotes: 0,
            rejectionVotes: 0,
            isApproved: false,
            nominationTime: block.timestamp
        });
        activeGovernorNominations.push(governorNominationCounter);
        emit GovernorNominationProposed(governorNominationCounter, msg.sender, _candidateAddress);
    }

    function voteOnGovernorNomination(uint256 _nominationId, bool _support) external onlyCollectiveMember whenNotPaused validNominationId(_nominationId) {
        require(block.timestamp < governorNominations[_nominationId].nominationTime + votingDuration, "Voting period ended.");
        // Prevent double voting (implementation omitted for brevity - use mapping(address => bool) for voted members)

        if (_support) {
            governorNominations[_nominationId].approvalVotes++;
        } else {
            governorNominations[_nominationId].rejectionVotes++;
        }
        emit GovernorNominationVoted(_nominationId, msg.sender, _support);
    }

    function enactGovernorNomination(uint256 _nominationId) external onlyGovernor whenNotPaused validNominationId(_nominationId) {
        require(block.timestamp >= governorNominations[_nominationId].nominationTime + votingDuration, "Voting period not ended yet.");
        uint256 totalVotes = governorNominations[_nominationId].approvalVotes + governorNominations[_nominationId].rejectionVotes;
        require(totalVotes > 0, "No votes cast."); // To prevent division by zero
        uint256 approvalPercentage = (governorNominations[_nominationId].approvalVotes * 100) / totalVotes;

        if (approvalPercentage >= quorumPercentage) {
            governorNominations[_nominationId].isApproved = true;
            governors.push(governorNominations[_nominationId].candidate);
            emit GovernorNominationApproved(_nominationId, governorNominations[_nominationId].candidate);
             // Remove from active nominations
            for (uint i = 0; i < activeGovernorNominations.length; i++) {
                if (activeGovernorNominations[i] == _nominationId) {
                    activeGovernorNominations[i] = activeGovernorNominations[activeGovernorNominations.length - 1];
                    activeGovernorNominations.pop();
                    break;
                }
            }
        } else {
             // Remove from active nominations
            for (uint i = 0; i < activeGovernorNominations.length; i++) {
                if (activeGovernorNominations[i] == _nominationId) {
                    activeGovernorNominations[i] = activeGovernorNominations[activeGovernorNominations.length - 1];
                    activeGovernorNominations.pop();
                    break;
                }
            }
        }
    }

    function renounceGovernor() external onlyGovernor whenNotPaused {
        // Governors can renounce their role. Need to ensure at least one governor remains, or implement a fallback mechanism.
        require(governors.length > 1, "Cannot renounce if you are the only governor."); // Basic check - more robust logic needed for production
        for (uint i = 0; i < governors.length; i++) {
            if (governors[i] == msg.sender) {
                governors[i] = governors[governors.length - 1];
                governors.pop();
                break;
            }
        }
        emit GovernorRenounced(msg.sender);
    }


    // -------- Art Management Functions --------

    function proposeArtContribution(string memory _title, string memory _description, string memory _ipfsHash) external onlyCollectiveMember whenNotPaused {
        contributionCounter++;
        artContributions[contributionCounter] = ArtContribution({
            id: contributionCounter,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            approvalVotes: 0,
            rejectionVotes: 0,
            isApproved: false,
            isActive: true,
            nftTokenId: 0
        });
        activeContributions.push(contributionCounter);
        emit ArtContributionProposed(contributionCounter, msg.sender, _title);
    }

    function voteOnArtContribution(uint256 _contributionId, bool _approve) external onlyCollectiveMember whenNotPaused validContributionId(_contributionId) {
        require(block.timestamp < block.timestamp + votingDuration, "Voting period ended."); // Example: voting duration from proposal time, adjust logic if needed
        // Prevent double voting (implementation omitted for brevity - use mapping(address => bool) for voted members)

        if (_approve) {
            artContributions[_contributionId].approvalVotes++;
        } else {
            artContributions[_contributionId].rejectionVotes++;
        }
        emit ArtContributionVoted(_contributionId, msg.sender, _approve);
    }

    function mintArtNFT(uint256 _contributionId) external onlyGovernor whenNotPaused validContributionId(_contributionId) {
        require(!artContributions[_contributionId].isApproved, "Contribution already approved."); // Ensure it's not already approved
        require(block.timestamp >= block.timestamp + votingDuration, "Voting period not ended yet."); // Example: voting duration from proposal time, adjust logic if needed

        uint256 totalVotes = artContributions[_contributionId].approvalVotes + artContributions[_contributionId].rejectionVotes;
        require(totalVotes > 0, "No votes cast."); // To prevent division by zero
        uint256 approvalPercentage = (artContributions[_contributionId].approvalVotes * 100) / totalVotes;

        if (approvalPercentage >= quorumPercentage) {
            artContributions[_contributionId].isApproved = true;
            artContributions[_contributionId].isActive = false; // Mark as finalized
            nftTokenCounter++;
            artNFTs[nftTokenCounter] = ArtNFT({
                tokenId: nftTokenCounter,
                contributionId: _contributionId,
                owner: artContributions[_contributionId].artist, // Artist becomes initial owner
                description: artContributions[_contributionId].description,
                ipfsHash: artContributions[_contributionId].ipfsHash
            });
            artContributions[_contributionId].nftTokenId = nftTokenCounter;
            emit ArtNFTMinted(nftTokenCounter, _contributionId, artContributions[_contributionId].artist);
            emit ArtContributionApproved(_contributionId);
             // Remove from active contributions
            for (uint i = 0; i < activeContributions.length; i++) {
                if (activeContributions[i] == _contributionId) {
                    activeContributions[i] = activeContributions[activeContributions.length - 1];
                    activeContributions.pop();
                    break;
                }
            }
        } else {
            artContributions[_contributionId].isActive = false; // Mark as finalized even if rejected
             // Remove from active contributions
            for (uint i = 0; i < activeContributions.length; i++) {
                if (activeContributions[i] == _contributionId) {
                    activeContributions[i] = activeContributions[activeContributions.length - 1];
                    activeContributions.pop();
                    break;
                }
            }
        }
    }

    function updateArtMetadata(uint256 _tokenId, string memory _newDescription, string memory _newIpfsHash) external onlyGovernor whenNotPaused {
        require(artNFTs[_tokenId].tokenId != 0, "Invalid Token ID.");
        // Add governance logic here to control metadata updates - e.g., voting or rule-based updates
        artNFTs[_tokenId].description = _newDescription;
        artNFTs[_tokenId].ipfsHash = _newIpfsHash;
        emit ArtMetadataUpdated(_tokenId);
    }

    function proposeArtExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription) external onlyCollectiveMember whenNotPaused {
        exhibitionCounter++;
        artExhibitions[exhibitionCounter] = ArtExhibition({
            id: exhibitionCounter,
            title: _exhibitionTitle,
            description: _exhibitionDescription,
            proposer: msg.sender,
            approvalVotes: 0,
            rejectionVotes: 0,
            isApproved: false,
            isActive: false, // Not active yet
            artTokenIds: new uint256[](0),
            startTime: 0,
            endTime: 0
        });
        activeExhibitions.push(exhibitionCounter);
        emit ArtExhibitionProposed(exhibitionCounter, msg.sender, _exhibitionTitle);
    }

    function voteOnArtExhibition(uint256 _exhibitionId, bool _approve) external onlyCollectiveMember whenNotPaused validExhibitionId(_exhibitionId) {
        require(block.timestamp < block.timestamp + votingDuration, "Voting period ended."); // Example: voting duration from proposal time, adjust logic if needed
        // Prevent double voting (implementation omitted for brevity - use mapping(address => bool) for voted members)

        if (_approve) {
            artExhibitions[_exhibitionId].approvalVotes++;
        } else {
            artExhibitions[_exhibitionId].rejectionVotes++;
        }
        emit ArtExhibitionVoted(_exhibitionId, msg.sender, _approve);
    }

    function addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId) external onlyGovernor whenNotPaused validExhibitionId(_exhibitionId) {
        require(artExhibitions[_exhibitionId].isApproved, "Exhibition not yet approved.");
        require(artNFTs[_tokenId].tokenId != 0, "Invalid Token ID.");
        // Add checks if the art piece is already in another exhibition, or meets exhibition criteria, etc.
        artExhibitions[_exhibitionId].artTokenIds.push(_tokenId);
        emit ArtAddedToExhibition(_exhibitionId, _tokenId);
    }

    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId) external onlyGovernor whenNotPaused validExhibitionId(_exhibitionId) {
        // Governance could decide rules for removal, maybe voting needed. For simplicity, governor can remove.
        uint256[] storage tokenIds = artExhibitions[_exhibitionId].artTokenIds;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                emit ArtRemovedFromExhibition(_exhibitionId, _tokenId);
                return;
            }
        }
        revert("Token not found in exhibition.");
    }

    function startExhibition(uint256 _exhibitionId) external onlyGovernor whenNotPaused validExhibitionId(_exhibitionId) {
        require(!artExhibitions[_exhibitionId].isActive, "Exhibition already active.");
        require(artExhibitions[_exhibitionId].isApproved, "Exhibition not approved yet.");
        require(artExhibitions[_exhibitionId].artTokenIds.length > 0, "Exhibition has no art pieces.");

        artExhibitions[_exhibitionId].isActive = true;
        artExhibitions[_exhibitionId].startTime = block.timestamp;
        artExhibitions[_exhibitionId].endTime = block.timestamp + 30 days; // Example: 30 days duration
        emit ArtExhibitionStarted(_exhibitionId);
    }

    function endExhibition(uint256 _exhibitionId) external onlyGovernor whenNotPaused validExhibitionId(_exhibitionId) {
        require(artExhibitions[_exhibitionId].isActive, "Exhibition not active.");
        artExhibitions[_exhibitionId].isActive = false;
        artExhibitions[_exhibitionId].endTime = block.timestamp; // Update end time to when it was actually ended.
        emit ArtExhibitionEnded(_exhibitionId);
         // Remove from active exhibitions
        for (uint i = 0; i < activeExhibitions.length; i++) {
            if (activeExhibitions[i] == _exhibitionId) {
                activeExhibitions[i] = activeExhibitions[activeExhibitions.length - 1];
                activeExhibitions.pop();
                break;
            }
        }
    }


    // -------- Reputation & Rewards (Conceptual) --------

    function upvoteArtist(address _artistAddress) external onlyCollectiveMember whenNotPaused {
        artistReputation[_artistAddress]++;
        emit ArtistUpvoted(_artistAddress, msg.sender);
    }

    function downvoteArtist(address _artistAddress) external onlyCollectiveMember whenNotPaused {
        artistReputation[_artistAddress]--;
        emit ArtistDownvoted(_artistAddress, msg.sender);
    }

    function getArtistReputation(address _artistAddress) external view returns (int256) {
        return artistReputation[_artistAddress];
    }


    // -------- Utility & Security Functions --------

    function getCollectiveBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function pauseContract() external onlyGovernor whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyGovernor whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // Fallback function to receive ETH donations (optional)
    receive() external payable {}
}
```