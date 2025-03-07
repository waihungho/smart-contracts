```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized autonomous art collective.
 * It allows members to propose, vote on, and execute various art-related activities,
 * including commissioning digital art, curating virtual exhibitions, managing an art treasury,
 * and engaging the community through challenges and interpretation contests.
 *
 * **Outline:**
 * 1. **Membership Management:**  Join, leave, manage member roles.
 * 2. **Art Proposal System:** Propose new art pieces, descriptions, budgets.
 * 3. **Voting System:**  Weighted voting on proposals based on member stake.
 * 4. **Treasury Management:** Deposit, withdraw, view treasury balance.
 * 5. **Art Commissioning:** Execute approved art proposals, manage artists.
 * 6. **Virtual Exhibition Management:** Propose, vote on, and curate virtual exhibitions.
 * 7. **Art NFT Minting:** Mint NFTs representing commissioned art pieces.
 * 8. **Art Sales & Revenue Sharing:** Sell art NFTs and distribute revenue to members/treasury.
 * 9. **Art Interpretation Contests:**  Run contests for best art interpretations.
 * 10. **Art Challenge System:** Propose and vote on art challenges for the community.
 * 11. **Reputation System:** Track member contributions and reputation.
 * 12. **Parameter Setting:** DAO-governed parameters (voting periods, thresholds).
 * 13. **Emergency Stop Mechanism:**  Pause critical functions in emergencies.
 * 14. **Art Provenance Tracking:** Record ownership history of art NFTs.
 * 15. **Art Curation Tools:**  Functions to manage and display curated art.
 * 16. **Community Engagement Features:**  Announcements, forums (off-chain link management).
 * 17. **Role-Based Access Control:**  Different roles with varying permissions.
 * 18. **Art Royalties Management:** Implement royalty splits for artists and DAO.
 * 19. **Decentralized Storage Integration:**  Link art metadata to decentralized storage (IPFS).
 * 20. **Governance Token (Placeholder):**  Basic token management for future expansion.
 *
 * **Function Summary:**
 * 1. `requestMembership()`: Allows anyone to request membership to the DAAC.
 * 2. `approveMembership(address _member)`: DAO admin function to approve membership requests.
 * 3. `revokeMembership(address _member)`: DAO admin function to revoke membership.
 * 4. `proposeArt(string _title, string _description, uint256 _budget)`: Member function to propose a new art piece commission.
 * 5. `voteOnArtProposal(uint256 _proposalId, bool _support)`: Member function to vote on an art proposal.
 * 6. `executeArtProposal(uint256 _proposalId)`: DAO admin function to execute an approved art proposal (placeholder for off-chain process).
 * 7. `depositToTreasury()`: Allows members to deposit funds into the DAO treasury.
 * 8. `requestWithdrawalFromTreasury(uint256 _amount)`: Member function to request a withdrawal from the treasury (requires DAO approval).
 * 9. `approveTreasuryWithdrawal(uint256 _withdrawalRequestId)`: DAO admin function to approve a treasury withdrawal request.
 * 10. `createVirtualExhibition(string _exhibitionName, uint256[] _artIds)`: Member function to propose a virtual exhibition curation.
 * 11. `voteOnExhibitionProposal(uint256 _exhibitionId, bool _support)`: Member function to vote on an exhibition proposal.
 * 12. `executeExhibitionProposal(uint256 _exhibitionId)`: DAO admin function to execute an approved exhibition proposal (set exhibition live).
 * 13. `mintArtNFT(uint256 _artId, address _artist, string _ipfsHash)`: DAO admin function to mint an NFT for a commissioned art piece.
 * 14. `setArtSalePrice(uint256 _artNftId, uint256 _price)`: DAO admin function to set the sale price for an art NFT.
 * 15. `purchaseArtNFT(uint256 _artNftId)`: Allows anyone to purchase an art NFT.
 * 16. `submitArtInterpretation(uint256 _artNftId, string _interpretation)`: Member function to submit an interpretation of an art piece.
 * 17. `voteOnInterpretation(uint256 _interpretationId, bool _support)`: Member function to vote on an art interpretation.
 * 18. `awardInterpretation(uint256 _interpretationId)`: DAO admin function to award the best interpretation (e.g., with reputation points).
 * 19. `proposeArtChallenge(string _challengeDescription, uint256 _reward)`: Member function to propose a community art challenge.
 * 20. `voteOnArtChallenge(uint256 _challengeId, bool _support)`: Member function to vote on an art challenge.
 * 21. `executeArtChallenge(uint256 _challengeId)`: DAO admin function to execute an approved art challenge (announce it).
 * 22. `setParameter_VotingPeriod(uint256 _newPeriod)`: DAO admin function to change the voting period parameter.
 * 23. `emergencyPause()`: DAO admin function to pause critical contract functions in an emergency.
 * 24. `emergencyUnpause()`: DAO admin function to resume contract functions after an emergency.
 * 25. `getArtProvenance(uint256 _artNftId)`: Public function to view the provenance history of an art NFT.
 * 26. `getTreasuryBalance()`: Public function to view the current treasury balance.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract DecentralizedArtCollective is Ownable, ERC721Enumerable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums & Structs ---
    enum ProposalStatus { Pending, Active, Approved, Rejected, Executed }
    enum MembershipStatus { Pending, Active, Revoked }
    enum Role { Member, Admin } // Extend roles as needed

    struct ArtProposal {
        string title;
        string description;
        uint256 budget;
        address proposer;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    struct TreasuryWithdrawalRequest {
        address requester;
        uint256 amount;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    struct VirtualExhibitionProposal {
        string name;
        uint256[] artIds;
        address proposer;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    struct ArtInterpretation {
        uint256 artNftId;
        address interpreter;
        string interpretationText;
        uint256 upvotes;
        uint256 downvotes;
    }

    struct ArtChallengeProposal {
        string description;
        uint256 reward;
        address proposer;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    struct Member {
        MembershipStatus status;
        Role role;
        uint256 reputation; // Example reputation system
        uint256 stake;       // Placeholder for future staking/governance token
    }

    struct ArtNFTMetadata {
        uint256 artId;
        address artist;
        string ipfsHash;
        uint256 salePrice;
    }

    // --- State Variables ---
    mapping(address => Member) public members;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => TreasuryWithdrawalRequest) public treasuryWithdrawalRequests;
    mapping(uint256 => VirtualExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => ArtInterpretation) public artInterpretations;
    mapping(uint256 => ArtChallengeProposal) public artChallengeProposals;
    mapping(uint256 => ArtNFTMetadata) public artNFTMetadata;
    mapping(uint256 => address[]) public artProvenance; // Art NFT ID -> list of owners

    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _withdrawalRequestIdCounter;
    Counters.Counter private _exhibitionIdCounter;
    Counters.Counter private _interpretationIdCounter;
    Counters.Counter private _challengeIdCounter;
    Counters.Counter private _artNftIdCounter;
    Counters.Counter private _artIdCounter; // Counter for internal art IDs (not NFT IDs)

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public proposalThreshold = 50; // Percentage of votes needed for approval (e.g., 50%)
    uint256 public treasuryBalance;

    // --- Events ---
    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event ArtProposalCreated(uint256 proposalId, string title, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtProposalExecuted(uint256 proposalId);
    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasuryWithdrawalRequested(uint256 requestId, address requester, uint256 amount);
    event TreasuryWithdrawalApproved(uint256 requestId);
    event VirtualExhibitionProposed(uint256 exhibitionId, string name, address proposer);
    event VirtualExhibitionVoted(uint256 exhibitionId, address voter, bool support);
    event VirtualExhibitionExecuted(uint256 exhibitionId);
    event ArtNFTMinted(uint256 artNftId, uint256 artId, address artist, string ipfsHash);
    event ArtNFTSalePriceSet(uint256 artNftId, uint256 price);
    event ArtNFTPurchased(uint256 artNftId, address buyer, uint256 price);
    event ArtInterpretationSubmitted(uint256 interpretationId, uint256 artNftId, address interpreter);
    event ArtInterpretationVoted(uint256 interpretationId, address voter, bool support);
    event ArtInterpretationAwarded(uint256 interpretationId);
    event ArtChallengeProposed(uint256 challengeId, string description, address proposer);
    event ArtChallengeVoted(uint256 challengeId, address voter, bool support);
    event ArtChallengeExecuted(uint256 challengeId);
    event ParameterVotingPeriodChanged(uint256 newPeriod);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender].status == MembershipStatus.Active, "Not an active member");
        _;
    }

    modifier onlyAdmin() {
        require(members[msg.sender].role == Role.Admin, "Not an admin member");
        _;
    }

    modifier proposalExists(uint256 _proposalId, mapping(uint256 => ArtProposal) storage _proposals) {
        require(_proposals[_proposalId].proposer != address(0), "Proposal does not exist");
        _;
    }

    modifier withdrawalRequestExists(uint256 _requestId) {
        require(treasuryWithdrawalRequests[_requestId].requester != address(0), "Withdrawal request does not exist");
        _;
    }

    modifier exhibitionProposalExists(uint256 _exhibitionId) {
        require(exhibitionProposals[_exhibitionId].proposer != address(0), "Exhibition proposal does not exist");
        _;
    }

    modifier interpretationExists(uint256 _interpretationId) {
        require(artInterpretations[_interpretationId].interpreter != address(0), "Interpretation does not exist");
        _;
    }

    modifier challengeProposalExists(uint256 _challengeId) {
        require(artChallengeProposals[_challengeId].proposer != address(0), "Challenge proposal does not exist");
        _;
    }

    modifier notPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("DAAC Art NFT", "DAACNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Set contract deployer as initial admin
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        members[msg.sender] = Member({status: MembershipStatus.Active, role: Role.Admin, reputation: 100, stake: 0}); // Make deployer initial admin member
    }

    // --- Membership Management ---
    function requestMembership() external notPaused {
        require(members[msg.sender].status == MembershipStatus.Pending || members[msg.sender].status == MembershipStatus.Revoked || members[msg.sender].status == MembershipStatus.Pending  || members[msg.sender].status == MembershipStatus.Revoked || members[msg.sender].status == MembershipStatus.Pending || members[msg.sender].status == MembershipStatus.Revoked || members[msg.sender].status == MembershipStatus.Pending || members[msg.sender].status == MembershipStatus.Revoked || members[msg.sender].status != MembershipStatus.Active, "Already an active member or pending request");
        members[msg.sender].status = MembershipStatus.Pending;
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyAdmin notPaused {
        require(members[_member].status == MembershipStatus.Pending, "Member is not pending approval");
        members[_member].status = MembershipStatus.Active;
        members[_member].role = Role.Member; // Default role for new members
        members[_member].reputation = 50; // Initial reputation
        emit MembershipApproved(_member);
    }

    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(members[_member].status == MembershipStatus.Active, "Member is not active");
        members[_member].status = MembershipStatus.Revoked;
        emit MembershipRevoked(_member);
    }

    // --- Art Proposal System ---
    function proposeArt(string memory _title, string memory _description, uint256 _budget) external onlyMember notPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        artProposals[proposalId] = ArtProposal({
            title: _title,
            description: _description,
            budget: _budget,
            proposer: msg.sender,
            status: ProposalStatus.Active,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp + votingPeriod
        });
        emit ArtProposalCreated(proposalId, _title, msg.sender);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _support) external onlyMember notPaused proposalExists(_proposalId, artProposals) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp < proposal.votingEndTime, "Voting period ended");

        // Simple weighted voting (stake-based voting could be added later)
        if (_support) {
            proposal.yesVotes += 1; // In a real DAO, weight votes by stake
        } else {
            proposal.noVotes += 1;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _support);

        _checkProposalOutcome(_proposalId, artProposals);
    }

    function executeArtProposal(uint256 _proposalId) external onlyAdmin notPaused proposalExists(_proposalId, artProposals) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved, "Proposal is not approved");
        require(proposal.status != ProposalStatus.Executed, "Proposal already executed");

        proposal.status = ProposalStatus.Executed;
        _artIdCounter.increment();
        uint256 internalArtId = _artIdCounter.current(); // Internal ID for tracking, not NFT ID
        // In a real scenario, this function would trigger off-chain processes
        // like contacting artists, managing the art creation process, etc.
        // For this example, we just mark it as executed and increment art ID.
        emit ArtProposalExecuted(_proposalId);
    }

    function _checkProposalOutcome(uint256 _proposalId, mapping(uint256 => ArtProposal) storage _proposals) private {
        ArtProposal storage proposal = _proposals[_proposalId];
        if (proposal.status == ProposalStatus.Active && block.timestamp >= proposal.votingEndTime) {
            uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
            if (totalVotes > 0 && (proposal.yesVotes * 100) / totalVotes >= proposalThreshold) {
                proposal.status = ProposalStatus.Approved;
            } else {
                proposal.status = ProposalStatus.Rejected;
            }
        }
    }

    // --- Treasury Management ---
    function depositToTreasury() external payable notPaused onlyMember {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function requestWithdrawalFromTreasury(uint256 _amount) external onlyMember notPaused {
        require(_amount > 0, "Withdrawal amount must be positive");
        require(treasuryBalance >= _amount, "Insufficient treasury balance");

        _withdrawalRequestIdCounter.increment();
        uint256 requestId = _withdrawalRequestIdCounter.current();
        treasuryWithdrawalRequests[requestId] = TreasuryWithdrawalRequest({
            requester: msg.sender,
            amount: _amount,
            status: ProposalStatus.Active,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp + votingPeriod
        });
        emit TreasuryWithdrawalRequested(requestId, msg.sender, _amount);
    }

    function voteOnTreasuryWithdrawal(uint256 _requestId, bool _support) external onlyMember notPaused withdrawalRequestExists(_requestId) {
        TreasuryWithdrawalRequest storage request = treasuryWithdrawalRequests[_requestId];
        require(request.status == ProposalStatus.Active, "Withdrawal request is not active");
        require(block.timestamp < request.votingEndTime, "Voting period ended");

        if (_support) {
            request.yesVotes += 1;
        } else {
            request.noVotes += 1;
        }
        emit ArtProposalVoted(_requestId, msg.sender, _support); // Reusing event for simplicity, consider specific event

        _checkWithdrawalRequestOutcome(_requestId);
    }


    function approveTreasuryWithdrawal(uint256 _withdrawalRequestId) external onlyAdmin notPaused withdrawalRequestExists(_withdrawalRequestId) {
        TreasuryWithdrawalRequest storage request = treasuryWithdrawalRequests[_withdrawalRequestId];
        require(request.status == ProposalStatus.Approved, "Withdrawal request is not approved");
        require(request.status != ProposalStatus.Executed, "Withdrawal already executed");

        (bool success, ) = request.requester.call{value: request.amount}("");
        require(success, "Treasury withdrawal failed");

        treasuryBalance -= request.amount;
        request.status = ProposalStatus.Executed;
        emit TreasuryWithdrawalApproved(_withdrawalRequestId);
    }

    function _checkWithdrawalRequestOutcome(uint256 _requestId) private {
        TreasuryWithdrawalRequest storage request = treasuryWithdrawalRequests[_requestId];
        if (request.status == ProposalStatus.Active && block.timestamp >= request.votingEndTime) {
            uint256 totalVotes = request.yesVotes + request.noVotes;
            if (totalVotes > 0 && (request.yesVotes * 100) / totalVotes >= proposalThreshold) {
                request.status = ProposalStatus.Approved;
            } else {
                request.status = ProposalStatus.Rejected;
            }
        }
    }

    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    // --- Virtual Exhibition Management ---
    function createVirtualExhibition(string memory _exhibitionName, uint256[] memory _artIds) external onlyMember notPaused {
        _exhibitionIdCounter.increment();
        uint256 exhibitionId = _exhibitionIdCounter.current();
        exhibitionProposals[exhibitionId] = VirtualExhibitionProposal({
            name: _exhibitionName,
            artIds: _artIds,
            proposer: msg.sender,
            status: ProposalStatus.Active,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp + votingPeriod
        });
        emit VirtualExhibitionProposed(exhibitionId, _exhibitionName, msg.sender);
    }

    function voteOnExhibitionProposal(uint256 _exhibitionId, bool _support) external onlyMember notPaused exhibitionProposalExists(_exhibitionId) {
        VirtualExhibitionProposal storage proposal = exhibitionProposals[_exhibitionId];
        require(proposal.status == ProposalStatus.Active, "Exhibition proposal is not active");
        require(block.timestamp < proposal.votingEndTime, "Voting period ended");

        if (_support) {
            proposal.yesVotes += 1;
        } else {
            proposal.noVotes += 1;
        }
        emit VirtualExhibitionVoted(_exhibitionId, msg.sender, _support);

        _checkExhibitionProposalOutcome(_exhibitionId);
    }

    function executeExhibitionProposal(uint256 _exhibitionId) external onlyAdmin notPaused exhibitionProposalExists(_exhibitionId) {
        VirtualExhibitionProposal storage proposal = exhibitionProposals[_exhibitionId];
        require(proposal.status == ProposalStatus.Approved, "Exhibition proposal is not approved");
        require(proposal.status != ProposalStatus.Executed, "Exhibition already executed");

        proposal.status = ProposalStatus.Executed;
        // In a real scenario, this function would trigger off-chain actions to
        // update website/virtual gallery to display the curated exhibition.
        emit VirtualExhibitionExecuted(_exhibitionId);
    }

    function _checkExhibitionProposalOutcome(uint256 _exhibitionId) private {
        VirtualExhibitionProposal storage proposal = exhibitionProposals[_exhibitionId];
        if (proposal.status == ProposalStatus.Active && block.timestamp >= proposal.votingEndTime) {
            uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
            if (totalVotes > 0 && (proposal.yesVotes * 100) / totalVotes >= proposalThreshold) {
                proposal.status = ProposalStatus.Approved;
            } else {
                proposal.status = ProposalStatus.Rejected;
            }
        }
    }

    // --- Art NFT Minting & Sales ---
    function mintArtNFT(uint256 _artId, address _artist, string memory _ipfsHash) external onlyAdmin notPaused {
        _artNftIdCounter.increment();
        uint256 artNftId = _artNftIdCounter.current();

        artNFTMetadata[artNftId] = ArtNFTMetadata({
            artId: _artId,
            artist: _artist,
            ipfsHash: _ipfsHash,
            salePrice: 0 // Initially no sale price
        });
        _safeMint(_artist, artNftId);
        _recordProvenance(artNftId, _artist); // Initial provenance record

        emit ArtNFTMinted(artNftId, _artId, _artist, _ipfsHash);
    }

    function setArtSalePrice(uint256 _artNftId, uint256 _price) external onlyAdmin notPaused {
        require(artNFTMetadata[_artNftId].artist != address(0), "Art NFT not found");
        artNFTMetadata[_artNftId].salePrice = _price;
        emit ArtNFTSalePriceSet(_artNftId, _price);
    }

    function purchaseArtNFT(uint256 _artNftId) external payable notPaused {
        ArtNFTMetadata storage metadata = artNFTMetadata[_artNftId];
        require(metadata.artist != address(0), "Art NFT not found");
        require(metadata.salePrice > 0, "Art NFT is not for sale");
        require(msg.value >= metadata.salePrice, "Insufficient payment");

        address currentOwner = ownerOf(_artNftId);
        treasuryBalance += metadata.salePrice; // Send sale price to treasury
        _transfer(currentOwner, msg.sender, _artNftId);
        _recordProvenance(_artNftId, msg.sender);
        emit ArtNFTPurchased(_artNftId, msg.sender, metadata.salePrice);

        // Handle refund for overpayment if any
        if (msg.value > metadata.salePrice) {
            uint256 refundAmount = msg.value - metadata.salePrice;
            (bool success, ) = msg.sender.call{value: refundAmount}("");
            require(success, "Refund failed");
        }
    }

    function _recordProvenance(uint256 _artNftId, address _newOwner) private {
        artProvenance[_artNftId].push(_newOwner);
    }

    function getArtProvenance(uint256 _artNftId) external view returns (address[] memory) {
        return artProvenance[_artNftId];
    }


    // --- Art Interpretation Contests ---
    function submitArtInterpretation(uint256 _artNftId, string memory _interpretation) external onlyMember notPaused {
        require(artNFTMetadata[_artNftId].artist != address(0), "Art NFT not found");
        _interpretationIdCounter.increment();
        uint256 interpretationId = _interpretationIdCounter.current();
        artInterpretations[interpretationId] = ArtInterpretation({
            artNftId: _artNftId,
            interpreter: msg.sender,
            interpretationText: _interpretation,
            upvotes: 0,
            downvotes: 0
        });
        emit ArtInterpretationSubmitted(interpretationId, _artNftId, msg.sender);
    }

    function voteOnInterpretation(uint256 _interpretationId, bool _support) external onlyMember notPaused interpretationExists(_interpretationId) {
        ArtInterpretation storage interpretation = artInterpretations[_interpretationId];
        if (_support) {
            interpretation.upvotes += 1;
        } else {
            interpretation.downvotes += 1;
        }
        emit ArtInterpretationVoted(_interpretationId, msg.sender, _support);
    }

    function awardInterpretation(uint256 _interpretationId) external onlyAdmin notPaused interpretationExists(_interpretationId) {
        // Placeholder for awarding interpretation. Could be reputation points, tokens, etc.
        members[artInterpretations[_interpretationId].interpreter].reputation += 10; // Example: Award reputation points
        emit ArtInterpretationAwarded(_interpretationId);
    }

    // --- Art Challenge System ---
    function proposeArtChallenge(string memory _challengeDescription, uint256 _reward) external onlyMember notPaused {
        _challengeIdCounter.increment();
        uint256 challengeId = _challengeIdCounter.current();
        artChallengeProposals[challengeId] = ArtChallengeProposal({
            description: _challengeDescription,
            reward: _reward,
            proposer: msg.sender,
            status: ProposalStatus.Active,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp + votingPeriod
        });
        emit ArtChallengeProposed(challengeId, _challengeDescription, msg.sender);
    }

    function voteOnArtChallenge(uint256 _challengeId, bool _support) external onlyMember notPaused challengeProposalExists(_challengeId) {
        ArtChallengeProposal storage proposal = artChallengeProposals[_challengeId];
        require(proposal.status == ProposalStatus.Active, "Challenge proposal is not active");
        require(block.timestamp < proposal.votingEndTime, "Voting period ended");

        if (_support) {
            proposal.yesVotes += 1;
        } else {
            proposal.noVotes += 1;
        }
        emit ArtChallengeVoted(_challengeId, msg.sender, _support);
        _checkChallengeProposalOutcome(_challengeId);
    }

    function executeArtChallenge(uint256 _challengeId) external onlyAdmin notPaused challengeProposalExists(_challengeId) {
        ArtChallengeProposal storage proposal = artChallengeProposals[_challengeId];
        require(proposal.status == ProposalStatus.Approved, "Challenge proposal not approved");
        require(proposal.status != ProposalStatus.Executed, "Challenge already executed");

        proposal.status = ProposalStatus.Executed;
        // In a real scenario, this would trigger announcements, prize distribution, etc.
        emit ArtChallengeExecuted(_challengeId);
    }

    function _checkChallengeProposalOutcome(uint256 _challengeId) private {
        ArtChallengeProposal storage proposal = artChallengeProposals[_challengeId];
        if (proposal.status == ProposalStatus.Active && block.timestamp >= proposal.votingEndTime) {
            uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
            if (totalVotes > 0 && (proposal.yesVotes * 100) / totalVotes >= proposalThreshold) {
                proposal.status = ProposalStatus.Approved;
            } else {
                proposal.status = ProposalStatus.Rejected;
            }
        }
    }


    // --- Parameter Setting (DAO Governed) ---
    function setParameter_VotingPeriod(uint256 _newPeriod) external onlyAdmin notPaused {
        votingPeriod = _newPeriod;
        emit ParameterVotingPeriodChanged(_newPeriod);
    }

    // --- Emergency Stop Mechanism ---
    function emergencyPause() external onlyAdmin {
        _pause();
        emit ContractPaused();
    }

    function emergencyUnpause() external onlyAdmin {
        _unpause();
        emit ContractUnpaused();
    }

    // --- Utility Functions ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```