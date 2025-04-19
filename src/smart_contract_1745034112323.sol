```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Adapt and Enhance for Production)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to collaborate,
 * curate, and monetize digital art through NFTs and community governance.
 *
 * **Contract Outline and Function Summary:**
 *
 * **I. Core Functionality (Art Submission & Curation):**
 *   1. `submitArtProposal(string _metadataURI)`: Allows members to submit art proposals with IPFS metadata URI.
 *   2. `voteOnArtProposal(uint256 _proposalId, bool _approve)`: Members vote on submitted art proposals.
 *   3. `finalizeArtProposal(uint256 _proposalId)`:  Finalizes a proposal after voting, minting NFT if approved.
 *   4. `getCurationCriteria()`: Returns the current curation criteria defined by the DAO.
 *   5. `setCurationCriteria(string _newCriteria)`:  DAO-governed function to update curation criteria.
 *   6. `reportArtViolation(uint256 _artId, string _reportReason)`: Allows members to report art pieces for violations.
 *   7. `resolveArtViolation(uint256 _artId, bool _isViolation)`: DAO-governed function to resolve art violation reports, potentially burning NFTs.
 *
 * **II. Membership & Governance:**
 *   8. `requestMembership()`: Allows users to request membership to the collective.
 *   9. `approveMembership(address _user)`: DAO-governed function to approve membership requests.
 *  10. `revokeMembership(address _member)`: DAO-governed function to revoke membership from a member.
 *  11. `isMember(address _user)`: Checks if an address is a member of the collective.
 *  12. `createGovernanceProposal(string _proposalDescription, bytes _calldata)`: Members propose governance actions with calldata for contract execution.
 *  13. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Members vote on governance proposals.
 *  14. `executeGovernanceProposal(uint256 _proposalId)`: Executes a governance proposal if it passes the voting threshold.
 *  15. `getGovernanceThreshold()`: Returns the current voting threshold for governance proposals.
 *  16. `setGovernanceThreshold(uint256 _newThreshold)`: DAO-governed function to update the governance voting threshold.
 *
 * **III. NFT & Revenue Management:**
 *  17. `mintArtNFT(string _metadataURI)`: Internal function to mint an NFT for approved art.
 *  18. `setArtPrice(uint256 _artId, uint256 _price)`: Allows the collective to set the price for an art NFT.
 *  19. `purchaseArtNFT(uint256 _artId)`: Allows users to purchase art NFTs, funds go to collective treasury.
 *  20. `withdrawTreasuryFunds(uint256 _amount, address _recipient)`: DAO-governed function to withdraw funds from the collective treasury.
 *  21. `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 *  22. `distributeRoyalties(uint256 _artId)`: (Hypothetical) Function to distribute royalties to original artist (concept - requires more complex tracking).
 *  23. `burnArtNFT(uint256 _artId)`: DAO-governed function to burn an art NFT (e.g., due to violation).
 *
 * **IV. Advanced & Creative Features:**
 *  24. `sponsorArtProposal(uint256 _proposalId)`: Allows members to sponsor art proposals with ETH to increase visibility or incentivize curation.
 *  25. `participateInArtChallenge(string _challengeName, string _artMetadataURI)`: Allows members to submit art for themed challenges.
 *  26. `voteOnChallengeSubmission(string _challengeName, uint256 _submissionId, bool _approve)`: Members vote on challenge submissions.
 *  27. `rewardChallengeWinners(string _challengeName)`: DAO-governed function to reward winners of art challenges (e.g., with NFTs, tokens).
 *  28. `createArtExhibition(string _exhibitionName, uint256[] _artIds)`: DAO-governed function to create virtual art exhibitions featuring curated art pieces.
 *  29. `donateToCollective()`: Allows anyone to donate ETH to the collective treasury to support its operations.
 */

contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    // Membership & Governance
    mapping(address => bool) public members;
    address[] public membershipRequests;
    address public daoGovernor; // Address with ultimate governance control (e.g., multisig, DAO contract)
    uint256 public governanceThresholdPercentage = 51; // Percentage of votes required for governance proposals to pass

    struct GovernanceProposal {
        string description;
        bytes calldataData;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public governanceProposalCount = 0;

    // Art Curation & NFTs
    string public curationCriteria = "Original and high-quality digital art that aligns with the collective's vision.";
    struct ArtProposal {
        string metadataURI;
        address proposer;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool approved;
    }
    mapping(uint256 => ArtProposal) public artProposals;
    uint256 public artProposalCount = 0;

    struct ArtPiece {
        uint256 id;
        string metadataURI;
        address creator; // Initially the proposer, might be refined for creator tracking
        uint256 price;
        bool isViolationReported;
        string violationReportReason;
        bool isBurned;
    }
    mapping(uint256 => ArtPiece) public artPieces;
    uint256 public artPieceCount = 0;
    mapping(uint256 => uint256) public artIdToNFTId; // Mapping ArtPiece ID to NFT ID (if using external NFT contract) - simplified in this example.

    // Treasury
    uint256 public treasuryBalance = 0;

    // Art Challenges (Example Feature)
    struct ArtChallenge {
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        address[] winners;
        mapping(uint256 => ArtProposal) submissions; // Reusing ArtProposal struct for challenge submissions
        uint256 submissionCount;
    }
    mapping(string => ArtChallenge) public artChallenges;
    string[] public activeChallengeNames;

    // Events
    event MembershipRequested(address indexed user);
    event MembershipApproved(address indexed member, address indexed approvedBy);
    event MembershipRevoked(address indexed member, address indexed revokedBy);
    event ArtProposalSubmitted(uint256 proposalId, address indexed proposer, string metadataURI);
    event ArtProposalVoted(uint256 proposalId, address indexed voter, bool approved);
    event ArtProposalFinalized(uint256 proposalId, bool approved, uint256 artId);
    event ArtNFTMinted(uint256 artId, uint256 nftId, string metadataURI);
    event ArtPriceSet(uint256 artId, uint256 price, address indexed setter);
    event ArtPurchased(uint256 artId, address indexed buyer, uint256 price);
    event TreasuryWithdrawal(uint256 amount, address indexed recipient, address indexed withdrawnBy);
    event GovernanceProposalCreated(uint256 proposalId, string description, address indexed proposer);
    event GovernanceProposalVoted(uint256 proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId, bool passed);
    event CurationCriteriaUpdated(string newCriteria, address indexed updatedBy);
    event ArtViolationReported(uint256 artId, address indexed reporter, string reason);
    event ArtViolationResolved(uint256 artId, bool isViolation, address indexed resolver);
    event ArtNFTBurned(uint256 artId, address indexed burner);
    event ArtProposalSponsored(uint256 proposalId, address indexed sponsor, uint256 amount);
    event ArtChallengeCreated(string challengeName, string description, address indexed creator);
    event ArtChallengeSubmission(string challengeName, uint256 submissionId, address indexed submitter, string metadataURI);
    event ChallengeSubmissionVoted(string challengeName, uint256 submissionId, address indexed voter, bool approved);
    event ChallengeWinnersRewarded(string challengeName, address[] winners, address indexed rewardedBy);
    event ArtExhibitionCreated(string exhibitionName, uint256[] artIds, address indexed creator);
    event DonationReceived(address indexed donor, uint256 amount);


    // --- Modifiers ---
    modifier onlyMembers() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == daoGovernor, "Only the DAO Governor can perform this action.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < artProposalCount && _proposalId >= 0, "Art proposal does not exist.");
        _;
    }

    modifier governanceProposalExists(uint256 _proposalId) {
        require(_proposalId < governanceProposalCount && _proposalId >= 0, "Governance proposal does not exist.");
        _;
    }

    modifier proposalNotFinalized(uint256 _proposalId) {
        require(!artProposals[_proposalId].finalized, "Art proposal already finalized.");
        _;
    }

    modifier governanceProposalNotExecuted(uint256 _proposalId) {
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed.");
        _;
    }

    modifier challengeExists(string memory _challengeName) {
        require(artChallenges[_challengeName].isActive, "Art Challenge does not exist or is not active.");
        _;
    }

    modifier submissionExists(string memory _challengeName, uint256 _submissionId) {
        require(_submissionId < artChallenges[_challengeName].submissionCount && _submissionId >= 0, "Challenge submission does not exist.");
        _;
    }


    // --- Constructor ---
    constructor(address _initialGovernor) {
        daoGovernor = _initialGovernor;
    }


    // --- I. Core Functionality (Art Submission & Curation) ---

    /// @notice Allows members to submit an art proposal.
    /// @param _metadataURI IPFS URI pointing to the art's metadata.
    function submitArtProposal(string memory _metadataURI) public onlyMembers {
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty.");

        artProposals[artProposalCount] = ArtProposal({
            metadataURI: _metadataURI,
            proposer: msg.sender,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + 7 days, // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false
        });

        emit ArtProposalSubmitted(artProposalCount, msg.sender, _metadataURI);
        artProposalCount++;
    }

    /// @notice Allows members to vote on an art proposal.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnArtProposal(uint256 _proposalId, bool _approve) public onlyMembers proposalExists(_proposalId) proposalNotFinalized(_proposalId) {
        require(block.timestamp < artProposals[_proposalId].votingEndTime, "Voting period has ended.");
        ArtProposal storage proposal = artProposals[_proposalId];

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Finalizes an art proposal after the voting period. Mints an NFT if approved.
    /// @param _proposalId ID of the art proposal to finalize.
    function finalizeArtProposal(uint256 _proposalId) public onlyMembers proposalExists(_proposalId) proposalNotFinalized(_proposalId) {
        require(block.timestamp >= artProposals[_proposalId].votingEndTime, "Voting period has not ended yet.");
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.finalized, "Proposal already finalized.");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        bool approved = (totalVotes > 0 && (proposal.yesVotes * 100) / totalVotes >= governanceThresholdPercentage); // Use governance threshold for art approval too. Consider separate threshold later.

        proposal.finalized = true;
        proposal.approved = approved;

        if (approved) {
            uint256 artId = mintArtNFT(proposal.metadataURI);
            artPieces[artId].creator = proposal.proposer; // Set creator
            emit ArtProposalFinalized(_proposalId, true, artId);
        } else {
            emit ArtProposalFinalized(_proposalId, false, 0); // 0 artId indicates rejection
        }
    }

    /// @notice Returns the current art curation criteria.
    function getCurationCriteria() public view returns (string memory) {
        return curationCriteria;
    }

    /// @notice DAO-governed function to set new art curation criteria.
    /// @param _newCriteria The new curation criteria string.
    function setCurationCriteria(string memory _newCriteria) public onlyGovernor {
        require(bytes(_newCriteria).length > 0, "Curation criteria cannot be empty.");
        curationCriteria = _newCriteria;
        emit CurationCriteriaUpdated(_newCriteria, msg.sender);
    }

    /// @notice Allows members to report an art piece for a violation (e.g., copyright, community guidelines).
    /// @param _artId ID of the art piece to report.
    /// @param _reportReason Reason for the violation report.
    function reportArtViolation(uint256 _artId, string memory _reportReason) public onlyMembers {
        require(_artId < artPieceCount, "Art ID does not exist.");
        require(bytes(_reportReason).length > 0, "Violation report reason cannot be empty.");
        require(!artPieces[_artId].isViolationReported, "Violation already reported for this art piece.");

        artPieces[_artId].isViolationReported = true;
        artPieces[_artId].violationReportReason = _reportReason;
        emit ArtViolationReported(_artId, msg.sender, _reportReason);
    }

    /// @notice DAO-governed function to resolve an art violation report. Can burn the NFT if violation confirmed.
    /// @param _artId ID of the art piece to resolve violation for.
    /// @param _isViolation True if violation is confirmed, false otherwise.
    function resolveArtViolation(uint256 _artId, bool _isViolation) public onlyGovernor {
        require(_artId < artPieceCount, "Art ID does not exist.");
        require(artPieces[_artId].isViolationReported, "No violation reported for this art piece.");

        artPieces[_artId].isViolationReported = false; // Reset violation status

        if (_isViolation) {
            burnArtNFT(_artId);
            emit ArtViolationResolved(_artId, true, msg.sender);
        } else {
            emit ArtViolationResolved(_artId, false, msg.sender);
        }
    }


    // --- II. Membership & Governance ---

    /// @notice Allows users to request membership to the collective.
    function requestMembership() public {
        require(!members[msg.sender], "You are already a member.");
        bool alreadyRequested = false;
        for(uint i=0; i < membershipRequests.length; i++){
            if(membershipRequests[i] == msg.sender){
                alreadyRequested = true;
                break;
            }
        }
        require(!alreadyRequested, "Membership already requested.");

        membershipRequests.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    /// @notice DAO-governed function to approve a membership request.
    /// @param _user Address of the user to approve.
    function approveMembership(address _user) public onlyGovernor {
        require(!members[_user], "User is already a member.");
        bool foundRequest = false;
        uint256 requestIndex;
        for(uint i=0; i < membershipRequests.length; i++){
            if(membershipRequests[i] == _user){
                foundRequest = true;
                requestIndex = i;
                break;
            }
        }
        require(foundRequest, "Membership request not found for this user.");

        members[_user] = true;
        // Remove from membership requests array (preserve order not important, so swap with last and pop)
        membershipRequests[requestIndex] = membershipRequests[membershipRequests.length - 1];
        membershipRequests.pop();

        emit MembershipApproved(_user, msg.sender);
    }

    /// @notice DAO-governed function to revoke membership from a member.
    /// @param _member Address of the member to revoke membership from.
    function revokeMembership(address _member) public onlyGovernor {
        require(members[_member], "User is not a member.");
        require(_member != daoGovernor, "Cannot revoke membership of the DAO Governor."); // Prevent accidental governance lock-out

        delete members[_member]; // Effectively sets to false
        emit MembershipRevoked(_member, msg.sender);
    }

    /// @notice Checks if an address is a member of the collective.
    /// @param _user Address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _user) public view returns (bool) {
        return members[_user];
    }

    /// @notice Allows members to create a governance proposal.
    /// @param _proposalDescription Description of the governance proposal.
    /// @param _calldata Calldata to execute if the proposal passes.
    function createGovernanceProposal(string memory _proposalDescription, bytes memory _calldata) public onlyMembers {
        require(bytes(_proposalDescription).length > 0, "Proposal description cannot be empty.");

        governanceProposals[governanceProposalCount] = GovernanceProposal({
            description: _proposalDescription,
            calldataData: _calldata,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + 7 days, // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false
        });

        emit GovernanceProposalCreated(governanceProposalCount, _proposalDescription, msg.sender);
        governanceProposalCount++;
    }

    /// @notice Allows members to vote on a governance proposal.
    /// @param _proposalId ID of the governance proposal to vote on.
    /// @param _support True to support, false to reject.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public onlyMembers governanceProposalExists(_proposalId) governanceProposalNotExecuted(_proposalId) {
        require(block.timestamp < governanceProposals[_proposalId].votingEndTime, "Voting period has ended.");
        GovernanceProposal storage proposal = governanceProposals[_proposalId];

        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance proposal if it has passed the voting threshold.
    /// @param _proposalId ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) public onlyGovernor governanceProposalExists(_proposalId) governanceProposalNotExecuted(_proposalId) {
        require(block.timestamp >= governanceProposals[_proposalId].votingEndTime, "Voting period has not ended yet.");
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        bool passed = (totalVotes > 0 && (proposal.yesVotes * 100) / totalVotes >= governanceThresholdPercentage);

        proposal.executed = true;
        proposal.passed = passed;

        if (passed) {
            (bool success, ) = address(this).call(proposal.calldataData); // Execute the calldata
            require(success, "Governance proposal execution failed.");
            emit GovernanceProposalExecuted(_proposalId, true);
        } else {
            emit GovernanceProposalExecuted(_proposalId, false);
        }
    }

    /// @notice Returns the current governance voting threshold percentage.
    function getGovernanceThreshold() public view returns (uint256) {
        return governanceThresholdPercentage;
    }

    /// @notice DAO-governed function to set a new governance voting threshold percentage.
    /// @param _newThreshold New governance voting threshold percentage (e.g., 51 for 51%).
    function setGovernanceThreshold(uint256 _newThreshold) public onlyGovernor {
        require(_newThreshold > 0 && _newThreshold <= 100, "Governance threshold must be between 1 and 100.");
        governanceThresholdPercentage = _newThreshold;
    }


    // --- III. NFT & Revenue Management ---

    /// @dev Internal function to mint a new art NFT. (Simplified - in real app, use ERC721 contract).
    /// @param _metadataURI IPFS URI for the NFT metadata.
    /// @return The ID of the minted art piece.
    function mintArtNFT(string memory _metadataURI) internal returns (uint256) {
        artPieces[artPieceCount] = ArtPiece({
            id: artPieceCount,
            metadataURI: _metadataURI,
            creator: address(0), // Creator set later in finalizeArtProposal
            price: 0,
            isViolationReported: false,
            violationReportReason: "",
            isBurned: false
        });
        emit ArtNFTMinted(artPieceCount, artPieceCount, _metadataURI); // In real NFT, would emit Transfer event from NFT contract
        artPieceCount++;
        return artPieceCount - 1; // Return the ID of the newly minted art piece
    }

    /// @notice Allows the DAO Governor to set the price for an art NFT.
    /// @param _artId ID of the art piece.
    /// @param _price Price in wei.
    function setArtPrice(uint256 _artId, uint256 _price) public onlyGovernor {
        require(_artId < artPieceCount, "Art ID does not exist.");
        require(_price >= 0, "Price cannot be negative.");
        artPieces[_artId].price = _price;
        emit ArtPriceSet(_artId, _price, msg.sender);
    }

    /// @notice Allows anyone to purchase an art NFT. Funds go to the collective treasury.
    /// @param _artId ID of the art piece to purchase.
    function purchaseArtNFT(uint256 _artId) payable public {
        require(_artId < artPieceCount, "Art ID does not exist.");
        require(artPieces[_artId].price > 0, "Art is not for sale or price not set.");
        require(msg.value >= artPieces[_artId].price, "Insufficient funds sent.");
        require(!artPieces[_artId].isBurned, "Art piece is burned and cannot be purchased.");

        treasuryBalance += msg.value;
        emit ArtPurchased(_artId, msg.sender, artPieces[_artId].price);
        // In a real NFT contract, you'd transfer ownership of the NFT here.
        // For this example, we just track purchase event and treasury.
    }

    /// @notice DAO-governed function to withdraw funds from the collective treasury.
    /// @param _amount Amount to withdraw in wei.
    /// @param _recipient Address to send the funds to.
    function withdrawTreasuryFunds(uint256 _amount, address _recipient) public onlyGovernor {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(treasuryBalance >= _amount, "Insufficient funds in treasury.");

        treasuryBalance -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Treasury withdrawal failed.");
        emit TreasuryWithdrawal(_amount, _recipient, msg.sender);
    }

    /// @notice Returns the current balance of the collective treasury.
    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    /// @notice (Hypothetical - Concept) Function to distribute royalties to the original artist.
    /// @param _artId ID of the art piece.
    function distributeRoyalties(uint256 _artId) public onlyGovernor {
        // ... (Complex implementation required to track original artist and royalty percentage per art piece) ...
        // ... (This would involve more state variables to store artist information and royalty rules) ...
        // ... (Example: Fetch artist address associated with _artId, calculate royalty amount from treasury, transfer ETH) ...
        // ... (For simplicity, this is left as a conceptual outline. Full royalty implementation is advanced.) ...
        require(false, "Royalty distribution not fully implemented in this example."); // Placeholder - remove in real implementation
    }

    /// @notice DAO-governed function to burn an art NFT (e.g., due to confirmed violation).
    /// @param _artId ID of the art piece to burn.
    function burnArtNFT(uint256 _artId) public onlyGovernor {
        require(_artId < artPieceCount, "Art ID does not exist.");
        require(!artPieces[_artId].isBurned, "Art piece already burned.");

        artPieces[_artId].isBurned = true; // Mark as burned in contract state
        emit ArtNFTBurned(_artId, msg.sender);
        // In a real NFT contract, you would call a burn function on the ERC721 contract.
        // Here, we just mark it as burned in our internal state.
    }


    // --- IV. Advanced & Creative Features ---

    /// @notice Allows members to sponsor an art proposal with ETH to increase visibility or incentivize curation.
    /// @param _proposalId ID of the art proposal to sponsor.
    function sponsorArtProposal(uint256 _proposalId) payable public onlyMembers proposalExists(_proposalId) proposalNotFinalized(_proposalId) {
        require(msg.value > 0, "Sponsorship amount must be greater than zero.");
        // You could store sponsorship amounts per proposal, or use it for some other logic (e.g., faster voting, prioritized curation queue).
        // For now, just transfer to treasury and emit event.
        treasuryBalance += msg.value;
        emit ArtProposalSponsored(_proposalId, msg.sender, msg.value);
    }

    /// @notice Allows members to submit art for a themed challenge.
    /// @param _challengeName Name of the art challenge.
    /// @param _artMetadataURI IPFS URI pointing to the art's metadata.
    function participateInArtChallenge(string memory _challengeName, string memory _artMetadataURI) public onlyMembers challengeExists(_challengeName) {
        require(bytes(_artMetadataURI).length > 0, "Metadata URI cannot be empty.");

        ArtChallenge storage challenge = artChallenges[_challengeName];
        challenge.submissions[challenge.submissionCount] = ArtProposal({ // Reuse ArtProposal struct for submissions
            metadataURI: _artMetadataURI,
            proposer: msg.sender,
            votingStartTime: block.timestamp, // Set voting start immediately upon submission? Or later?
            votingEndTime: challenge.endTime, // Challenge end time as voting end time
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false // Submission approval in challenge context
        });

        emit ArtChallengeSubmission(_challengeName, challenge.submissionCount, msg.sender, _artMetadataURI);
        challenge.submissionCount++;
    }

    /// @notice Allows members to vote on a submission in an art challenge.
    /// @param _challengeName Name of the art challenge.
    /// @param _submissionId ID of the submission to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnChallengeSubmission(string memory _challengeName, uint256 _submissionId, bool _approve) public onlyMembers challengeExists(_challengeName) submissionExists(_challengeName, _submissionId) {
        require(block.timestamp < artChallenges[_challengeName].endTime, "Challenge voting period has ended."); // Voting ends with challenge end time
        ArtProposal storage submission = artChallenges[_challengeName].submissions[_submissionId];

        if (_approve) {
            submission.yesVotes++;
        } else {
            submission.noVotes++;
        }
        emit ChallengeSubmissionVoted(_challengeName, _submissionId, msg.sender, _approve);
    }

    /// @notice DAO-governed function to reward winners of an art challenge based on votes.
    /// @param _challengeName Name of the art challenge.
    function rewardChallengeWinners(string memory _challengeName) public onlyGovernor challengeExists(_challengeName) {
        ArtChallenge storage challenge = artChallenges[_challengeName];
        require(block.timestamp >= challenge.endTime, "Challenge period has not ended yet.");
        require(challenge.winners.length == 0, "Challenge winners already rewarded."); // Prevent re-rewarding

        uint256 winningVotes = 0;
        address winnerAddress = address(0);
        uint256 winnerSubmissionId = 0;
        address[] potentialWinners;


        for (uint256 i = 0; i < challenge.submissionCount; i++) {
            ArtProposal storage submission = challenge.submissions[i];
            if (submission.yesVotes > winningVotes) {
                winningVotes = submission.yesVotes;
                winnerAddress = submission.proposer;
                potentialWinners = new address[](1);
                potentialWinners[0] = winnerAddress;

            } else if (submission.yesVotes == winningVotes && winningVotes > 0) {
                // In case of a tie, add to potential winners. Simple tie-breaker: first submission wins in tie. Can be more complex tie-breaker.
                 if (winnerAddress == address(0) && submission.yesVotes > 0) { //First winner in a tie
                    winnerAddress = submission.proposer;
                    potentialWinners = new address[](1);
                    potentialWinners[0] = winnerAddress;
                 } else if (winnerAddress != address(0) && submission.proposer != winnerAddress && submission.yesVotes > 0) { // Tie with existing winner, add to potential winners list.
                    address[] memory tempWinners = new address[](potentialWinners.length + 1);
                    for(uint j=0; j < potentialWinners.length; j++){
                        tempWinners[j] = potentialWinners[j];
                    }
                    tempWinners[potentialWinners.length] = submission.proposer;
                    potentialWinners = tempWinners;

                 }
            }
        }

        challenge.winners = potentialWinners; // Set winners - in case of tie, might be multiple winners.
        emit ChallengeWinnersRewarded(_challengeName, challenge.winners, msg.sender);

        // Distribute rewards (NFTs, tokens, ETH) to challenge.winners here if needed.
        // Example: Mint NFTs for winners, or transfer ETH from treasury.
    }

    /// @notice DAO-governed function to create a virtual art exhibition featuring curated art pieces.
    /// @param _exhibitionName Name of the art exhibition.
    /// @param _artIds Array of art piece IDs to include in the exhibition.
    function createArtExhibition(string memory _exhibitionName, uint256[] memory _artIds) public onlyGovernor {
        require(bytes(_exhibitionName).length > 0, "Exhibition name cannot be empty.");
        require(_artIds.length > 0, "Exhibition must include at least one art piece.");
        // Add more validation (e.g., check if artIds are valid, not burned, etc.)

        emit ArtExhibitionCreated(_exhibitionName, _artIds, msg.sender);
        // In a real application, you might store exhibition details, link to a frontend to display the exhibition, etc.
        // This example is simplified to just emit an event.
    }


    /// @notice Allows anyone to donate ETH to the collective treasury.
    function donateToCollective() payable public {
        require(msg.value > 0, "Donation amount must be greater than zero.");
        treasuryBalance += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    /// @notice DAO-governed function to create a new art challenge.
    /// @param _challengeName Name of the challenge.
    /// @param _description Description of the challenge.
    /// @param _endTime Unix timestamp for challenge end time.
    function createArtChallenge(string memory _challengeName, string memory _description, uint256 _endTime) public onlyGovernor {
        require(bytes(_challengeName).length > 0, "Challenge name cannot be empty.");
        require(bytes(_description).length > 0, "Challenge description cannot be empty.");
        require(_endTime > block.timestamp, "Challenge end time must be in the future.");
        require(!artChallenges[_challengeName].isActive, "Challenge with this name already exists or is active."); // Prevent duplicate active challenges


        artChallenges[_challengeName] = ArtChallenge({
            name: _challengeName,
            description: _description,
            startTime: block.timestamp,
            endTime: _endTime,
            isActive: true,
            winners: new address[](0),
            submissions: mapping(uint256 => ArtProposal)(),
            submissionCount: 0
        });
        activeChallengeNames.push(_challengeName); // Keep track of active challenges

        emit ArtChallengeCreated(_challengeName, _description, msg.sender);
    }

    /// @notice  Function to get details of an art challenge by name.
    /// @param _challengeName Name of the challenge.
    /// @return ArtChallenge struct.
    function getArtChallengeDetails(string memory _challengeName) public view challengeExists(_challengeName) returns (ArtChallenge memory) {
        return artChallenges[_challengeName];
    }

    /// @notice Function to get list of active challenge names.
    /// @return Array of active challenge names.
    function getActiveChallengeNames() public view returns (string[] memory) {
        return activeChallengeNames;
    }


    // --- Fallback Function (Optional - for receiving ETH directly) ---
    receive() external payable {
        if (msg.value > 0) {
            donateToCollective(); // Treat direct ETH transfer as a donation
        }
    }
}
```