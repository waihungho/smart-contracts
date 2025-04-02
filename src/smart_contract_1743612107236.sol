```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Conceptual Smart Contract)
 * @dev A smart contract for a decentralized autonomous art collective, enabling collaborative art creation,
 * governance, curation, and innovative functionalities. This contract aims to explore advanced concepts
 * and provide a creative platform for digital art within the blockchain ecosystem.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Collective Governance & Membership:**
 *     - `joinCollective(string _artistStatement)`: Allows artists to request membership by submitting a statement.
 *     - `leaveCollective()`: Allows members to leave the collective.
 *     - `approveMembership(address _artist)`: Governor function to approve pending membership requests.
 *     - `revokeMembership(address _member)`: Governor function to revoke membership.
 *     - `getMemberDetails(address _member)`: Retrieves details of a member (statement, join date, etc.).
 *     - `getMemberList()`: Returns a list of all collective members.
 *     - `isMember(address _user)`: Checks if an address is a member of the collective.
 *     - `setGovernanceParameters(uint256 _quorumPercentage, uint256 _votingDuration)`: Governor function to set governance parameters.
 *
 * **2. Collaborative Art Creation & Management (Staged Art):**
 *     - `createArtStage(string _stageTitle, string _stageDescription, uint256 _submissionDeadline)`: Members propose and create new stages for collaborative artworks.
 *     - `submitArtLayer(uint256 _stageId, string _layerCID, string _layerDescription)`: Members submit layers of art (IPFS CID) for a specific stage.
 *     - `voteOnArtLayer(uint256 _stageId, uint256 _layerIndex, bool _approve)`: Members vote on submitted art layers for a stage.
 *     - `finalizeArtStage(uint256 _stageId)`: Governor function to finalize an art stage after voting, selecting approved layers.
 *     - `mintCollectiveArtwork(string _artworkTitle, string _artworkDescription, uint256[] _stageIds)`: Governor function to mint a finalized collective artwork NFT from completed stages.
 *     - `getStageDetails(uint256 _stageId)`: Retrieves details of an art stage.
 *     - `getLayersForStage(uint256 _stageId)`: Retrieves submitted layers for a stage.
 *     - `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a minted collective artwork.
 *
 * **3. Reputation & Contribution System (Dynamic Reputation Score):**
 *     - `contributeToStage(uint256 _stageId)`:  Members gain reputation by participating in art stages (submission, voting).
 *     - `upvoteLayerContribution(uint256 _stageId, uint256 _layerIndex)`: Members can upvote valuable layer contributions, increasing contributor reputation.
 *     - `reportLayerContribution(uint256 _stageId, uint256 _layerIndex, string _reportReason)`: Members can report inappropriate contributions, potentially decreasing contributor reputation (governor review needed).
 *     - `getMemberReputation(address _member)`: Retrieves the reputation score of a member.
 *
 * **4. Dynamic Art & Evolving NFTs (Concept - Requires External Oracle/Service):**
 *     - `setArtworkDynamicProperty(uint256 _artworkId, string _propertyName, string _propertyValue)`: Governor function to set dynamic properties of an artwork (e.g., mood, season) that could be updated by an external oracle.
 *     - `triggerArtworkEvolution(uint256 _artworkId, string _evolutionEvent)`: Governor function to trigger an evolution event for an artwork, potentially changing its metadata or visual representation based on predefined rules.
 *
 * **5. DAO Treasury & Funding (Simple Model):**
 *     - `depositToTreasury()` payable: Members or external entities can deposit funds to the collective treasury.
 *     - `proposeTreasurySpending(address _recipient, uint256 _amount, string _proposalDescription)`: Members propose spending from the treasury.
 *     - `voteOnTreasuryProposal(uint256 _proposalId, bool _approve)`: Members vote on treasury spending proposals.
 *     - `executeTreasurySpending(uint256 _proposalId)`: Governor function to execute approved treasury spending proposals.
 *     - `getTreasuryBalance()` view: Returns the current balance of the collective treasury.
 *
 * **6.  Decentralized Curation & Gallery (On-Chain Curation):**
 *     - `proposeArtworkForGallery(uint256 _artworkId, string _galleryDescription)`: Members propose collective artworks to be featured in the on-chain gallery.
 *     - `voteOnGalleryProposal(uint256 _proposalId, bool _approve)`: Members vote on proposals to add artworks to the gallery.
 *     - `addArtworkToGallery(uint256 _proposalId)`: Governor function to add approved artworks to the on-chain gallery.
 *     - `removeFromGallery(uint256 _artworkId)`: Governor function to remove artworks from the gallery.
 *     - `getGalleryArtworks()`: Returns a list of artwork IDs currently in the gallery.
 *
 * **7.  Advanced Features (Conceptual & Extensible):**
 *     - `setExternalDataFeed(address _dataFeedContract)`: Governor function to set an external data feed contract for dynamic art properties (concept).
 *     - `registerArtStyle(string _styleName, string _styleDescription)`: Governor function to register different art styles that can be associated with stages or artworks (concept).
 *     - `getArtStyleDetails(uint256 _styleId)`: Retrieves details of a registered art style (concept).
 *     - `createCustomVotingRule(string _ruleName, bytes _ruleLogic)`: Governor function to define custom voting rules for specific proposals (advanced governance - concept).
 *
 * **Note:** This is a conceptual smart contract and might require further development, security audits, and gas optimization for production use. Some advanced features like dynamic art and custom voting rules are simplified concepts and would require more complex implementation and potentially external services.
 */
