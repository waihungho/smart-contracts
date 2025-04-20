```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to submit, curate, exhibit, and monetize digital art collaboratively.

 * **Outline & Function Summary:**

 * **State Variables:**
 *   - `artworkRegistry`: Mapping to store artwork details (metadata, artist, approval status, etc.) indexed by artwork ID.
 *   - `proposals`: Mapping to store proposals for governance actions (artwork curation, setting changes, treasury spending, etc.) indexed by proposal ID.
 *   - `members`: Mapping to track collective members and their roles (artist, curator, general member).
 *   - `treasuryBalance`: Contract's treasury balance.
 *   - `votingPower`: Mapping to store voting power of each member (can be based on contribution, token holding, etc.).
 *   - `curators`: Array of addresses designated as curators.
 *   - `settings`: Struct to hold configurable contract settings (voting durations, fees, etc.).
 *   - `exhibitions`: Mapping to manage virtual exhibitions and associated artwork.
 *   - `royaltiesSplit`: Mapping to configure royalty split percentages for different actions.
 *   - `platformFee`: Percentage of sales taken as platform fee.
 *   - `nextArtworkId`: Counter for unique artwork IDs.
 *   - `nextProposalId`: Counter for unique proposal IDs.
 *   - `nextExhibitionId`: Counter for unique exhibition IDs.
 *   - `paused`: Boolean to pause/unpause contract functionalities.
 *   - `owner`: Address of the contract owner.

 * **Events:**
 *   - `ArtworkSubmitted`: Emitted when an artist submits artwork.
 *   - `ArtworkApproved`: Emitted when artwork is approved by curators.
 *   - `ArtworkRejected`: Emitted when artwork is rejected by curators.
 *   - `ProposalCreated`: Emitted when a new governance proposal is created.
 *   - `VoteCast`: Emitted when a member casts a vote on a proposal.
 *   - `ProposalExecuted`: Emitted when a proposal is successfully executed.
 *   - `MembershipRequested`: Emitted when an address requests membership.
 *   - `MembershipGranted`: Emitted when membership is granted.
 *   - `MembershipRevoked`: Emitted when membership is revoked.
 *   - `TreasuryDeposit`: Emitted when funds are deposited into the treasury.
 *   - `TreasuryWithdrawal`: Emitted when funds are withdrawn from the treasury.
 *   - `ExhibitionCreated`: Emitted when a new exhibition is created.
 *   - `ExhibitionArtworkAdded`: Emitted when artwork is added to an exhibition.
 *   - `ContractPaused`: Emitted when the contract is paused.
 *   - `ContractUnpaused`: Emitted when the contract is unpaused.
 *   - `CuratorAdded`: Emitted when a curator is added.
 *   - `CuratorRemoved`: Emitted when a curator is removed.
 *   - `RoyaltyWithdrawn`: Emitted when an artist withdraws their royalties.

 * **Functions:**

 * **Artwork Management:**
 *   1. `submitArtwork(string memory _metadataURI)`: Artists submit their artwork with metadata URI for curation.
 *   2. `voteOnArtwork(uint256 _artworkId, bool _approve)`: Curators vote to approve or reject submitted artwork.
 *   3. `getArtworkDetails(uint256 _artworkId)`: Retrieve detailed information about a specific artwork.
 *   4. `listApprovedArtwork()`: Get a list of IDs of artworks approved by the collective.
 *   5. `setArtworkMetadataURI(uint256 _artworkId, string memory _newMetadataURI)`: Artist can update metadata URI for their artwork (if allowed by settings).
 *   6. `burnArtwork(uint256 _artworkId)`: Remove artwork from the registry (governance/curator action, potentially with voting).

 * **Membership & Governance:**
 *   7. `requestMembership()`: Address requests to become a member of the collective.
 *   8. `voteOnMembership(address _applicant, bool _approve)`: Existing members vote on membership applications.
 *   9. `grantMembership(address _member)`: Grant membership to an address (governance action after successful vote).
 *   10. `revokeMembership(address _member)`: Revoke membership from an address (governance action, potentially with voting).
 *   11. `proposeSettingChange(string memory _settingName, uint256 _newValue)`: Members propose changes to contract settings.
 *   12. `voteOnProposal(uint256 _proposalId, bool _support)`: Members vote on governance proposals.
 *   13. `executeProposal(uint256 _proposalId)`: Execute a proposal after it reaches quorum and majority.
 *   14. `delegateVotingPower(address _delegateTo)`: Members can delegate their voting power to another member.
 *   15. `getMyVotingPower()`: Get the voting power of the caller.
 *   16. `getMemberCount()`: Get the total number of members in the collective.

 * **Treasury & Finance:**
 *   17. `depositToTreasury()`: Allow anyone to deposit ETH into the contract treasury (payable).
 *   18. `submitTreasuryProposal(address _recipient, uint256 _amount, string memory _reason)`: Members propose spending funds from the treasury.
 *   19. `withdrawArtworkRoyalties(uint256 _artworkId)`: Artists withdraw their earned royalties from sales or exhibitions.
 *   20. `getTreasuryBalance()`: View the current balance of the contract treasury.

 * **Exhibitions & Showcase:**
 *   21. `createExhibition(string memory _exhibitionName, string memory _description)`: Create a new virtual art exhibition.
 *   22. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Add approved artwork to a specific exhibition.
 *   23. `listExhibitionArtwork(uint256 _exhibitionId)`: Get a list of artwork IDs in a given exhibition.

 * **Admin & Utility:**
 *   24. `setCurator(address _curator, bool _isCurator)`: Owner function to add or remove curators.
 *   25. `pauseContract()`: Owner function to pause most contract functionalities in case of emergency.
 *   26. `unpauseContract()`: Owner function to unpause the contract.
 *   27. `setPlatformFee(uint256 _newFeePercentage)`: Owner function to adjust the platform fee percentage.
 *   28. `setRoyaltiesSplit(string memory _actionType, uint256 _newSplitPercentage)`: Owner function to adjust royalty split percentages.
 */
pragma solidity ^0.8.0;

contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---
    struct Artwork {
        uint256 id;
        address artist;
        string metadataURI;
        bool approved;
        uint256 submissionTimestamp;
        uint256 royaltyBalance; // Accumulated royalties for the artwork
    }
    mapping(uint256 => Artwork) public artworkRegistry;
    uint256 public nextArtworkId = 1;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 creationTimestamp;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        ProposalType proposalType;
        bytes proposalData; // Encoded data specific to the proposal type
    }
    enum ProposalType {
        SETTING_CHANGE,
        TREASURY_SPEND,
        MEMBERSHIP_ACTION,
        ARTWORK_ACTION,
        EXHIBITION_ACTION,
        GENERAL_GOVERNANCE
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;
    uint256 public proposalVoteDuration = 7 days; // Default proposal vote duration

    mapping(address => bool) public members;
    uint256 public memberCount = 0;

    mapping(address => uint256) public votingPower; // Voting power per member (initially 1, can be adjusted)

    address[] public curators;

    struct Settings {
        uint256 artworkApprovalThreshold; // Number of curator votes needed for approval
        uint256 membershipApprovalThreshold; // Number of member votes for membership approval
        uint256 proposalQuorumPercentage; // Percentage of total voting power needed for quorum
        uint256 platformFeePercentage;
        uint256 artistRoyaltyPercentage;
        bool allowMetadataUpdate; // Whether artists can update metadata
    }
    Settings public settings;

    struct Exhibition {
        uint256 id;
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256[] artworkIds;
    }
    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public nextExhibitionId = 1;

    uint256 public treasuryBalance;

    bool public paused = false;
    address public owner;

    // --- Events ---
    event ArtworkSubmitted(uint256 artworkId, address artist, string metadataURI);
    event ArtworkApproved(uint256 artworkId, address approvedBy);
    event ArtworkRejected(uint256 artworkId, address rejectedBy);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string description);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType, bool success);
    event MembershipRequested(address applicant);
    event MembershipGranted(address member);
    event MembershipRevoked(address member);
    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event ExhibitionCreated(uint256 exhibitionId, string name, string description);
    event ExhibitionArtworkAdded(uint256 exhibitionId, uint256 artworkId);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event CuratorAdded(address curator);
    event CuratorRemoved(address curator);
    event RoyaltyWithdrawn(uint256 artworkId, address artist, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier onlyCurator() {
        bool isCurator = false;
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == msg.sender) {
                isCurator = true;
                break;
            }
        }
        require(isCurator, "Only curators can call this function.");
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
    constructor() {
        owner = msg.sender;
        curators.push(msg.sender); // Owner is the initial curator
        settings = Settings({
            artworkApprovalThreshold: 2, // Example: 2 curator votes to approve artwork
            membershipApprovalThreshold: 5, // Example: 5 member votes to approve membership
            proposalQuorumPercentage: 30, // Example: 30% of voting power for quorum
            platformFeePercentage: 5,     // 5% platform fee on sales
            artistRoyaltyPercentage: 90,   // 90% royalty for artists on primary sales
            allowMetadataUpdate: false     // Initially disallow metadata updates
        });
        members[msg.sender] = true; // Owner is also the first member
        votingPower[msg.sender] = 10; // Owner gets higher initial voting power (example)
        memberCount = 1;
    }

    // --- Artwork Management Functions ---
    function submitArtwork(string memory _metadataURI) external onlyMember whenNotPaused {
        uint256 artworkId = nextArtworkId++;
        artworkRegistry[artworkId] = Artwork({
            id: artworkId,
            artist: msg.sender,
            metadataURI: _metadataURI,
            approved: false,
            submissionTimestamp: block.timestamp,
            royaltyBalance: 0
        });
        emit ArtworkSubmitted(artworkId, msg.sender, _metadataURI);
    }

    function voteOnArtwork(uint256 _artworkId, bool _approve) external onlyCurator whenNotPaused {
        require(artworkRegistry[_artworkId].artist != address(0), "Artwork does not exist.");
        require(!artworkRegistry[_artworkId].approved, "Artwork already processed."); // Prevent revoting
        require(artworkRegistry[_artworkId].artist != msg.sender, "Curator cannot vote on their own artwork.");

        if (_approve) {
            // In a more robust system, track curator votes per artwork for threshold
            artworkRegistry[_artworkId].approved = true; // Simple approval for now
            emit ArtworkApproved(_artworkId, msg.sender);
        } else {
            emit ArtworkRejected(_artworkId, msg.sender); // Could track rejections too
            // In a real system, might have rejection logic or multiple rejection votes needed
        }
    }

    function getArtworkDetails(uint256 _artworkId) external view returns (Artwork memory) {
        require(artworkRegistry[_artworkId].artist != address(0), "Artwork does not exist.");
        return artworkRegistry[_artworkId];
    }

    function listApprovedArtwork() external view returns (uint256[] memory) {
        uint256[] memory approvedArtworkIds = new uint256[](nextArtworkId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextArtworkId; i++) {
            if (artworkRegistry[i].approved) {
                approvedArtworkIds[count++] = i;
            }
        }
        // Resize array to actual number of approved artworks
        assembly {
            mstore(approvedArtworkIds, count) // Update the length of the array
        }
        return approvedArtworkIds;
    }

    function setArtworkMetadataURI(uint256 _artworkId, string memory _newMetadataURI) external onlyMember whenNotPaused {
        require(settings.allowMetadataUpdate, "Metadata update is not allowed.");
        require(artworkRegistry[_artworkId].artist == msg.sender, "Only artist can update metadata.");
        artworkRegistry[_artworkId].metadataURI = _newMetadataURI;
    }

    function burnArtwork(uint256 _artworkId) external onlyCurator whenNotPaused {
        require(artworkRegistry[_artworkId].artist != address(0), "Artwork does not exist.");
        delete artworkRegistry[_artworkId];
        // Consider adding governance for artwork burning in a real-world scenario
    }


    // --- Membership & Governance Functions ---
    function requestMembership() external whenNotPaused {
        require(!members[msg.sender], "Already a member.");
        // In a real system, you'd likely have a membership application process, possibly with a deposit
        emit MembershipRequested(msg.sender);
        // Create a proposal for membership approval
        _createMembershipProposal("Membership application for " , msg.sender);
    }

    function voteOnMembership(address _applicant, bool _approve) external onlyMember whenNotPaused {
        // In a real system, you'd likely have a proposal ID associated with each membership request
        // This is simplified for example.
        // Assume there's an active proposal for _applicant membership
        uint256 proposalId = _findMembershipProposalForApplicant(_applicant); // Implement this logic
        require(proposalId != 0, "No active membership proposal found for this applicant.");
        require(!proposals[proposalId].executed, "Proposal already executed.");

        if (_approve) {
            proposals[proposalId].yesVotes += votingPower[msg.sender];
            emit VoteCast(proposalId, msg.sender, true);
        } else {
            proposals[proposalId].noVotes += votingPower[msg.sender];
            emit VoteCast(proposalId, msg.sender, false);
        }
        _checkAndExecuteProposal(proposalId);
    }

    function grantMembership(address _member) private { // Internal function called after proposal execution
        require(!members[_member], "Address is already a member.");
        members[_member] = true;
        memberCount++;
        votingPower[_member] = 1; // Default voting power for new members
        emit MembershipGranted(_member);
    }

    function revokeMembership(address _member) external onlyMember whenNotPaused {
        require(members[_member], "Address is not a member.");
        require(msg.sender != _member, "Cannot revoke your own membership.");
        // Create a proposal for membership revocation
        _createMembershipRevocationProposal("Revoke membership of ", _member);
    }

    function proposeSettingChange(string memory _settingName, uint256 _newValue) external onlyMember whenNotPaused {
        _createSettingChangeProposal(_settingName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPaused {
        require(proposals[_proposalId].proposer != address(0), "Proposal does not exist.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp < proposals[_proposalId].voteEndTime, "Voting period ended.");

        if (_support) {
            proposals[_proposalId].yesVotes += votingPower[msg.sender];
            emit VoteCast(_proposalId, msg.sender, true);
        } else {
            proposals[_proposalId].noVotes += votingPower[msg.sender];
            emit VoteCast(_proposalId, msg.sender, false);
        }
        _checkAndExecuteProposal(_proposalId);
    }

    function executeProposal(uint256 _proposalId) external onlyMember whenNotPaused {
        require(proposals[_proposalId].proposer != address(0), "Proposal does not exist.");
        _checkAndExecuteProposal(_proposalId); // Allow manual execution if needed (e.g., for off-chain execution failures)
    }

    function delegateVotingPower(address _delegateTo) external onlyMember whenNotPaused {
        require(members[_delegateTo], "Delegate address must be a member.");
        votingPower[_delegateTo] += votingPower[msg.sender];
        votingPower[msg.sender] = 0; // Delegate gives up their voting power
        // Consider adding events for delegation and undelegation
    }

    function getMyVotingPower() external view onlyMember returns (uint256) {
        return votingPower[msg.sender];
    }

    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }


    // --- Treasury & Finance Functions ---
    function depositToTreasury() external payable whenNotPaused {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function submitTreasuryProposal(address _recipient, uint256 _amount, string memory _reason) external onlyMember whenNotPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(_amount <= treasuryBalance, "Insufficient treasury balance.");
        _createTreasurySpendProposal(_recipient, _amount, _reason);
    }

    function withdrawArtworkRoyalties(uint256 _artworkId) external onlyMember whenNotPaused {
        require(artworkRegistry[_artworkId].artist == msg.sender, "Only artist can withdraw royalties.");
        uint256 amount = artworkRegistry[_artworkId].royaltyBalance;
        require(amount > 0, "No royalties to withdraw.");
        artworkRegistry[_artworkId].royaltyBalance = 0; // Reset balance after withdrawal
        payable(msg.sender).transfer(amount);
        emit RoyaltyWithdrawn(_artworkId, msg.sender, amount);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }


    // --- Exhibitions & Showcase Functions ---
    function createExhibition(string memory _exhibitionName, string memory _description) external onlyMember whenNotPaused {
        uint256 exhibitionId = nextExhibitionId++;
        exhibitions[exhibitionId] = Exhibition({
            id: exhibitionId,
            name: _exhibitionName,
            description: _description,
            startTime: 0, // Set startTime later via proposal if needed
            endTime: 0,   // Set endTime later via proposal if needed
            artworkIds: new uint256[](0)
        });
        emit ExhibitionCreated(exhibitionId, _exhibitionName, _description);
    }

    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) external onlyCurator whenNotPaused {
        require(exhibitions[_exhibitionId].id != 0, "Exhibition does not exist.");
        require(artworkRegistry[_artworkId].approved, "Artwork must be approved to add to exhibition.");
        exhibitions[_exhibitionId].artworkIds.push(_artworkId);
        emit ExhibitionArtworkAdded(_exhibitionId, _artworkId);
    }

    function listExhibitionArtwork(uint256 _exhibitionId) external view returns (uint256[] memory) {
        require(exhibitions[_exhibitionId].id != 0, "Exhibition does not exist.");
        return exhibitions[_exhibitionId].artworkIds;
    }


    // --- Admin & Utility Functions ---
    function setCurator(address _curator, bool _isCurator) external onlyOwner whenNotPaused {
        bool found = false;
        uint256 curatorIndex;
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _curator) {
                found = true;
                curatorIndex = i;
                break;
            }
        }

        if (_isCurator && !found) {
            curators.push(_curator);
            emit CuratorAdded(_curator);
        } else if (!_isCurator && found) {
            // Remove curator, maintain array order (can be optimized if order doesn't matter)
            for (uint256 i = curatorIndex; i < curators.length - 1; i++) {
                curators[i] = curators[i + 1];
            }
            curators.pop();
            emit CuratorRemoved(_curator);
        }
        // No action if already in desired state
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner whenNotPaused {
        require(_newFeePercentage <= 100, "Platform fee percentage cannot exceed 100.");
        settings.platformFeePercentage = _newFeePercentage;
    }

    function setRoyaltiesSplit(string memory _actionType, uint256 _newSplitPercentage) external onlyOwner whenNotPaused {
        require(_newSplitPercentage <= 100, "Royalty split percentage cannot exceed 100.");
        if (keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("artistRoyalty"))) {
            settings.artistRoyaltyPercentage = _newSplitPercentage;
        } else {
            revert("Invalid action type for royalty split.");
        }
        // Extend for other royalty types if needed in the future
    }

    // --- Internal Helper Functions for Proposals ---
    function _createProposal(
        ProposalType _proposalType,
        string memory _description,
        bytes memory _proposalData
    ) internal onlyMember returns (uint256) {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            creationTimestamp: block.timestamp,
            voteEndTime: block.timestamp + proposalVoteDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposalType: _proposalType,
            proposalData: _proposalData
        });
        emit ProposalCreated(proposalId, _proposalType, msg.sender, _description);
        return proposalId;
    }

    function _checkAndExecuteProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.timestamp >= proposal.voteEndTime, "Voting period not ended.");

        uint256 totalVotingPower = 0;
        for(uint i=0; i < curators.length; ++i) { // Assuming curators also have voting power
            totalVotingPower += votingPower[curators[i]];
        }
        for (uint256 i = 1; i < nextArtworkId; i++) { // Sum voting power of all members. In efficient system, track total voting power directly.
            if (members[artworkRegistry[i].artist]) {
                totalVotingPower += votingPower[artworkRegistry[i].artist];
            }
        }


        uint256 quorum = (totalVotingPower * settings.proposalQuorumPercentage) / 100;
        if (proposal.yesVotes >= proposal.noVotes && proposal.yesVotes >= quorum) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, proposal.proposalType, true);
            _executeProposalAction(_proposalId);
        } else {
            proposal.executed = true; // Mark as executed even if failed to prevent re-execution
            emit ProposalExecuted(_proposalId, proposal.proposalType, false);
        }
    }

    function _executeProposalAction(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalType == ProposalType.SETTING_CHANGE) {
            (string memory settingName, uint256 newValue) = abi.decode(proposal.proposalData, (string, uint256));
            if (keccak256(abi.encodePacked(settingName)) == keccak256(abi.encodePacked("artworkApprovalThreshold"))) {
                settings.artworkApprovalThreshold = uint16(newValue); // Example, adjust type if needed
            } else if (keccak256(abi.encodePacked(settingName)) == keccak256(abi.encodePacked("membershipApprovalThreshold"))) {
                settings.membershipApprovalThreshold = uint16(newValue);
            } else if (keccak256(abi.encodePacked(settingName)) == keccak256(abi.encodePacked("proposalQuorumPercentage"))) {
                settings.proposalQuorumPercentage = uint16(newValue);
            } // ... add more settings to handle
        } else if (proposal.proposalType == ProposalType.TREASURY_SPEND) {
            (address recipient, uint256 amount) = abi.decode(proposal.proposalData, (address, uint256));
            treasuryBalance -= amount;
            payable(recipient).transfer(amount);
            emit TreasuryWithdrawal(recipient, amount);
        } else if (proposal.proposalType == ProposalType.MEMBERSHIP_ACTION) {
            (string memory action, address memberAddress) = abi.decode(proposal.proposalData, (string, address));
            if (keccak256(abi.encodePacked(action)) == keccak256(abi.encodePacked("grant"))) {
                grantMembership(memberAddress);
            } else if (keccak256(abi.encodePacked(action)) == keccak256(abi.encodePacked("revoke"))) {
                members[memberAddress] = false;
                memberCount--;
                emit MembershipRevoked(memberAddress);
            }
        } // ... handle other proposal types
    }

    function _createSettingChangeProposal(string memory _settingName, uint256 _newValue) internal {
        bytes memory proposalData = abi.encode(_settingName, _newValue);
        _createProposal(ProposalType.SETTING_CHANGE, string.concat("Change setting '", _settingName, "' to ", Strings.toString(_newValue)), proposalData);
    }

    function _createTreasurySpendProposal(address _recipient, uint256 _amount, string memory _reason) internal {
        bytes memory proposalData = abi.encode(_recipient, _amount);
        _createProposal(ProposalType.TREASURY_SPEND, string.concat("Spend ", Strings.toString(_amount), " ETH from treasury to ", Strings.toHexString(_recipient), " for ", _reason), proposalData);
    }

    function _createMembershipProposal(string memory _descriptionPrefix, address _applicant) internal {
        bytes memory proposalData = abi.encode("grant", _applicant);
        _createProposal(ProposalType.MEMBERSHIP_ACTION, string.concat(_descriptionPrefix, Strings.toHexString(_applicant)), proposalData);
    }

    function _createMembershipRevocationProposal(string memory _descriptionPrefix, address _member) internal {
        bytes memory proposalData = abi.encode("revoke", _member);
        _createProposal(ProposalType.MEMBERSHIP_ACTION, string.concat(_descriptionPrefix, Strings.toHexString(_member)), proposalData);
    }

    function _findMembershipProposalForApplicant(address _applicant) internal view returns (uint256) {
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (proposals[i].proposalType == ProposalType.MEMBERSHIP_ACTION) {
                (string memory action, address memberAddress) = abi.decode(proposals[i].proposalData, (string, address));
                if (keccak256(abi.encodePacked(action)) == keccak256(abi.encodePacked("grant")) && memberAddress == _applicant && !proposals[i].executed) {
                    return proposals[i].id;
                }
            }
        }
        return 0; // Not found
    }
}

// --- Helper Library for String Conversion (from OpenZeppelin Contracts) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.5.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        bytes memory buffer = new bytes(64);
        uint256 cursor = 64;
        while (value != 0) {
            cursor--;
            buffer[cursor] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        while (cursor != 64 && buffer[cursor] == bytes1(uint8(48))) {
            cursor++;
        }
        return string(abi.encodePacked("0x", string(buffer[cursor..])));
    }

    /**
     * @dev Converts an `address` with checksum to its ASCII `string` hexadecimal representation.
     *
     * CAUTION: This function is deprecated because it conflicts with the checksum format defined in
     * [ERC-55](https://eips.ethereum.org/EIPS/eip-55). Use {toHexString} instead.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)));
    }
}
```