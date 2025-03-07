```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling collaborative art creation,
 *      governance, exhibitions, and revenue sharing. This contract explores advanced concepts like
 *      dynamic NFT traits, on-chain voting for art style, collaborative art pieces, and decentralized curation.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership & Governance:**
 *    - `proposeNewMember(address _newMember)`: Allows current members to propose new members.
 *    - `voteOnMemberProposal(uint256 _proposalId, bool _vote)`: Members can vote on pending membership proposals.
 *    - `revokeMembership(address _member)`: Allows members to propose and vote to revoke membership.
 *    - `depositFunds()`: Members can deposit funds into the collective's treasury.
 *    - `withdrawFunds(uint256 _amount)`: Allows members to propose and vote on withdrawals from the treasury.
 *    - `proposeNewRule(string memory _ruleDescription)`: Members can propose new rules for the collective.
 *    - `voteOnRuleProposal(uint256 _proposalId, bool _vote)`: Members can vote on pending rule proposals.
 *
 * **2. Art Creation & Management:**
 *    - `submitArtProposal(string memory _artTitle, string memory _artDescription, string memory _initialStyleKeywords)`: Members can propose new art pieces with initial details and style keywords.
 *    - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members vote on art proposals to decide which pieces get created.
 *    - `setArtStyleDirection(uint256 _artId, string memory _styleKeyword)`: Members can propose and vote on style directions for approved art pieces, influencing dynamic traits.
 *    - `mintArtNFT(uint256 _artId)`: After style direction is finalized, mints the art piece as a dynamic NFT.
 *    - `setArtMetadataURI(uint256 _artId, string memory _metadataURI)`:  Sets the metadata URI for an art NFT, allowing for off-chain storage of art data.
 *    - `burnUnmintedArt(uint256 _artId)`: In case an art piece is no longer desired after approval but before minting, it can be 'burned' (removed from active proposals).
 *
 * **3. Exhibition & Sales:**
 *    - `createExhibition(string memory _exhibitionTitle)`: Allows members to propose and vote to create new art exhibitions.
 *    - `addArtToExhibition(uint256 _exhibitionId, uint256 _artId)`:  Allows members to propose and vote to add art pieces to exhibitions.
 *    - `removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId)`: Allows members to propose and vote to remove art from exhibitions.
 *    - `setExhibitionTicketPrice(uint256 _exhibitionId, uint256 _price)`: Allows members to propose and vote to set ticket prices for exhibitions.
 *    - `buyExhibitionTicket(uint256 _exhibitionId) payable`: Allows anyone to buy a ticket to an exhibition.
 *    - `sellArtNFT(uint256 _artId, uint256 _price)`: Allows members to propose and vote to sell an art NFT at a set price.
 *
 * **4. Revenue & Payouts:**
 *    - `distributeExhibitionRevenue(uint256 _exhibitionId)`: Distributes revenue from exhibition ticket sales to collective members (proportional to stake/voting power).
 *    - `distributeArtSaleRevenue(uint256 _artId)`: Distributes revenue from NFT sales to collective members.
 *
 * **5. Utility & Info:**
 *    - `getMemberCount()`: Returns the current number of members in the collective.
 *    - `getArtProposalDetails(uint256 _proposalId)`: Returns details of a specific art proposal.
 *    - `getExhibitionDetails(uint256 _exhibitionId)`: Returns details of a specific exhibition.
 *    - `isMember(address _account)`: Checks if an address is a member of the collective.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Membership & Governance
    mapping(address => bool) public members;
    address[] public memberList;
    uint256 public membershipFee; // Optional: Could be implemented for new members
    uint256 public votingDuration = 7 days;
    uint256 public quorumPercentage = 51; // Percentage of members needed to pass a vote
    uint256 public treasuryBalance;

    struct Proposal {
        ProposalType proposalType;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        string description; // For rule proposals, etc.
        address proposedMember; // For member proposals
        address memberToRevoke; // For revoke member proposals
        uint256 withdrawalAmount; // For withdrawal proposals
        uint256 artProposalId; // For art related proposals
        uint256 exhibitionId; // For exhibition related proposals
        string ruleDescription; // For rule proposals
        string styleKeyword; // For style direction proposals
        uint256 ticketPrice; // For exhibition ticket price proposals
        uint256 artIdToSell; // For art NFT sales proposals
        uint256 artSalePrice; // For art NFT sales proposals
    }

    enum ProposalType {
        MEMBERSHIP,
        REVOKE_MEMBERSHIP,
        RULE_CHANGE,
        TREASURY_WITHDRAWAL,
        ART_PROPOSAL,
        ART_STYLE_DIRECTION,
        EXHIBITION_CREATION,
        EXHIBITION_ART_ADD,
        EXHIBITION_ART_REMOVE,
        EXHIBITION_TICKET_PRICE,
        ART_NFT_SALE
    }

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter public proposalCounter;

    // Art Creation & Management
    struct ArtPiece {
        string title;
        string description;
        string styleKeywords;
        string currentStyleDirection; // Dynamic trait - influenced by votes
        bool minted;
        string metadataURI;
    }
    mapping(uint256 => ArtPiece) public artPieces;
    Counters.Counter public artCounter;

    // Exhibition & Sales
    struct Exhibition {
        string title;
        uint256 ticketPrice;
        uint256[] artPieceIds;
        bool active;
    }
    mapping(uint256 => Exhibition) public exhibitions;
    Counters.Counter public exhibitionCounter;

    mapping(uint256 => mapping(address => bool)) public exhibitionTicketHolders; // exhibitionId => holderAddress => hasTicket

    // Events
    event MemberProposed(uint256 proposalId, address proposer, address newMember);
    event MemberProposalVoted(uint256 proposalId, address voter, bool vote);
    event MemberAdded(address newMember);
    event MemberRevocationProposed(uint256 proposalId, address proposer, address memberToRevoke);
    event MemberRevoked(address revokedMember);
    event FundsDeposited(address member, uint256 amount);
    event FundsWithdrawn(uint256 proposalId, address recipient, uint256 amount);
    event RuleProposalCreated(uint256 proposalId, address proposer, string ruleDescription);
    event RuleProposalVoted(uint256 proposalId, address voter, bool vote);
    event RuleChanged(string newRule);
    event ArtProposalCreated(uint256 proposalId, address proposer, string artTitle);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtPieceMinted(uint256 artId, uint256 tokenId);
    event ArtStyleDirectionProposed(uint256 proposalId, uint256 artId, string styleKeyword);
    event ArtStyleDirectionSet(uint256 artId, string styleKeyword);
    event ArtMetadataURISet(uint256 artId, string metadataURI);
    event ExhibitionCreated(uint256 exhibitionId, string title);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artId);
    event ExhibitionTicketPriceSet(uint256 exhibitionId, uint256 price);
    event ExhibitionTicketBought(uint256 exhibitionId, address buyer);
    event ArtNFTSaleProposed(uint256 proposalId, uint256 artId, uint256 price);
    event ArtNFTSold(uint256 artId, uint256 price, address buyer);
    event ExhibitionRevenueDistributed(uint256 exhibitionId, uint256 totalRevenue);
    event ArtSaleRevenueDistributed(uint256 artId, uint256 totalRevenue);
    event ArtBurned(uint256 artId);


    // --- Constructor ---
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _setOwner(_msgSender()); // Deployer is initial owner (can be DAO itself in real world)
        _addMember(_msgSender()); // Deployer is the first member
    }

    // --- Modifiers ---
    modifier onlyMember() {
        require(members[_msgSender()], "Not a member");
        _;
    }

    modifier onlyProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter.current, "Invalid proposal ID");
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(proposals[_proposalId].endTime > block.timestamp && !proposals[_proposalId].executed, "Proposal is not active");
        _;
    }

    modifier onlyArtExists(uint256 _artId) {
        require(_artId > 0 && _artId <= artCounter.current, "Invalid art ID");
        _;
    }

    modifier onlyExhibitionExists(uint256 _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId <= exhibitionCounter.current, "Invalid exhibition ID");
        _;
    }

    modifier onlyArtNotMinted(uint256 _artId) {
        require(!artPieces[_artId].minted, "Art already minted");
        _;
    }

    modifier onlyArtMinted(uint256 _artId) {
        require(artPieces[_artId].minted, "Art not yet minted");
        _;
    }


    // --- 1. Membership & Governance ---

    function _addMember(address _newMember) internal {
        require(!members[_newMember], "Address is already a member");
        members[_newMember] = true;
        memberList.push(_newMember);
        emit MemberAdded(_newMember);
    }

    function _removeMember(address _member) internal {
        require(members[_member], "Address is not a member");
        members[_member] = false;
        // Remove from memberList (more gas-efficient ways in real-world scenarios if needed for frequent removals)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MemberRevoked(_member);
    }

    function proposeNewMember(address _newMember) external onlyMember {
        require(!members[_newMember], "Address is already a member");
        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.MEMBERSHIP,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to add new member",
            proposedMember: _newMember,
            memberToRevoke: address(0),
            withdrawalAmount: 0,
            artProposalId: 0,
            exhibitionId: 0,
            ruleDescription: "",
            styleKeyword: "",
            ticketPrice: 0,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit MemberProposed(proposalId, _msgSender(), _newMember);
    }

    function voteOnMemberProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.MEMBERSHIP, "Proposal is not a membership proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit MemberProposalVoted(_proposalId, _msgSender(), _vote);

        _checkAndExecuteProposal(_proposalId);
    }

    function revokeMembership(address _member) external onlyMember {
        require(members[_member] && _member != owner(), "Cannot revoke membership of non-member or owner");
        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.REVOKE_MEMBERSHIP,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to revoke membership",
            proposedMember: address(0),
            memberToRevoke: _member,
            withdrawalAmount: 0,
            artProposalId: 0,
            exhibitionId: 0,
            ruleDescription: "",
            styleKeyword: "",
            ticketPrice: 0,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit MemberRevocationProposed(proposalId, _msgSender(), _member);
    }

    function voteOnRevokeMembershipProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.REVOKE_MEMBERSHIP, "Proposal is not a revoke membership proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit MemberProposalVoted(_proposalId, _msgSender(), _vote);

        _checkAndExecuteProposal(_proposalId);
    }


    function depositFunds() external payable onlyMember {
        treasuryBalance += msg.value;
        emit FundsDeposited(_msgSender(), msg.value);
    }

    function withdrawFunds(uint256 _amount) external onlyMember {
        require(_amount > 0, "Withdrawal amount must be positive");
        require(_amount <= treasuryBalance, "Insufficient treasury balance");

        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.TREASURY_WITHDRAWAL,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to withdraw funds from treasury",
            proposedMember: address(0),
            memberToRevoke: address(0),
            withdrawalAmount: _amount,
            artProposalId: 0,
            exhibitionId: 0,
            ruleDescription: "",
            styleKeyword: "",
            ticketPrice: 0,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit FundsWithdrawalProposed(proposalId, _msgSender(), _amount); // Custom event
    }

    event FundsWithdrawalProposed(uint256 proposalId, address proposer, uint256 amount); // Custom event

    function voteOnWithdrawalProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.TREASURY_WITHDRAWAL, "Proposal is not a withdrawal proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit RuleProposalVoted(_proposalId, _msgSender(), _vote); // Reusing event, might create specific one

        _checkAndExecuteProposal(_proposalId);
    }


    function proposeNewRule(string memory _ruleDescription) external onlyMember {
        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.RULE_CHANGE,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to change collective rules",
            proposedMember: address(0),
            memberToRevoke: address(0),
            withdrawalAmount: 0,
            artProposalId: 0,
            exhibitionId: 0,
            ruleDescription: _ruleDescription,
            styleKeyword: "",
            ticketPrice: 0,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit RuleProposalCreated(proposalId, _msgSender(), _ruleDescription);
    }

    function voteOnRuleProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.RULE_CHANGE, "Proposal is not a rule change proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit RuleProposalVoted(_proposalId, _msgSender(), _vote);

        _checkAndExecuteProposal(_proposalId);
    }


    function _checkAndExecuteProposal(uint256 _proposalId) internal {
        if (block.timestamp > proposals[_proposalId].endTime && !proposals[_proposalId].executed) {
            uint256 totalMembers = memberList.length;
            uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;

            if (proposals[_proposalId].yesVotes >= requiredVotes) {
                proposals[_proposalId].executed = true;
                ProposalType pType = proposals[_proposalId].proposalType;

                if (pType == ProposalType.MEMBERSHIP) {
                    _addMember(proposals[_proposalId].proposedMember);
                } else if (pType == ProposalType.REVOKE_MEMBERSHIP) {
                    _removeMember(proposals[_proposalId].memberToRevoke);
                } else if (pType == ProposalType.RULE_CHANGE) {
                    emit RuleChanged(proposals[_proposalId].ruleDescription); // Example: Store rules off-chain or in a more structured way in real-world
                } else if (pType == ProposalType.TREASURY_WITHDRAWAL) {
                    uint256 amount = proposals[_proposalId].withdrawalAmount;
                    payable(proposals[_proposalId].proposer).transfer(amount); // Proposer initiates withdrawal - could be different recipient in real-world
                    treasuryBalance -= amount;
                    emit FundsWithdrawn(_proposalId, proposals[_proposalId].proposer, amount);
                } else if (pType == ProposalType.ART_PROPOSAL) {
                    // Art proposal logic is handled in voteOnArtProposal to allow for style voting later
                } else if (pType == ProposalType.ART_STYLE_DIRECTION) {
                    uint256 artId = proposals[_proposalId].artProposalId;
                    artPieces[artId].currentStyleDirection = proposals[_proposalId].styleKeyword;
                    emit ArtStyleDirectionSet(artId, proposals[_proposalId].styleKeyword);
                } else if (pType == ProposalType.EXHIBITION_CREATION) {
                    exhibitions[proposals[_proposalId].exhibitionId].active = true;
                    emit ExhibitionCreated(proposals[_proposalId].exhibitionId, exhibitions[proposals[_proposalId].exhibitionId].title);
                } else if (pType == ProposalType.EXHIBITION_ART_ADD) {
                    uint256 exhibitionId = proposals[_proposalId].exhibitionId;
                    uint256 artId = proposals[_proposalId].artProposalId;
                    exhibitions[exhibitionId].artPieceIds.push(artId);
                    emit ArtAddedToExhibition(exhibitionId, artId);
                } else if (pType == ProposalType.EXHIBITION_ART_REMOVE) {
                    uint256 exhibitionId = proposals[_proposalId].exhibitionId;
                    uint256 artId = proposals[_proposalId].artProposalId;
                    _removeArtFromExhibitionInternal(exhibitionId, artId); // Internal helper function to remove art from exhibition array
                    emit ArtRemovedFromExhibition(exhibitionId, artId);
                } else if (pType == ProposalType.EXHIBITION_TICKET_PRICE) {
                    uint256 exhibitionId = proposals[_proposalId].exhibitionId;
                    exhibitions[exhibitionId].ticketPrice = proposals[_proposalId].ticketPrice;
                    emit ExhibitionTicketPriceSet(exhibitionId, proposals[_proposalId].ticketPrice);
                } else if (pType == ProposalType.ART_NFT_SALE) {
                    // Art NFT sale logic handled in voteOnArtNFTSale to allow for sale execution later
                }
            }
        }
    }

    // --- 2. Art Creation & Management ---

    function submitArtProposal(string memory _artTitle, string memory _artDescription, string memory _initialStyleKeywords) external onlyMember {
        artCounter.increment();
        uint256 artId = artCounter.current;
        artPieces[artId] = ArtPiece({
            title: _artTitle,
            description: _artDescription,
            styleKeywords: _initialStyleKeywords,
            currentStyleDirection: "", // Initially no style direction
            minted: false,
            metadataURI: ""
        });

        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.ART_PROPOSAL,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to create new art piece: " + _artTitle,
            proposedMember: address(0),
            memberToRevoke: address(0),
            withdrawalAmount: 0,
            artProposalId: artId,
            exhibitionId: 0,
            ruleDescription: "",
            styleKeyword: "",
            ticketPrice: 0,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit ArtProposalCreated(proposalId, _msgSender(), _artTitle);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.ART_PROPOSAL, "Proposal is not an art proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, _msgSender(), _vote);

        if (block.timestamp > proposals[_proposalId].endTime && !proposals[_proposalId].executed) {
            uint256 totalMembers = memberList.length;
            uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;

            if (proposals[_proposalId].yesVotes >= requiredVotes) {
                proposals[_proposalId].executed = true;
                // Art proposal approved - now members can propose style directions for this art piece
            } else {
                // Art proposal rejected - maybe burn it or mark as rejected (not implemented here for simplicity)
                burnUnmintedArt(proposals[_proposalId].artProposalId); // Burn rejected art proposals
            }
        }
    }

    function setArtStyleDirection(uint256 _artId, string memory _styleKeyword) external onlyMember onlyArtExists(_artId) onlyArtNotMinted(_artId) {
        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.ART_STYLE_DIRECTION,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to set style direction for art piece",
            proposedMember: address(0),
            memberToRevoke: address(0),
            withdrawalAmount: 0,
            artProposalId: _artId,
            exhibitionId: 0,
            ruleDescription: "",
            styleKeyword: _styleKeyword,
            ticketPrice: 0,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit ArtStyleDirectionProposed(proposalId, _artId, _styleKeyword);
    }

    function voteOnStyleDirectionProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.ART_STYLE_DIRECTION, "Proposal is not a style direction proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, _msgSender(), _vote); // Reusing event, might create specific one

        _checkAndExecuteProposal(_proposalId);
    }


    function mintArtNFT(uint256 _artId) external onlyMember onlyArtExists(_artId) onlyArtNotMinted(_artId) {
        require(bytes(artPieces[_artId].currentStyleDirection).length > 0, "Style direction must be set before minting"); // Style direction must be voted on

        _mint(_msgSender(), _artId); // tokenId is artId for simplicity
        artPieces[_artId].minted = true;
        emit ArtPieceMinted(_artId, _artId);
    }

    function setArtMetadataURI(uint256 _artId, string memory _metadataURI) external onlyMember onlyArtExists(_artId) onlyArtMinted(_artId) {
        artPieces[_artId].metadataURI = _metadataURI;
        emit ArtMetadataURISet(_artId, _metadataURI);
    }

    function burnUnmintedArt(uint256 _artId) public onlyMember onlyArtExists(_artId) onlyArtNotMinted(_artId) {
        delete artPieces[_artId]; // Remove art piece data
        emit ArtBurned(_artId);
    }


    // --- 3. Exhibition & Sales ---

    function createExhibition(string memory _exhibitionTitle) external onlyMember {
        exhibitionCounter.increment();
        uint256 exhibitionId = exhibitionCounter.current;
        exhibitions[exhibitionId] = Exhibition({
            title: _exhibitionTitle,
            ticketPrice: 0, // Default ticket price
            artPieceIds: new uint256[](0),
            active: false // Exhibition needs to be activated by voting
        });

        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.EXHIBITION_CREATION,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to create new exhibition: " + _exhibitionTitle,
            proposedMember: address(0),
            memberToRevoke: address(0),
            withdrawalAmount: 0,
            artProposalId: 0,
            exhibitionId: exhibitionId,
            ruleDescription: "",
            styleKeyword: "",
            ticketPrice: 0,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit ExhibitionCreated(proposalId, _exhibitionTitle);
    }

    function voteOnExhibitionCreationProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.EXHIBITION_CREATION, "Proposal is not an exhibition creation proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, _msgSender(), _vote); // Reusing event, might create specific one

        _checkAndExecuteProposal(_proposalId);
    }


    function addArtToExhibition(uint256 _exhibitionId, uint256 _artId) external onlyMember onlyExhibitionExists(_exhibitionId) onlyArtExists(_artId) onlyArtMinted(_artId) {
        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.EXHIBITION_ART_ADD,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to add art to exhibition",
            proposedMember: address(0),
            memberToRevoke: address(0),
            withdrawalAmount: 0,
            artProposalId: _artId,
            exhibitionId: _exhibitionId,
            ruleDescription: "",
            styleKeyword: "",
            ticketPrice: 0,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit ArtAddedToExhibitionProposalCreated(proposalId, _exhibitionId, _artId); // Custom Event
    }

    event ArtAddedToExhibitionProposalCreated(uint256 proposalId, uint256 exhibitionId, uint256 artId); // Custom Event

    function voteOnAddArtToExhibitionProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.EXHIBITION_ART_ADD, "Proposal is not an add art to exhibition proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, _msgSender(), _vote); // Reusing event, might create specific one

        _checkAndExecuteProposal(_proposalId);
    }


    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId) external onlyMember onlyExhibitionExists(_exhibitionId) onlyArtExists(_artId) onlyArtMinted(_artId) {
         proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.EXHIBITION_ART_REMOVE,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to remove art from exhibition",
            proposedMember: address(0),
            memberToRevoke: address(0),
            withdrawalAmount: 0,
            artProposalId: _artId,
            exhibitionId: _exhibitionId,
            ruleDescription: "",
            styleKeyword: "",
            ticketPrice: 0,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit ArtRemovedFromExhibitionProposalCreated(proposalId, _exhibitionId, _artId); // Custom Event
    }

    event ArtRemovedFromExhibitionProposalCreated(uint256 proposalId, uint256 exhibitionId, uint256 artId); // Custom Event


    function voteOnRemoveArtFromExhibitionProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.EXHIBITION_ART_REMOVE, "Proposal is not a remove art from exhibition proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, _msgSender(), _vote); // Reusing event, might create specific one

        _checkAndExecuteProposal(_proposalId);
    }

    function _removeArtFromExhibitionInternal(uint256 _exhibitionId, uint256 _artId) internal {
        uint256[] storage artIds = exhibitions[_exhibitionId].artPieceIds;
        for (uint256 i = 0; i < artIds.length; i++) {
            if (artIds[i] == _artId) {
                artIds[i] = artIds[artIds.length - 1];
                artIds.pop();
                break;
            }
        }
    }


    function setExhibitionTicketPrice(uint256 _exhibitionId, uint256 _price) external onlyMember onlyExhibitionExists(_exhibitionId) {
        require(_price >= 0, "Ticket price must be non-negative");
        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.EXHIBITION_TICKET_PRICE,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to set exhibition ticket price",
            proposedMember: address(0),
            memberToRevoke: address(0),
            withdrawalAmount: 0,
            artProposalId: 0,
            exhibitionId: _exhibitionId,
            ruleDescription: "",
            styleKeyword: "",
            ticketPrice: _price,
            artIdToSell: 0,
            artSalePrice: 0
        });
        emit ExhibitionTicketPriceProposalCreated(proposalId, _exhibitionId, _price); // Custom Event
    }

    event ExhibitionTicketPriceProposalCreated(uint256 proposalId, uint256 exhibitionId, uint256 price); // Custom Event

    function voteOnSetExhibitionTicketPriceProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.EXHIBITION_TICKET_PRICE, "Proposal is not a set ticket price proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, _msgSender(), _vote); // Reusing event, might create specific one

        _checkAndExecuteProposal(_proposalId);
    }


    function buyExhibitionTicket(uint256 _exhibitionId) external payable onlyExhibitionExists(_exhibitionId) {
        require(exhibitions[_exhibitionId].active, "Exhibition is not active");
        require(!exhibitionTicketHolders[_exhibitionId][_msgSender()], "Already have a ticket"); // Prevent duplicate tickets

        uint256 ticketPrice = exhibitions[_exhibitionId].ticketPrice;
        require(msg.value >= ticketPrice, "Insufficient payment");

        exhibitionTicketHolders[_exhibitionId][_msgSender()] = true;
        treasuryBalance += ticketPrice; // Revenue goes to collective treasury
        emit ExhibitionTicketBought(_exhibitionId, _msgSender());

        if (msg.value > ticketPrice) {
            payable(_msgSender()).transfer(msg.value - ticketPrice); // Refund excess payment
        }
    }

    function sellArtNFT(uint256 _artId, uint256 _price) external onlyMember onlyArtExists(_artId) onlyArtMinted(_artId) {
        require(_price > 0, "Sale price must be positive");
        require(ownerOf(_artId) == address(this), "Contract must own the NFT to sell"); // Ensure contract owns the NFT

        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.ART_NFT_SALE,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: "Proposal to sell art NFT",
            proposedMember: address(0),
            memberToRevoke: address(0),
            withdrawalAmount: 0,
            artProposalId: 0,
            exhibitionId: 0,
            ruleDescription: "",
            styleKeyword: "",
            ticketPrice: 0,
            artIdToSell: _artId,
            artSalePrice: _price
        });
        emit ArtNFTSaleProposed(proposalId, _artId, _price);
    }

    function voteOnArtNFTSaleProposal(uint256 _proposalId, bool _vote) external onlyMember onlyProposalExists(_proposalId) onlyActiveProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.ART_NFT_SALE, "Proposal is not an art NFT sale proposal");
        require(_msgSender() != proposals[_proposalId].proposer, "Proposer cannot vote on their own proposal"); // Optional

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, _msgSender(), _vote); // Reusing event, might create specific one

        if (block.timestamp > proposals[_proposalId].endTime && !proposals[_proposalId].executed) {
            uint256 totalMembers = memberList.length;
            uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;

            if (proposals[_proposalId].yesVotes >= requiredVotes) {
                proposals[_proposalId].executed = true;
                // Art NFT sale approved - ready for purchase
            }
        }
    }

    function purchaseArtNFT(uint256 _proposalId) external payable onlyProposalExists(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.ART_NFT_SALE, "Proposal is not an art NFT sale proposal");
        require(proposals[_proposalId].executed, "Art NFT sale proposal not yet approved or failed");
        require(proposals[_proposalId].endTime < block.timestamp, "Art NFT sale proposal is still active, wait for voting to end"); // Ensure voting ended and executed

        uint256 artId = proposals[_proposalId].artIdToSell;
        uint256 salePrice = proposals[_proposalId].artSalePrice;

        require(msg.value >= salePrice, "Insufficient payment for art NFT");

        _transfer(address(this), _msgSender(), artId); // Transfer NFT to buyer
        treasuryBalance += salePrice; // Revenue to collective treasury
        emit ArtNFTSold(artId, salePrice, _msgSender());

        if (msg.value > salePrice) {
            payable(_msgSender()).transfer(msg.value - salePrice); // Refund excess payment
        }
    }


    // --- 4. Revenue & Payouts ---

    function distributeExhibitionRevenue(uint256 _exhibitionId) external onlyMember onlyExhibitionExists(_exhibitionId) {
        require(exhibitions[_exhibitionId].active, "Exhibition must be active to distribute revenue");

        uint256 totalRevenue = 0;
        uint256 ticketPrice = exhibitions[_exhibitionId].ticketPrice;
        uint256 ticketCount = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (exhibitionTicketHolders[_exhibitionId][memberList[i]]) {
                ticketCount++;
            }
        }
        totalRevenue = ticketCount * ticketPrice; // Calculate revenue based on ticket holders (can be more robust in real world)
        require(totalRevenue <= treasuryBalance, "Insufficient treasury balance to distribute exhibition revenue");

        uint256 revenuePerMember = totalRevenue / memberList.length; // Simple equal distribution for example

        for (uint256 i = 0; i < memberList.length; i++) {
            payable(memberList[i]).transfer(revenuePerMember); // Distribute equally to members - can be weighted by stake in real-world DAO
        }

        treasuryBalance -= totalRevenue;
        emit ExhibitionRevenueDistributed(_exhibitionId, totalRevenue);
    }

    function distributeArtSaleRevenue(uint256 _artId) external onlyMember onlyArtExists(_artId) onlyArtMinted(_artId) {
        require(ownerOf(_artId) != address(this), "Art NFT must be sold to distribute revenue"); // Check if NFT has been sold

        uint256 artSaleProposalId = 0;
        for (uint256 i = 1; i <= proposalCounter.current; i++) {
            if (proposals[i].proposalType == ProposalType.ART_NFT_SALE && proposals[i].artIdToSell == _artId && proposals[i].executed) {
                artSaleProposalId = i;
                break;
            }
        }
        require(artSaleProposalId > 0, "Art sale proposal not found or not executed");

        uint256 totalRevenue = proposals[artSaleProposalId].artSalePrice;
        require(totalRevenue <= treasuryBalance, "Insufficient treasury balance to distribute art sale revenue");


        uint256 revenuePerMember = totalRevenue / memberList.length; // Simple equal distribution for example

        for (uint256 i = 0; i < memberList.length; i++) {
            payable(memberList[i]).transfer(revenuePerMember); // Distribute equally to members - can be weighted by stake in real-world DAO
        }

        treasuryBalance -= totalRevenue;
        emit ArtSaleRevenueDistributed(_artId, totalRevenue);
    }


    // --- 5. Utility & Info ---

    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    function getArtProposalDetails(uint256 _proposalId) external view onlyProposalExists(_proposalId) returns (Proposal memory) {
        require(proposals[_proposalId].proposalType == ProposalType.ART_PROPOSAL, "Proposal is not an art proposal");
        return proposals[_proposalId];
    }

    function getExhibitionDetails(uint256 _exhibitionId) external view onlyExhibitionExists(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    function isMember(address _account) external view returns (bool) {
        return members[_account];
    }

    // --- Overrides for ERC721 ---
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return artPieces[_tokenId].metadataURI; // Fetch metadata URI from ArtPiece struct
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add any custom logic before token transfer if needed (e.g., royalties, transfer restrictions)
    }

    // --- Owner Functions (Example - for initial setup or emergency) ---
    function setVotingDuration(uint256 _durationInSeconds) external onlyOwner {
        votingDuration = _durationInSeconds;
    }

    function setQuorumPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage >= 0 && _percentage <= 100, "Quorum percentage must be between 0 and 100");
        quorumPercentage = _percentage;
    }

    function setMembershipFee(uint256 _fee) external onlyOwner {
        membershipFee = _fee;
    }

    function rescueERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        // In case of accidental ERC20 tokens sent to contract
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        uint256 transferAmount = Math.min(_amount, balance);
        token.transfer(owner(), transferAmount);
    }

    function rescueETH(uint256 _amount) external onlyOwner {
        // In case of accidental ETH sent to contract
        uint256 balance = address(this).balance;
        uint256 transferAmount = Math.min(_amount, balance);
        payable(owner()).transfer(transferAmount);
    }

    // Fallback function to reject direct ETH transfers (optional, but good practice for contracts not expecting direct payments)
    receive() external payable {
        revert("Direct ETH transfer not allowed. Use depositFunds function.");
    }
}

// --- Interface for ERC20 (for rescueERC20 function) ---
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    // ... other ERC20 functions if needed
}
```