contract DecentralizedAutonomousArtCollective {

    // **** STRUCTS & ENUMS ****
    struct Member {
        address artistAddress;
        string artistStatement;
        uint256 joinDate;
        uint256 reputationScore;
        bool isActive;
    }

    struct ArtStage {
        uint256 stageId;
        string stageTitle;
        string stageDescription;
        uint256 submissionDeadline;
        address creator;
        bool isFinalized;
        uint256 layerCount;
    }

    struct ArtLayer {
        uint256 layerId;
        uint256 stageId;
        address artist;
        string layerCID;
        string layerDescription;
        uint256 upvotes;
        uint256 downvotes; // Could be used for negative reputation impact
        bool isApproved; // After voting
    }

    struct CollectiveArtwork {
        uint256 artworkId;
        string artworkTitle;
        string artworkDescription;
        uint256[] stageIds;
        address minter;
        uint256 mintDate;
        // Dynamic Properties (Concept)
        mapping(string => string) dynamicProperties;
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        string description;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isExecuted;
        bytes proposalData; // Generic data for different proposal types
    }

    enum ProposalType {
        MEMBERSHIP_APPROVAL,
        TREASURY_SPENDING,
        ART_STAGE_FINALIZATION,
        GALLERY_ADDITION,
        GOVERNANCE_PARAMETER_CHANGE,
        CUSTOM // For future extensibility
    }


    // **** STATE VARIABLES ****
    address public governor; // Address with governance rights
    uint256 public membershipFee; // Fee to join the collective (optional)
    uint256 public quorumPercentage = 50; // Default quorum for proposals (e.g., 50%)
    uint256 public votingDuration = 7 days; // Default voting duration

    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public memberCount = 0;

    mapping(uint256 => ArtStage) public artStages;
    uint256 public stageCount = 0;
    mapping(uint256 => mapping(uint256 => ArtLayer)) public artLayers; // stageId => layerIndex => ArtLayer
    uint256 public layerCount = 0;

    mapping(uint256 => CollectiveArtwork) public collectiveArtworks;
    uint256 public artworkCount = 0;

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount = 0;

    mapping(uint256 => bool) public galleryArtworks; // artworkId => isInGallery

    // Reputation System
    mapping(address => uint256) public memberReputation;
    uint256 public reputationGainOnContribution = 10;
    uint256 public reputationGainOnUpvote = 1;
    uint256 public reputationLossOnReport = 5; // Governor reviewed report


    // **** EVENTS ****
    event MembershipRequested(address artist, string statement);
    event MembershipApproved(address artist);
    event MembershipRevoked(address member);
    event MemberLeft(address member);

    event ArtStageCreated(uint256 stageId, string title, address creator);
    event ArtLayerSubmitted(uint256 stageId, uint256 layerId, address artist, string layerCID);
    event ArtLayerVoted(uint256 stageId, uint256 layerId, address voter, bool approve);
    event ArtStageFinalized(uint256 stageId);
    event CollectiveArtworkMinted(uint256 artworkId, string title, address minter);

    event TreasuryDeposit(address sender, uint256 amount);
    event TreasurySpendingProposed(uint256 proposalId, address recipient, uint256 amount, string description);
    event TreasurySpendingExecuted(uint256 proposalId, address recipient, uint256 amount);

    event ArtworkProposedForGallery(uint256 proposalId, uint256 artworkId, string description);
    event ArtworkAddedToGallery(uint256 artworkId);
    event ArtworkRemovedFromGallery(uint256 artworkId);

    event DynamicArtworkPropertySet(uint256 artworkId, string propertyName, string propertyValue);
    event ArtworkEvolutionTriggered(uint256 artworkId, string evolutionEvent);

    event ReputationIncreased(address member, uint256 amount, string reason);
    event ReputationDecreased(address member, uint256 amount, string reason);
    event LayerContributionUpvoted(uint256 stageId, uint256 layerId, address upvoter);
    event LayerContributionReported(uint256 stageId, uint256 layerId, address reporter, string reason);

    event GovernanceParametersSet(uint256 quorumPercentage, uint256 votingDuration);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType);


    // **** MODIFIERS ****
    modifier onlyGovernor() {
        require(msg.sender == governor, "Only governor can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only collective members can call this function.");
        _;
    }

    modifier stageExists(uint256 _stageId) {
        require(artStages[_stageId].stageId == _stageId, "Art stage does not exist.");
        _;
    }

    modifier layerExists(uint256 _stageId, uint256 _layerIndex) {
        require(artLayers[_stageId][_layerIndex].layerId == _layerIndex && artLayers[_stageId][_layerIndex].stageId == _stageId, "Art layer does not exist in this stage.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(collectiveArtworks[_artworkId].artworkId == _artworkId, "Collective artwork does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].votingStartTime && block.timestamp <= proposals[_proposalId].votingEndTime, "Voting is not active for this proposal.");
        _;
    }

    modifier votingNotStarted(uint256 _proposalId) {
        require(block.timestamp < proposals[_proposalId].votingStartTime, "Voting has already started.");
        _;
    }

    modifier votingNotEnded(uint256 _proposalId) {
        require(block.timestamp <= proposals[_proposalId].votingEndTime, "Voting has already ended.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].isExecuted, "Proposal has already been executed.");
        _;
    }


    // **** CONSTRUCTOR ****
    constructor() {
        governor = msg.sender; // Deployer is initial governor
    }


    // **** 1. CORE COLLECTIVE GOVERNANCE & MEMBERSHIP ****
    function joinCollective(string memory _artistStatement) public {
        require(!isMember(msg.sender), "Already a member.");
        require(bytes(_artistStatement).length > 0, "Artist statement cannot be empty.");

        // Membership fee logic can be added here if needed
        // e.g., require(msg.value >= membershipFee, "Membership fee is required.");

        // Create a membership request proposal
        uint256 proposalId = _createProposal(
            ProposalType.MEMBERSHIP_APPROVAL,
            msg.sender,
            "Membership Request for "
        );
        proposals[proposalId].proposalData = abi.encode(msg.sender); // Store artist address in proposal data

        emit MembershipRequested(msg.sender, _artistStatement);
    }

    function leaveCollective() public onlyMember {
        _revokeMembershipInternal(msg.sender);
        emit MemberLeft(msg.sender);
    }

    function approveMembership(address _artist) public onlyGovernor {
        require(!isMember(_artist), "Artist is already a member.");

        // Find the membership approval proposal (inefficient in large scale, consider indexing)
        uint256 proposalIdToExecute = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].proposalType == ProposalType.MEMBERSHIP_APPROVAL &&
                !proposals[i].isExecuted &&
                address(abi.decode(proposals[i].proposalData, (address))) == _artist) {
                proposalIdToExecute = i;
                break;
            }
        }
        require(proposalIdToExecute != 0, "Membership approval proposal not found or already executed.");

        // Execute the proposal (effectively approving membership)
        _executeProposal(proposalIdToExecute);

        members[_artist] = Member({
            artistAddress: _artist,
            artistStatement: "", // Statement would be stored off-chain or in a separate mapping for efficiency
            joinDate: block.timestamp,
            reputationScore: 0,
            isActive: true
        });
        memberList.push(_artist);
        memberCount++;
        emit MembershipApproved(_artist);
    }

    function revokeMembership(address _member) public onlyGovernor {
        require(isMember(_member), "Not a member.");
        _revokeMembershipInternal(_member);
        emit MembershipRevoked(_member);
    }

    function _revokeMembershipInternal(address _member) private {
        members[_member].isActive = false;
        // Remove from memberList (inefficient for large lists, consider alternative data structures)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                memberCount--;
                break;
            }
        }
    }

    function getMemberDetails(address _member) public view returns (Member memory) {
        require(isMember(_member), "Not a member.");
        return members[_member];
    }

    function getMemberList() public view returns (address[] memory) {
        return memberList;
    }

    function isMember(address _user) public view returns (bool) {
        return members[_user].isActive;
    }

    function setGovernanceParameters(uint256 _quorumPercentage, uint256 _votingDuration) public onlyGovernor {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        require(_votingDuration > 0, "Voting duration must be greater than 0.");
        quorumPercentage = _quorumPercentage;
        votingDuration = _votingDuration;
        emit GovernanceParametersSet(_quorumPercentage, _votingDuration);
    }


    // **** 2. COLLABORATIVE ART CREATION & MANAGEMENT (Staged Art) ****
    function createArtStage(string memory _stageTitle, string memory _stageDescription, uint256 _submissionDeadline) public onlyMember {
        require(bytes(_stageTitle).length > 0 && bytes(_stageDescription).length > 0, "Stage title and description cannot be empty.");
        require(_submissionDeadline > block.timestamp, "Submission deadline must be in the future.");

        stageCount++;
        artStages[stageCount] = ArtStage({
            stageId: stageCount,
            stageTitle: _stageTitle,
            stageDescription: _stageDescription,
            submissionDeadline: _submissionDeadline,
            creator: msg.sender,
            isFinalized: false,
            layerCount: 0
        });
        emit ArtStageCreated(stageCount, _stageTitle, msg.sender);
    }

    function submitArtLayer(uint256 _stageId, string memory _layerCID, string memory _layerDescription) public onlyMember stageExists(_stageId) {
        require(!artStages[_stageId].isFinalized, "Stage is already finalized, cannot submit layers.");
        require(block.timestamp <= artStages[_stageId].submissionDeadline, "Submission deadline has passed.");
        require(bytes(_layerCID).length > 0 && bytes(_layerDescription).length > 0, "Layer CID and description cannot be empty.");

        layerCount++;
        uint256 layerIndex = artStages[_stageId].layerCount;
        artLayers[_stageId][layerIndex] = ArtLayer({
            layerId: layerIndex,
            stageId: _stageId,
            artist: msg.sender,
            layerCID: _layerCID,
            layerDescription: _layerDescription,
            upvotes: 0,
            downvotes: 0,
            isApproved: false
        });
        artStages[_stageId].layerCount++;
        emit ArtLayerSubmitted(_stageId, layerIndex, msg.sender, _layerCID);
        _increaseMemberReputation(msg.sender, reputationGainOnContribution, "Art Layer Submission");
    }

    function voteOnArtLayer(uint256 _stageId, uint256 _layerIndex, bool _approve) public onlyMember stageExists(_stageId) layerExists(_stageId, _layerIndex) {
        require(!artStages[_stageId].isFinalized, "Stage is already finalized, voting is closed.");
        require(block.timestamp <= artStages[_stageId].submissionDeadline, "Voting deadline has passed."); // Voting happens within submission window for simplicity

        if (_approve) {
            artLayers[_stageId][_layerIndex].upvotes++;
        } else {
            artLayers[_stageId][_layerIndex].downvotes++; // Could be used for negative reputation later
        }
        emit ArtLayerVoted(_stageId, _layerIndex, msg.sender, _approve);
        _increaseMemberReputation(msg.sender, reputationGainOnContribution, "Art Layer Vote");
    }

    function finalizeArtStage(uint256 _stageId) public onlyGovernor stageExists(_stageId) {
        require(!artStages[_stageId].isFinalized, "Art stage already finalized.");
        require(block.timestamp > artStages[_stageId].submissionDeadline, "Submission deadline has not passed yet."); // Finalize after submission ends

        uint256 approvedLayerCount = 0;
        for (uint256 i = 0; i < artStages[_stageId].layerCount; i++) {
            // Simple approval logic: more upvotes than downvotes (can be customized)
            if (artLayers[_stageId][i].upvotes > artLayers[_stageId][i].downvotes) {
                artLayers[_stageId][i].isApproved = true;
                approvedLayerCount++;
            } else {
                artLayers[_stageId][i].isApproved = false; // Explicitly set to false for clarity
            }
        }

        artStages[_stageId].isFinalized = true;
        emit ArtStageFinalized(_stageId);
    }

    function mintCollectiveArtwork(string memory _artworkTitle, string memory _artworkDescription, uint256[] memory _stageIds) public onlyGovernor {
        require(bytes(_artworkTitle).length > 0 && bytes(_artworkDescription).length > 0, "Artwork title and description cannot be empty.");
        require(_stageIds.length > 0, "Artwork must include at least one stage.");

        for (uint256 i = 0; i < _stageIds.length; i++) {
            require(artStages[_stageIds[i]].isFinalized, "All stages must be finalized before minting artwork.");
        }

        artworkCount++;
        collectiveArtworks[artworkCount] = CollectiveArtwork({
            artworkId: artworkCount,
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            stageIds: _stageIds,
            minter: msg.sender,
            mintDate: block.timestamp
        });
        emit CollectiveArtworkMinted(artworkCount, _artworkTitle, msg.sender);

        // Here you would typically integrate with an NFT contract to actually mint the NFT
        // For simplicity, this example just tracks the artwork on-chain.
        // Example NFT minting call (conceptual):
        // ERC721Contract.mint(artworkCount, metadataURI); // metadataURI would point to IPFS data for the artwork
    }

    function getStageDetails(uint256 _stageId) public view stageExists(_stageId) returns (ArtStage memory) {
        return artStages[_stageId];
    }

    function getLayersForStage(uint256 _stageId) public view stageExists(_stageId) returns (ArtLayer[] memory) {
        ArtLayer[] memory layers = new ArtLayer[](artStages[_stageId].layerCount);
        for (uint256 i = 0; i < artStages[_stageId].layerCount; i++) {
            layers[i] = artLayers[_stageId][i];
        }
        return layers;
    }

    function getArtworkDetails(uint256 _artworkId) public view artworkExists(_artworkId) returns (CollectiveArtwork memory) {
        return collectiveArtworks[_artworkId];
    }


    // **** 3. REPUTATION & CONTRIBUTION SYSTEM (Dynamic Reputation Score) ****
    function contributeToStage(uint256 _stageId) public onlyMember stageExists(_stageId) {
        // Example contribution function (can be expanded - e.g., participating in discussions, etc.)
        _increaseMemberReputation(msg.sender, reputationGainOnContribution, "Stage Contribution");
    }

    function upvoteLayerContribution(uint256 _stageId, uint256 _layerIndex) public onlyMember stageExists(_stageId) layerExists(_stageId, _layerIndex) {
        require(artLayers[_stageId][_layerIndex].artist != msg.sender, "Cannot upvote your own layer.");
        artLayers[_stageId][_layerIndex].upvotes++;
        _increaseMemberReputation(artLayers[_stageId][_layerIndex].artist, reputationGainOnUpvote, "Layer Upvote Received");
        emit LayerContributionUpvoted(_stageId, _layerIndex, msg.sender);
    }

    function reportLayerContribution(uint256 _stageId, uint256 _layerIndex, string memory _reportReason) public onlyMember stageExists(_stageId) layerExists(_stageId, _layerIndex) {
        require(artLayers[_stageId][_layerIndex].artist != msg.sender, "Cannot report your own layer.");
        // Reporting mechanism - could trigger governor review and reputation decrease
        // For simplicity, just emit an event for now. Governor could have a function to review reports and decrease reputation.
        emit LayerContributionReported(_stageId, _layerIndex, msg.sender, _reportReason);
    }

    function getMemberReputation(address _member) public view returns (uint256) {
        return memberReputation[_member];
    }

    function _increaseMemberReputation(address _member, uint256 _amount, string memory _reason) private {
        memberReputation[_member] += _amount;
        emit ReputationIncreased(_member, _amount, _reason);
    }

    function _decreaseMemberReputation(address _member, uint256 _amount, string memory _reason) private onlyGovernor { // Governor controlled reputation decrease
        memberReputation[_member] -= _amount;
        emit ReputationDecreased(_member, _amount, _reason);
    }


    // **** 4. DYNAMIC ART & EVOLVING NFTs (Concept - Requires External Oracle/Service) ****
    function setArtworkDynamicProperty(uint256 _artworkId, string memory _propertyName, string memory _propertyValue) public onlyGovernor artworkExists(_artworkId) {
        collectiveArtworks[_artworkId].dynamicProperties[_propertyName] = _propertyValue;
        emit DynamicArtworkPropertySet(_artworkId, _propertyName, _propertyValue);
    }

    function triggerArtworkEvolution(uint256 _artworkId, string memory _evolutionEvent) public onlyGovernor artworkExists(_artworkId) {
        // Concept: This function could trigger changes to the artwork's metadata or visual representation
        // based on the _evolutionEvent. This would likely require off-chain services or oracles to update the actual NFT.
        emit ArtworkEvolutionTriggered(_artworkId, _evolutionEvent);
    }


    // **** 5. DAO TREASURY & FUNDING (Simple Model) ****
    function depositToTreasury() public payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _proposalDescription) public onlyMember {
        require(_recipient != address(0), "Recipient address cannot be zero address.");
        require(_amount > 0, "Spending amount must be greater than 0.");
        require(address(this).balance >= _amount, "Treasury balance is insufficient.");

        uint256 proposalId = _createProposal(
            ProposalType.TREASURY_SPENDING,
            msg.sender,
            _proposalDescription
        );
        proposals[proposalId].proposalData = abi.encode(_recipient, _amount); // Store recipient and amount
        emit TreasurySpendingProposed(proposalId, _recipient, _amount, _proposalDescription);
    }

    function voteOnTreasuryProposal(uint256 _proposalId, bool _approve) public onlyMember proposalExists(_proposalId) votingActive(_proposalId) votingNotEnded(_proposalId) proposalNotExecuted(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.TREASURY_SPENDING, "Invalid proposal type for treasury voting.");
        require(!hasVoted(msg.sender, _proposalId), "Member has already voted on this proposal.");
        recordVote(msg.sender, _proposalId); // Mark as voted

        if (_approve) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    function executeTreasurySpending(uint256 _proposalId) public onlyGovernor proposalExists(_proposalId) proposalNotExecuted(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.TREASURY_SPENDING, "Invalid proposal type for treasury execution.");
        require(block.timestamp > proposals[_proposalId].votingEndTime, "Voting is still active.");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        require(totalVotes * 100 / memberCount >= quorumPercentage, "Quorum not reached."); // Quorum check
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not approved by majority."); // Simple majority vote

        (address recipient, uint256 amount) = abi.decode(proposals[_proposalId].proposalData, (address, uint256));
        payable(recipient).transfer(amount);
        proposals[_proposalId].isExecuted = true;
        emit TreasurySpendingExecuted(_proposalId, recipient, amount);
        _executeProposal(_proposalId); // Mark proposal as executed
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // **** 6. DECENTRALIZED CURATION & GALLERY (On-Chain Curation) ****
    function proposeArtworkForGallery(uint256 _artworkId, string memory _galleryDescription) public onlyMember artworkExists(_artworkId) {
        require(!galleryArtworks[_artworkId], "Artwork is already in the gallery.");

        uint256 proposalId = _createProposal(
            ProposalType.GALLERY_ADDITION,
            msg.sender,
            _galleryDescription
        );
        proposals[proposalId].proposalData = abi.encode(_artworkId); // Store artworkId
        emit ArtworkProposedForGallery(proposalId, _artworkId, _galleryDescription);
    }

    function voteOnGalleryProposal(uint256 _proposalId, bool _approve) public onlyMember proposalExists(_proposalId) votingActive(_proposalId) votingNotEnded(_proposalId) proposalNotExecuted(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.GALLERY_ADDITION, "Invalid proposal type for gallery voting.");
        require(!hasVoted(msg.sender, _proposalId), "Member has already voted on this proposal.");
        recordVote(msg.sender, _proposalId); // Mark as voted

        if (_approve) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    function addArtworkToGallery(uint256 _proposalId) public onlyGovernor proposalExists(_proposalId) proposalNotExecuted(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.GALLERY_ADDITION, "Invalid proposal type for gallery addition.");
        require(block.timestamp > proposals[_proposalId].votingEndTime, "Voting is still active.");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        require(totalVotes * 100 / memberCount >= quorumPercentage, "Quorum not reached."); // Quorum check
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not approved by majority."); // Simple majority vote

        uint256 artworkId = abi.decode(proposals[_proposalId].proposalData, (uint256));
        galleryArtworks[artworkId] = true;
        emit ArtworkAddedToGallery(artworkId);
        _executeProposal(_proposalId); // Mark proposal as executed
    }

    function removeFromGallery(uint256 _artworkId) public onlyGovernor artworkExists(_artworkId) {
        require(galleryArtworks[_artworkId], "Artwork is not in the gallery.");
        galleryArtworks[_artworkId] = false;
        emit ArtworkRemovedFromGallery(_artworkId);
    }

    function getGalleryArtworks() public view returns (uint256[] memory) {
        uint256[] memory galleryArtworkIds = new uint256[](artworkCount); // Max possible size, could be optimized
        uint256 galleryIndex = 0;
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (galleryArtworks[i]) {
                galleryArtworkIds[galleryIndex] = i;
                galleryIndex++;
            }
        }
        // Resize array to actual number of gallery artworks
        assembly {
            mstore(galleryArtworkIds, galleryIndex) // Update array length in memory
        }
        return galleryArtworkIds;
    }


    // **** 7. ADVANCED FEATURES (Conceptual & Extensible) ****
    function setExternalDataFeed(address _dataFeedContract) public onlyGovernor {
        // Concept: Integrate with an external data feed contract for dynamic art properties.
        // Example: dataFeedContract = _dataFeedContract;
        // ... logic to use _dataFeedContract to update artwork properties ...
    }

    function registerArtStyle(string memory _styleName, string memory _styleDescription) public onlyGovernor {
        // Concept: Allow governor to register art styles that can be associated with stages/artworks.
        // Example: ArtStyle struct, mapping(uint256 => ArtStyle), styleCount, etc.
    }

    function getArtStyleDetails(uint256 _styleId) public view returns (string memory /* styleName, styleDescription */ ) {
        // Concept: Retrieve details of a registered art style.
        return ""; // Placeholder
    }

    function createCustomVotingRule(string memory _ruleName, bytes memory _ruleLogic) public onlyGovernor {
        // Concept: Allow governor to define custom voting rules for specific proposal types.
        // Example: Mapping(ProposalType => bytes _ruleLogic), logic to execute _ruleLogic during voting.
    }


    // **** INTERNAL HELPER FUNCTIONS (Governance & Proposals) ****
    mapping(uint256 => mapping(address => bool)) private memberVotes; // proposalId => member => hasVoted

    function _createProposal(ProposalType _proposalType, address _proposer, string memory _description) private returns (uint256) {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposalId: proposalCount,
            proposalType: _proposalType,
            proposer: _proposer,
            description: _description,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false,
            proposalData: bytes("") // Default empty data
        });
        emit ProposalCreated(proposalCount, _proposalType, _proposer, _description);
        return proposalCount;
    }

    function recordVote(address _voter, uint256 _proposalId) private {
        memberVotes[_proposalId][_voter] = true;
    }

    function hasVoted(address _voter, uint256 _proposalId) private view returns (bool) {
        return memberVotes[_proposalId][_voter];
    }

    function _executeProposal(uint256 _proposalId) private {
        proposals[_proposalId].isExecuted = true;
        emit ProposalExecuted(_proposalId, proposals[_proposalId].proposalType);
    }

    // Fallback function to receive ETH deposits
    receive() external payable {}
}
```