```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI
 * @dev A sophisticated smart contract for a decentralized art collective,
 * incorporating advanced concepts like generative art, collaborative creation,
 * dynamic royalties, reputation-based governance, and decentralized curation.
 *
 * Outline & Function Summary:
 *
 * --- Core Functionality ---
 * 1.  registerArtist(): Allows artists to register with a profile.
 * 2.  updateArtistProfile(): Artists can update their profile information.
 * 3.  submitGenerativeArtAlgorithm(): Artists submit generative art algorithms (simplified).
 * 4.  generateArtFromAlgorithm(): Executes a submitted algorithm to generate art (simplified).
 * 5.  mintArtworkNFT(): Mints an NFT representing a generated or traditionally submitted artwork.
 * 6.  transferArtworkOwnership(): Allows artwork NFT owners to transfer ownership.
 * 7.  setArtworkRoyalty(): Artists can set a royalty percentage on their artworks.
 * 8.  purchaseArtwork(): Enables users to purchase artworks, distributing royalties dynamically.
 *
 * --- Collaborative & Curation Features ---
 * 9.  createCollaborationProposal(): Artists propose collaborations on artworks.
 * 10. voteOnCollaborationProposal(): Registered artists vote on collaboration proposals.
 * 11. acceptCollaborationInvite(): Artists accept invitations to join collaborations.
 * 12. submitCollaborativeArtwork():  Leads of approved collaborations submit collaborative artworks.
 * 13. proposeArtworkForExhibition(): Artists propose artworks for virtual exhibitions.
 * 14. voteOnExhibitionProposal(): Registered artists vote on artwork exhibition proposals.
 * 15. createCurationChallenge(): Governors create curation challenges with specific themes.
 * 16. submitArtworkToChallenge(): Artists submit artworks to active curation challenges.
 * 17. voteOnChallengeSubmission(): Registered artists vote on submissions to curation challenges.
 * 18. rewardChallengeWinners(): Governors reward winning artists of curation challenges.
 *
 * --- Governance & Reputation ---
 * 19. setGovernor(): Allows current governors to appoint new governors.
 * 20. proposeParameterChange(): Governors propose changes to contract parameters (e.g., royalty split).
 * 21. voteOnParameterChange(): Registered artists vote on proposed parameter changes.
 * 22. executeParameterChange(): Governors execute approved parameter changes.
 * 23. accrueReputation(): (Internal) Function to increase artist reputation based on activities.
 * 24. getArtistReputation(): Retrieves an artist's reputation score.
 *
 * --- Utility & Information ---
 * 25. getArtistProfile(): Retrieves an artist's profile information.
 * 26. getArtworkDetails(): Retrieves details of a specific artwork NFT.
 * 27. getCollectiveBalance(): Retrieves the contract's ETH balance.
 */

contract DecentralizedAutonomousArtCollective {

    // --- State Variables ---

    struct ArtistProfile {
        string artistName;
        string artistDescription;
        string artistWebsite;
        uint256 reputationScore;
        bool isRegistered;
    }

    struct Artwork {
        string artworkTitle;
        string artworkDescription;
        string artworkUri; // URI for the artwork metadata (e.g., IPFS)
        address artist;
        uint256 royaltyPercentage;
        uint256 mintTimestamp;
        bool isCollaborative;
        address[] collaborators;
    }

    struct GenerativeAlgorithm {
        string algorithmName;
        string algorithmDescription;
        string algorithmCode; // Simplified representation - in real world, could be URI/IPFS hash
        address artist;
        uint256 submissionTimestamp;
    }

    struct CollaborationProposal {
        address proposer;
        string proposalDescription;
        address[] invitedCollaborators;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
    }

    struct ExhibitionProposal {
        uint256 artworkId;
        address proposer;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
    }

    struct CurationChallenge {
        string challengeName;
        string challengeDescription;
        uint256 submissionDeadline;
        uint256 votingDeadline;
        uint256 rewardAmount;
        bool isActive;
        uint256 winnerArtworkId;
    }

    struct ParameterChangeProposal {
        string parameterName;
        string proposedValue;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isExecuted;
    }


    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => GenerativeAlgorithm) public generativeAlgorithms;
    mapping(uint256 => CollaborationProposal) public collaborationProposals;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => CurationChallenge) public curationChallenges;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;

    uint256 public artworkCount = 0;
    uint256 public algorithmCount = 0;
    uint256 public collaborationProposalCount = 0;
    uint256 public exhibitionProposalCount = 0;
    uint256 public curationChallengeCount = 0;
    uint256 public parameterChangeProposalCount = 0;

    address[] public governors;
    uint256 public minCollaborationVotes = 5; // Minimum votes to approve collaboration
    uint256 public minExhibitionVotes = 10; // Minimum votes to approve exhibition
    uint256 public minParameterChangeVotes = 15; // Minimum votes to approve parameter change
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public royaltySplitPercentage = 90; // Default royalty percentage for artists (90% to artist, 10% to collective)


    // --- Events ---
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string artistName);
    event AlgorithmSubmitted(uint256 algorithmId, address artistAddress, string algorithmName);
    event ArtworkMinted(uint256 artworkId, address artistAddress, string artworkTitle);
    event ArtworkTransferred(uint256 artworkId, address from, address to);
    event ArtworkRoyaltySet(uint256 artworkId, uint256 royaltyPercentage);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price, address artist, uint256 royaltyAmount, uint256 collectiveFee);
    event CollaborationProposalCreated(uint256 proposalId, address proposer, string description);
    event CollaborationProposalVoted(uint256 proposalId, address voter, bool vote);
    event CollaborationProposalAccepted(uint256 proposalId);
    event CollaborativeArtworkSubmitted(uint256 artworkId, address submitter, string artworkTitle);
    event ExhibitionProposalCreated(uint256 proposalId, uint256 artworkId, address proposer);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionProposalApproved(uint256 proposalId, uint256 artworkId);
    event CurationChallengeCreated(uint256 challengeId, string challengeName);
    event ArtworkSubmittedToChallenge(uint256 challengeId, uint256 artworkId, address artist);
    event ChallengeSubmissionVoted(uint256 challengeId, uint256 artworkId, address voter, bool vote);
    event ChallengeWinnersRewarded(uint256 challengeId, uint256 artworkId, address winnerArtist);
    event GovernorSet(address newGovernor, address setter);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, string proposedValue);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, string newValue);
    event ReputationAccrued(address artistAddress, uint256 reputationPoints, string activity);


    // --- Modifiers ---
    modifier onlyGovernor() {
        bool isGov = false;
        for (uint i = 0; i < governors.length; i++) {
            if (governors[i] == _msgSender()) {
                isGov = true;
                break;
            }
        }
        require(isGov, "Only governors can perform this action.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artistProfiles[_msgSender()].isRegistered, "Only registered artists can perform this action.");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Invalid artwork ID.");
        _;
    }

    modifier validAlgorithmId(uint256 _algorithmId) {
        require(_algorithmId > 0 && _algorithmId <= algorithmCount, "Invalid algorithm ID.");
        _;
    }

    modifier validCollaborationProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= collaborationProposalCount, "Invalid collaboration proposal ID.");
        _;
    }

    modifier validExhibitionProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= exhibitionProposalCount, "Invalid exhibition proposal ID.");
        _;
    }

    modifier validCurationChallengeId(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId <= curationChallengeCount, "Invalid curation challenge ID.");
        _;
    }

    modifier validParameterChangeProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= parameterChangeProposalCount, "Invalid parameter change proposal ID.");
        _;
    }

    modifier collaborationProposalActive(uint256 _proposalId) {
        require(collaborationProposals[_proposalId].isActive, "Collaboration proposal is not active.");
        require(block.timestamp < collaborationProposals[_proposalId].votingDeadline, "Collaboration proposal voting has ended.");
        _;
    }

    modifier exhibitionProposalActive(uint256 _proposalId) {
        require(exhibitionProposals[_proposalId].isActive, "Exhibition proposal is not active.");
        require(block.timestamp < exhibitionProposals[_proposalId].votingDeadline, "Exhibition proposal voting has ended.");
        _;
    }

    modifier curationChallengeActive(uint256 _challengeId) {
        require(curationChallenges[_challengeId].isActive, "Curation challenge is not active.");
        require(block.timestamp < curationChallenges[_challengeId].votingDeadline, "Curation challenge voting has ended.");
        _;
    }

    modifier parameterChangeProposalActive(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].isActive, "Parameter change proposal is not active.");
        require(block.timestamp < parameterChangeProposals[_proposalId].votingDeadline, "Parameter change proposal voting has ended.");
        _;
    }


    // --- Constructor ---
    constructor(address[] memory _initialGovernors) {
        require(_initialGovernors.length > 0, "At least one governor is required.");
        governors = _initialGovernors;
    }


    // --- Core Functionality ---

    function registerArtist(string memory _artistName, string memory _artistDescription, string memory _artistWebsite) public {
        require(!artistProfiles[_msgSender()].isRegistered, "Artist is already registered.");
        artistProfiles[_msgSender()] = ArtistProfile({
            artistName: _artistName,
            artistDescription: _artistDescription,
            artistWebsite: _artistWebsite,
            reputationScore: 0,
            isRegistered: true
        });
        emit ArtistRegistered(_msgSender(), _artistName);
    }

    function updateArtistProfile(string memory _artistName, string memory _artistDescription, string memory _artistWebsite) public onlyRegisteredArtist {
        artistProfiles[_msgSender()].artistName = _artistName;
        artistProfiles[_msgSender()].artistDescription = _artistDescription;
        artistProfiles[_msgSender()].artistWebsite = _artistWebsite;
        emit ArtistProfileUpdated(_msgSender(), _artistName);
    }

    function submitGenerativeArtAlgorithm(string memory _algorithmName, string memory _algorithmDescription, string memory _algorithmCode) public onlyRegisteredArtist {
        algorithmCount++;
        generativeAlgorithms[algorithmCount] = GenerativeAlgorithm({
            algorithmName: _algorithmName,
            algorithmDescription: _algorithmDescription,
            algorithmCode: _algorithmCode,
            artist: _msgSender(),
            submissionTimestamp: block.timestamp
        });
        emit AlgorithmSubmitted(algorithmCount, _msgSender(), _algorithmName);
        _accrueReputation(_msgSender(), 5, "Algorithm Submission"); // Reputation for submitting algorithm
    }

    // Simplified generative art execution - In real world, this would be much more complex (off-chain execution, oracles, etc.)
    function generateArtFromAlgorithm(uint256 _algorithmId, string memory _artworkTitle, string memory _artworkDescription, string memory _artworkUri, uint256 _royaltyPercentage) public onlyRegisteredArtist validAlgorithmId(_algorithmId) {
        require(generativeAlgorithms[_algorithmId].artist == _msgSender(), "Only the algorithm artist can generate art.");
        mintArtworkNFT(_artworkTitle, _artworkDescription, _artworkUri, _royaltyPercentage, false, new address[](0), _msgSender()); // Not collaborative, artist is the algorithm submitter
    }

    function mintArtworkNFT(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkUri, uint256 _royaltyPercentage, bool _isCollaborative, address[] memory _collaborators, address _artistOverride) private {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        artworkCount++;
        artworks[artworkCount] = Artwork({
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            artworkUri: _artworkUri,
            artist: (_artistOverride == address(0) ? _msgSender() : _artistOverride), // Allow overriding artist for collaborative works
            royaltyPercentage: _royaltyPercentage,
            mintTimestamp: block.timestamp,
            isCollaborative: _isCollaborative,
            collaborators: _collaborators
        });
        emit ArtworkMinted(artworkCount, (_artistOverride == address(0) ? _msgSender() : _artistOverride), _artworkTitle);
        _accrueReputation((_artistOverride == address(0) ? _msgSender() : _artistOverride), 10, "Artwork Minting"); // Reputation for minting artwork
    }

    function transferArtworkOwnership(uint256 _artworkId, address _to) public validArtworkId(_artworkId) {
        require(artworks[_artworkId].artist == _msgSender(), "You are not the owner of this artwork.");
        artworks[_artworkId].artist = _to;
        emit ArtworkTransferred(_artworkId, _msgSender(), _to);
    }

    function setArtworkRoyalty(uint256 _artworkId, uint256 _royaltyPercentage) public onlyRegisteredArtist validArtworkId(_artworkId) {
        require(artworks[_artworkId].artist == _msgSender(), "You are not the owner of this artwork.");
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        artworks[_artworkId].royaltyPercentage = _royaltyPercentage;
        emit ArtworkRoyaltySet(_artworkId, _royaltyPercentage);
    }

    function purchaseArtwork(uint256 _artworkId) public payable validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.artist != _msgSender(), "You cannot purchase your own artwork.");
        uint256 price = msg.value; // Price is determined by msg.value sent by the buyer
        uint256 royaltyAmount = (price * artwork.royaltyPercentage) / 100;
        uint256 collectiveFee = price - royaltyAmount;

        payable(artwork.artist).transfer(royaltyAmount); // Send royalty to artist
        payable(address(this)).transfer(collectiveFee);   // Send collective fee to contract

        artwork.artist = _msgSender(); // New owner is the buyer
        emit ArtworkPurchased(_artworkId, _msgSender(), price, artwork.artist, royaltyAmount, collectiveFee);
        _accrueReputation(artwork.artist, 2, "Artwork Purchase"); // Reputation for purchasing artwork
        _accrueReputation(artwork.artist, 8, "Artwork Sale"); // Reputation for selling artwork
    }


    // --- Collaborative & Curation Features ---

    function createCollaborationProposal(string memory _proposalDescription, address[] memory _invitedCollaborators) public onlyRegisteredArtist {
        collaborationProposalCount++;
        collaborationProposals[collaborationProposalCount] = CollaborationProposal({
            proposer: _msgSender(),
            proposalDescription: _proposalDescription,
            invitedCollaborators: _invitedCollaborators,
            votingDeadline: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            isActive: true
        });
        emit CollaborationProposalCreated(collaborationProposalCount, _msgSender(), _proposalDescription);
        _accrueReputation(_msgSender(), 3, "Collaboration Proposal Creation"); // Reputation for creating proposal
    }

    function voteOnCollaborationProposal(uint256 _proposalId, bool _vote) public onlyRegisteredArtist validCollaborationProposalId(_proposalId) collaborationProposalActive(_proposalId) {
        CollaborationProposal storage proposal = collaborationProposals[_proposalId];
        bool isInvited = false;
        for (uint i = 0; i < proposal.invitedCollaborators.length; i++) {
            if (proposal.invitedCollaborators[i] == _msgSender()) {
                isInvited = true;
                break;
            }
        }
        require(isInvited || proposal.proposer == _msgSender(), "You are not invited to vote on this collaboration.");
        require(proposal.isActive, "Collaboration proposal is not active.");

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit CollaborationProposalVoted(_proposalId, _msgSender(), _vote);

        if (proposal.yesVotes >= minCollaborationVotes) {
            proposal.isActive = false; // Mark as accepted
            emit CollaborationProposalAccepted(_proposalId);
        } else if (proposal.noVotes > proposal.invitedCollaborators.length - minCollaborationVotes + 1 || block.timestamp >= proposal.votingDeadline) {
            proposal.isActive = false; // Mark as rejected if enough no votes or voting time ends
        }
        _accrueReputation(_msgSender(), 1, "Collaboration Proposal Vote"); // Reputation for voting
    }

    function acceptCollaborationInvite(uint256 _proposalId) public onlyRegisteredArtist validCollaborationProposalId(_proposalId) collaborationProposalActive(_proposalId) {
        CollaborationProposal storage proposal = collaborationProposals[_proposalId];
        bool isInvited = false;
        for (uint i = 0; i < proposal.invitedCollaborators.length; i++) {
            if (proposal.invitedCollaborators[i] == _msgSender()) {
                isInvited = true;
                break;
            }
        }
        require(isInvited, "You were not invited to this collaboration.");
        voteOnCollaborationProposal(_proposalId, true); // Automatically vote yes when accepting invite
    }


    function submitCollaborativeArtwork(uint256 _proposalId, string memory _artworkTitle, string memory _artworkDescription, string memory _artworkUri, uint256 _royaltyPercentage) public onlyRegisteredArtist validCollaborationProposalId(_proposalId) {
        CollaborationProposal storage proposal = collaborationProposals[_proposalId];
        require(!proposal.isActive, "Collaboration proposal must be accepted before submitting artwork."); // Ensure proposal is accepted
        require(proposal.yesVotes >= minCollaborationVotes, "Collaboration proposal was not sufficiently approved.");

        bool isProposerOrInvited = (proposal.proposer == _msgSender());
        if (!isProposerOrInvited) {
            for (uint i = 0; i < proposal.invitedCollaborators.length; i++) {
                if (proposal.invitedCollaborators[i] == _msgSender()) {
                    isProposerOrInvited = true;
                    break;
                }
            }
        }
        require(isProposerOrInvited, "Only proposer or invited collaborators can submit collaborative artwork.");

        address[] memory collaborators = new address[](proposal.invitedCollaborators.length + 1); // Include proposer as collaborator too
        collaborators[0] = proposal.proposer;
        for (uint i = 0; i < proposal.invitedCollaborators.length; i++) {
            collaborators[i+1] = proposal.invitedCollaborators[i];
        }

        mintArtworkNFT(_artworkTitle, _artworkDescription, _artworkUri, _royaltyPercentage, true, collaborators, proposal.proposer); // Proposer is the primary artist for royalty distribution
        emit CollaborativeArtworkSubmitted(artworkCount, _msgSender(), _artworkTitle);
        _accrueReputation(_msgSender(), 15, "Collaborative Artwork Submission"); // Higher reputation for collaborative work
    }


    function proposeArtworkForExhibition(uint256 _artworkId) public onlyRegisteredArtist validArtworkId(_artworkId) {
        require(artworks[_artworkId].artist == _msgSender(), "You must own the artwork to propose it for exhibition.");
        exhibitionProposalCount++;
        exhibitionProposals[exhibitionProposalCount] = ExhibitionProposal({
            artworkId: _artworkId,
            proposer: _msgSender(),
            votingDeadline: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            isActive: true
        });
        emit ExhibitionProposalCreated(exhibitionProposalCount, _artworkId, _msgSender());
        _accrueReputation(_msgSender(), 2, "Exhibition Proposal Creation"); // Reputation for exhibition proposal
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) public onlyRegisteredArtist validExhibitionProposalId(_proposalId) exhibitionProposalActive(_proposalId) {
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        require(proposal.isActive, "Exhibition proposal is not active.");

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ExhibitionProposalVoted(_proposalId, _msgSender(), _vote);

        if (proposal.yesVotes >= minExhibitionVotes) {
            proposal.isActive = false; // Mark as approved
            emit ExhibitionProposalApproved(_proposalId, proposal.artworkId);
        } else if (proposal.noVotes > artistProfiles.length() - minExhibitionVotes + 1 || block.timestamp >= proposal.votingDeadline) {
            proposal.isActive = false; // Mark as rejected if enough no votes or voting time ends
        }
        _accrueReputation(_msgSender(), 1, "Exhibition Proposal Vote"); // Reputation for voting
    }


    function createCurationChallenge(string memory _challengeName, string memory _challengeDescription, uint256 _submissionDays, uint256 _votingDays, uint256 _rewardAmount) public onlyGovernor {
        require(_submissionDays > 0 && _votingDays > 0, "Submission and voting days must be positive.");
        require(_rewardAmount > 0, "Reward amount must be positive.");
        curationChallengeCount++;
        curationChallenges[curationChallengeCount] = CurationChallenge({
            challengeName: _challengeName,
            challengeDescription: _challengeDescription,
            submissionDeadline: block.timestamp + (_submissionDays * 1 days),
            votingDeadline: block.timestamp + (_submissionDays + _votingDays) * 1 days,
            rewardAmount: _rewardAmount,
            isActive: true,
            winnerArtworkId: 0 // No winner yet
        });
        emit CurationChallengeCreated(curationChallengeCount, _challengeName);
    }

    function submitArtworkToChallenge(uint256 _challengeId, uint256 _artworkId) public onlyRegisteredArtist validCurationChallengeId(_challengeId) validArtworkId(_artworkId) curationChallengeActive(_challengeId) {
        CurationChallenge storage challenge = curationChallenges[_challengeId];
        require(block.timestamp < challenge.submissionDeadline, "Curation challenge submission deadline has passed.");
        require(artworks[_artworkId].artist == _msgSender(), "You must own the artwork to submit to the challenge.");
        // In a real-world scenario, we might want to check if the artwork is thematically relevant to the challenge here.

        emit ArtworkSubmittedToChallenge(_challengeId, _artworkId, _msgSender());
        _accrueReputation(_msgSender(), 4, "Challenge Artwork Submission"); // Reputation for submitting to challenge
    }

    function voteOnChallengeSubmission(uint256 _challengeId, uint256 _artworkId, bool _vote) public onlyRegisteredArtist validCurationChallengeId(_challengeId) validArtworkId(_artworkId) curationChallengeActive(_challengeId) {
        CurationChallenge storage challenge = curationChallenges[_challengeId];
        require(block.timestamp >= challenge.submissionDeadline && block.timestamp < challenge.votingDeadline, "Curation challenge voting period is not active.");
        require(challenge.isActive, "Curation challenge is not active.");
        // In a real-world scenario, we would likely track votes per artwork per challenge to determine the winner.
        // For simplicity here, we'll just count votes and determine a winner based on the total yes votes.

        if (_vote) {
            // Simple voting logic - in real world, would need to track votes per artwork and determine winner
            // For simplicity, we just increment a "yes vote" count for the challenge, and winner determination would be more complex
            // (e.g., track votes per artwork and find the artwork with the most yes votes).
            // This example skips tracking votes per artwork for brevity.
            // In a real-world scenario, you'd likely need a mapping from challengeId to artworkId to vote count.
        }
        emit ChallengeSubmissionVoted(_challengeId, _artworkId, _msgSender(), _vote);
        _accrueReputation(_msgSender(), 1, "Challenge Submission Vote"); // Reputation for voting
    }

    function rewardChallengeWinners(uint256 _challengeId, uint256 _winnerArtworkId) public onlyGovernor validCurationChallengeId(_challengeId) validArtworkId(_winnerArtworkId) {
        CurationChallenge storage challenge = curationChallenges[_challengeId];
        require(block.timestamp >= challenge.votingDeadline, "Curation challenge voting is not yet finished.");
        require(challenge.isActive, "Curation challenge is not active.");
        require(challenge.winnerArtworkId == 0, "Challenge winner has already been rewarded.");
        require(artworks[_winnerArtworkId].artist != address(0), "Invalid winner artwork or artist.");

        challenge.isActive = false; // Mark challenge as completed
        challenge.winnerArtworkId = _winnerArtworkId;

        payable(artworks[_winnerArtworkId].artist).transfer(challenge.rewardAmount);
        emit ChallengeWinnersRewarded(_challengeId, _winnerArtworkId, artworks[_winnerArtworkId].artist);
        _accrueReputation(artworks[_winnerArtworkId].artist, 20, "Curation Challenge Win"); // Significant reputation for winning
    }



    // --- Governance & Reputation ---

    function setGovernor(address _newGovernor) public onlyGovernor {
        governors.push(_newGovernor);
        emit GovernorSet(_newGovernor, _msgSender());
    }

    function proposeParameterChange(string memory _parameterName, string memory _proposedValue) public onlyGovernor {
        parameterChangeProposalCount++;
        parameterChangeProposals[parameterChangeProposalCount] = ParameterChangeProposal({
            parameterName: _parameterName,
            proposedValue: _proposedValue,
            votingDeadline: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            isExecuted: false
        });
        emit ParameterChangeProposed(parameterChangeProposalCount, _parameterName, _proposedValue);
        _accrueReputation(_msgSender(), 2, "Parameter Change Proposal Creation"); // Reputation for parameter proposal
    }

    function voteOnParameterChange(uint256 _proposalId, bool _vote) public onlyRegisteredArtist validParameterChangeProposalId(_proposalId) parameterChangeProposalActive(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.isActive, "Parameter change proposal is not active.");

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ParameterChangeVoted(_proposalId, _msgSender(), _vote);

        if (proposal.yesVotes >= minParameterChangeVotes) {
            proposal.isActive = false; // Mark as approved
        } else if (proposal.noVotes > artistProfiles.length() - minParameterChangeVotes + 1 || block.timestamp >= proposal.votingDeadline) {
            proposal.isActive = false; // Mark as rejected if enough no votes or voting time ends
        }
        _accrueReputation(_msgSender(), 1, "Parameter Change Vote"); // Reputation for voting
    }

    function executeParameterChange(uint256 _proposalId) public onlyGovernor validParameterChangeProposalId(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(!proposal.isActive, "Parameter change proposal is not active (already finalized or not approved yet).");
        require(!proposal.isExecuted, "Parameter change proposal already executed.");
        require(proposal.yesVotes >= minParameterChangeVotes, "Parameter change proposal was not approved.");

        proposal.isExecuted = true;
        if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("minCollaborationVotes"))) {
            minCollaborationVotes = uint256(parseInt(proposal.proposedValue));
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("minExhibitionVotes"))) {
            minExhibitionVotes = uint256(parseInt(proposal.proposedValue));
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("minParameterChangeVotes"))) {
            minParameterChangeVotes = uint256(parseInt(proposal.proposedValue));
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("votingDuration"))) {
            votingDuration = uint256(parseInt(proposal.proposedValue));
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("royaltySplitPercentage"))) {
            royaltySplitPercentage = uint256(parseInt(proposal.proposedValue));
        } else {
            revert("Unknown parameter to change.");
        }
        emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.proposedValue);
    }

    // Internal function to accrue reputation - simplified system
    function _accrueReputation(address _artist, uint256 _points, string memory _activity) internal {
        if (artistProfiles[_artist].isRegistered) {
            artistProfiles[_artist].reputationScore += _points;
            emit ReputationAccrued(_artist, _points, _activity);
        }
    }

    function getArtistReputation(address _artist) public view returns (uint256) {
        return artistProfiles[_artist].reputationScore;
    }


    // --- Utility & Information ---

    function getArtistProfile(address _artist) public view returns (ArtistProfile memory) {
        return artistProfiles[_artist];
    }

    function getArtworkDetails(uint256 _artworkId) public view validArtworkId(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getCollectiveBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Helper function to parse string to uint (for parameter changes) ---
    function parseInt(string memory _str) internal pure returns (uint) {
        uint result = 0;
        bytes memory bytesStr = bytes(_str);
        for (uint i = 0; i < bytesStr.length; i++) {
            uint digit = uint(bytesStr[i]) - uint(uint8('0'));
            if (digit > 9) {
                revert("Invalid character in string for integer conversion");
            }
            result = result * 10 + digit;
        }
        return result;
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```