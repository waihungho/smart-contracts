```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling artists to submit art,
 * community members to vote on art inclusion, curate exhibitions, and manage a collective treasury.
 *
 * **Outline:**
 * 1. **Core Art NFT Functionality:**
 *    - Minting Art NFTs by artists with metadata.
 *    - Viewing Art NFT details.
 *    - Transferring Art NFTs.
 * 2. **Art Submission and Voting System:**
 *    - Submitting art proposals with metadata.
 *    - Community voting on art proposals using governance tokens.
 *    - Determining voting results and adding approved art to the collective.
 * 3. **Exhibition Curation:**
 *    - Creating exhibitions by curators.
 *    - Adding and removing Art NFTs from exhibitions.
 *    - Viewing active and past exhibitions.
 * 4. **Governance and Community Management:**
 *    - Governance token distribution and management.
 *    - Proposing and voting on new rules or changes to the collective.
 *    - Staking governance tokens for voting power.
 * 5. **Artist and Curator Management:**
 *    - Registering as an artist.
 *    - Nominating and voting for curators.
 *    - Removing curators (governance vote).
 * 6. **Treasury Management:**
 *    - Receiving funds from NFT sales and other sources.
 *    - Proposals and voting for treasury spending.
 *    - Viewing treasury balance.
 * 7. **Community Features:**
 *    - Liking Art NFTs.
 *    - Commenting on Art NFTs (on-chain comments).
 *    - Featured Art of the Week (curator selection).
 * 8. **Utility and Admin Functions:**
 *    - Pausing and unpausing the contract (emergency).
 *    - Setting fees and parameters.
 *    - Emergency withdrawal function (multi-sig admin).
 *
 * **Function Summary:**
 * 1. `mintArtNFT(string memory _metadataURI)`: Allows registered artists to mint a new Art NFT.
 * 2. `getArtNFTDetails(uint256 _tokenId)`: Retrieves details of a specific Art NFT.
 * 3. `transferArtNFT(address _to, uint256 _tokenId)`: Allows Art NFT owners to transfer their NFTs.
 * 4. `submitArtProposal(string memory _metadataURI)`: Registered artists can submit art for community voting.
 * 5. `voteForArtInclusion(uint256 _proposalId, bool _vote)`: Governance token holders can vote on art proposals.
 * 6. `finalizeArtProposal(uint256 _proposalId)`: Finalizes an art proposal after voting period ends, adds approved art to collective.
 * 7. `createExhibition(string memory _exhibitionName)`: Curators can create a new exhibition.
 * 8. `addArtToExhibition(uint256 _exhibitionId, uint256 _artTokenId)`: Curators can add Art NFTs to an exhibition.
 * 9. `removeArtFromExhibition(uint256 _exhibitionId, uint256 _artTokenId)`: Curators can remove Art NFTs from an exhibition.
 * 10. `getActiveExhibitions()`: Returns a list of active exhibition IDs.
 * 11. `getExhibitionDetails(uint256 _exhibitionId)`: Retrieves details of a specific exhibition.
 * 12. `proposeNewRule(string memory _ruleDescription)`: Governance token holders can propose new rules for the collective.
 * 13. `voteOnRuleProposal(uint256 _proposalId, bool _vote)`: Governance token holders can vote on rule proposals.
 * 14. `executeRuleProposal(uint256 _proposalId)`: Executes a rule proposal if it passes the vote.
 * 15. `stakeGovernanceToken(uint256 _amount)`: Allows users to stake governance tokens to gain voting power.
 * 16. `unstakeGovernanceToken(uint256 _amount)`: Allows users to unstake governance tokens.
 * 17. `registerAsArtist()`: Allows users to register as artists within the collective.
 * 18. `nominateCurator(address _curatorAddress)`: Governance token holders can nominate addresses to be curators.
 * 19. `voteForCurator(uint256 _nominationId, bool _vote)`: Governance token holders can vote on curator nominations.
 * 20. `finalizeCuratorVote(uint256 _nominationId)`: Finalizes a curator nomination vote and appoints curators if approved.
 * 21. `removeCurator(address _curatorAddress)`: Allows governance to remove a curator through a vote.
 * 22. `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 * 23. `proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason)`: Governance token holders can propose treasury spending.
 * 24. `voteOnTreasurySpending(uint256 _proposalId, bool _vote)`: Governance token holders can vote on treasury spending proposals.
 * 25. `executeTreasurySpending(uint256 _proposalId)`: Executes a treasury spending proposal if it passes the vote.
 * 26. `likeArtNFT(uint256 _artTokenId)`: Allows users to "like" an Art NFT.
 * 27. `commentOnArtNFT(uint256 _artTokenId, string memory _comment)`: Allows users to leave on-chain comments on Art NFTs.
 * 28. `setFeaturedArtOfWeek(uint256 _artTokenId)`: Allows curators to set a featured Art NFT of the week.
 * 29. `getFeaturedArtOfWeek()`: Returns the currently featured Art NFT of the week.
 * 30. `pauseContract()`: Allows emergency admin to pause contract operations.
 * 31. `unpauseContract()`: Allows emergency admin to unpause contract operations.
 * 32. `setMintingFee(uint256 _fee)`: Allows contract owner to set the minting fee for Art NFTs.
 * 33. `setGovernanceTokenAddress(address _tokenAddress)`: Allows contract owner to set the governance token address.
 * 34. `emergencyWithdraw(address _recipient, uint256 _amount)`: Allows multi-sig emergency admins to withdraw funds in case of emergency.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Structs and Enums ---
    struct ArtNFT {
        uint256 tokenId;
        address artist;
        string metadataURI;
        uint256 likeCount;
        string[] comments;
    }

    struct ArtProposal {
        uint256 proposalId;
        address artist;
        string metadataURI;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool approved;
    }

    struct Exhibition {
        uint256 exhibitionId;
        string name;
        address curator;
        uint256[] artTokenIds;
        bool isActive;
    }

    struct RuleProposal {
        uint256 proposalId;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool approved;
    }

    struct TreasurySpendingProposal {
        uint256 proposalId;
        address recipient;
        uint256 amount;
        string reason;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool approved;
    }

    struct CuratorNomination {
        uint256 nominationId;
        address nominatedCurator;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool approved;
    }


    // --- State Variables ---
    Counters.Counter private _artNFTCounter;
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => address) public artNFTOwner; // Redundant but for clarity
    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private _artProposalCounter;
    uint256 public artProposalVotingDuration = 7 days; // Default voting duration for art proposals
    uint256 public ruleProposalVotingDuration = 14 days; // Default voting duration for rule proposals
    uint256 public treasurySpendingVotingDuration = 7 days; // Default voting duration for treasury spending proposals
    uint256 public curatorNominationVotingDuration = 7 days; // Default voting duration for curator nominations

    mapping(uint256 => Exhibition) public exhibitions;
    Counters.Counter private _exhibitionCounter;
    mapping(address => bool) public isCurator;
    mapping(address => bool) public isRegisteredArtist;
    address[] public curators;

    mapping(uint256 => RuleProposal) public ruleProposals;
    Counters.Counter private _ruleProposalCounter;

    mapping(uint256 => TreasurySpendingProposal) public treasurySpendingProposals;
    Counters.Counter private _treasurySpendingProposalCounter;

    mapping(uint256 => CuratorNomination) public curatorNominations;
    Counters.Counter private _curatorNominationCounter;

    IERC20 public governanceToken;
    uint256 public governanceTokenStakeRequiredForVote = 100; // Example value, adjust as needed
    mapping(address => uint256) public governanceTokenStakes;

    uint256 public mintingFee = 0.01 ether; // Default minting fee
    address[] public emergencyAdmins; // Multi-sig emergency admins
    bool public paused;
    uint256 public featuredArtOfWeekTokenId;

    // --- Events ---
    event ArtNFTMinted(uint256 tokenId, address artist, string metadataURI);
    event ArtProposalSubmitted(uint256 proposalId, address artist, string metadataURI);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint256 proposalId, bool approved);
    event ArtAddedToCollective(uint256 tokenId, address artist);
    event ExhibitionCreated(uint256 exhibitionId, string name, address curator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artTokenId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artTokenId);
    event RuleProposalCreated(uint256 proposalId, string description, address proposer);
    event RuleProposalVoted(uint256 proposalId, address voter, bool vote);
    event RuleProposalExecuted(uint256 proposalId, bool approved);
    event GovernanceTokenStaked(address staker, uint256 amount);
    event GovernanceTokenUnstaked(address unstaker, uint256 amount);
    event ArtistRegistered(address artist);
    event CuratorNominated(uint256 nominationId, address nominatedCurator, address nominator);
    event CuratorVoteCast(uint256 nominationId, address voter, bool vote);
    event CuratorNominationFinalized(uint256 nominationId, address nominatedCurator, bool approved);
    event CuratorAdded(address curator);
    event CuratorRemoved(address curator);
    event TreasurySpendingProposed(uint256 proposalId, address recipient, uint256 amount, string reason, address proposer);
    event TreasurySpendingVoted(uint256 proposalId, address voter, bool vote);
    event TreasurySpendingExecuted(uint256 proposalId, bool approved, address recipient, uint256 amount);
    event ArtNFTLiked(uint256 tokenId, address liker);
    event ArtNFTCommented(uint256 tokenId, uint256 commentIndex, address commenter, string comment);
    event FeaturedArtOfWeekSet(uint256 tokenId, address curator);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event MintingFeeSet(uint256 newFee, address setter);
    event GovernanceTokenAddressSet(address tokenAddress, address setter);
    event EmergencyWithdrawal(address recipient, uint256 amount, address withdrawer);


    // --- Modifiers ---
    modifier onlyRegisteredArtist() {
        require(isRegisteredArtist[msg.sender], "Not a registered artist");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Not a curator");
        _;
    }

    modifier onlyGovernanceTokenHolder() {
        require(governanceTokenStakes[msg.sender] >= governanceTokenStakeRequiredForVote, "Insufficient governance tokens staked to vote");
        _;
    }

    modifier onlyEmergencyAdmin() {
        bool isAdmin = false;
        for (uint256 i = 0; i < emergencyAdmins.length; i++) {
            if (emergencyAdmins[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "Not an emergency admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }


    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, address _governanceTokenAddress, address[] memory _initialEmergencyAdmins) ERC721(_name, _symbol) {
        governanceToken = IERC20(_governanceTokenAddress);
        emergencyAdmins = _initialEmergencyAdmins;
    }


    // --- Core Art NFT Functionality ---
    function mintArtNFT(string memory _metadataURI) external payable whenNotPaused onlyRegisteredArtist {
        require(msg.value >= mintingFee, "Insufficient minting fee");
        _artNFTCounter.increment();
        uint256 tokenId = _artNFTCounter.current();
        _safeMint(msg.sender, tokenId);
        artNFTs[tokenId] = ArtNFT(tokenId, msg.sender, _metadataURI, 0, new string[](0));
        artNFTOwner[tokenId] = msg.sender; // Explicitly set owner mapping
        emit ArtNFTMinted(tokenId, msg.sender, _metadataURI);

        // Optionally send minting fee to the treasury
        payable(address(this)).transfer(msg.value);
    }

    function getArtNFTDetails(uint256 _tokenId) external view returns (ArtNFT memory) {
        require(_exists(_tokenId), "Art NFT does not exist");
        return artNFTs[_tokenId];
    }

    function transferArtNFT(address _to, uint256 _tokenId) external whenNotPaused {
        safeTransferFrom(msg.sender, _to, _tokenId);
        artNFTOwner[_tokenId] = _to; // Update owner mapping
    }


    // --- Art Submission and Voting System ---
    function submitArtProposal(string memory _metadataURI) external whenNotPaused onlyRegisteredArtist {
        _artProposalCounter.increment();
        uint256 proposalId = _artProposalCounter.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            artist: msg.sender,
            metadataURI: _metadataURI,
            startTime: block.timestamp,
            endTime: block.timestamp + artProposalVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _metadataURI);
    }

    function voteForArtInclusion(uint256 _proposalId, bool _vote) external whenNotPaused onlyGovernanceTokenHolder {
        require(!artProposals[_proposalId].finalized, "Proposal already finalized");
        require(block.timestamp < artProposals[_proposalId].endTime, "Voting period ended");

        // Simple voting, each token holder can vote once (can be improved with voting power based on stake)
        // For simplicity, assuming each voter can vote only once, no double voting check for now.
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    function finalizeArtProposal(uint256 _proposalId) external whenNotPaused {
        require(!artProposals[_proposalId].finalized, "Proposal already finalized");
        require(block.timestamp >= artProposals[_proposalId].endTime, "Voting period not ended yet");

        artProposals[_proposalId].finalized = true;
        if (artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) {
            artProposals[_proposalId].approved = true;
            _addArtToCollective(artProposals[_proposalId].artist, artProposals[_proposalId].metadataURI);
            emit ArtProposalFinalized(_proposalId, true);
        } else {
            artProposals[_proposalId].approved = false;
            emit ArtProposalFinalized(_proposalId, false);
        }
    }

    function _addArtToCollective(address _artist, string memory _metadataURI) private {
        _artNFTCounter.increment();
        uint256 tokenId = _artNFTCounter.current();
        _safeMint(_artist, tokenId); // Mint to the artist who submitted it
        artNFTs[tokenId] = ArtNFT(tokenId, _artist, _metadataURI, 0, new string[](0));
        artNFTOwner[tokenId] = _artist;
        emit ArtAddedToCollective(tokenId, _artist);
    }


    // --- Exhibition Curation ---
    function createExhibition(string memory _exhibitionName) external whenNotPaused onlyCurator {
        _exhibitionCounter.increment();
        uint256 exhibitionId = _exhibitionCounter.current();
        exhibitions[exhibitionId] = Exhibition({
            exhibitionId: exhibitionId,
            name: _exhibitionName,
            curator: msg.sender,
            artTokenIds: new uint256[](0),
            isActive: true
        });
        emit ExhibitionCreated(exhibitionId, _exhibitionName, msg.sender);
    }

    function addArtToExhibition(uint256 _exhibitionId, uint256 _artTokenId) external whenNotPaused onlyCurator {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active");
        require(_exists(_artTokenId), "Art NFT does not exist");
        exhibitions[_exhibitionId].artTokenIds.push(_artTokenId);
        emit ArtAddedToExhibition(_exhibitionId, _artTokenId);
    }

    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artTokenId) external whenNotPaused onlyCurator {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active");
        uint256[] storage artIds = exhibitions[_exhibitionId].artTokenIds;
        for (uint256 i = 0; i < artIds.length; i++) {
            if (artIds[i] == _artTokenId) {
                delete artIds[i];
                // To maintain array integrity after delete, consider shifting elements or using a different data structure if order is important.
                // For simplicity, we are just deleting and leaving a 'hole'.
                emit ArtRemovedFromExhibition(_exhibitionId, _artTokenId);
                return;
            }
        }
        revert("Art NFT not found in exhibition");
    }

    function getActiveExhibitions() external view returns (uint256[] memory) {
        uint256[] memory activeExhibitionIds = new uint256[](_exhibitionCounter.current()); // Max size, might be less
        uint256 count = 0;
        for (uint256 i = 1; i <= _exhibitionCounter.current(); i++) {
            if (exhibitions[i].isActive) {
                activeExhibitionIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeExhibitionIds[i];
        }
        return result;
    }

    function getExhibitionDetails(uint256 _exhibitionId) external view returns (Exhibition memory) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active or does not exist");
        return exhibitions[_exhibitionId];
    }

    function endExhibition(uint256 _exhibitionId) external whenNotPaused onlyCurator {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only curator can end exhibition");
        exhibitions[_exhibitionId].isActive = false;
    }


    // --- Governance and Community Management ---
    function proposeNewRule(string memory _ruleDescription) external whenNotPaused onlyGovernanceTokenHolder {
        _ruleProposalCounter.increment();
        uint256 proposalId = _ruleProposalCounter.current();
        ruleProposals[proposalId] = RuleProposal({
            proposalId: proposalId,
            description: _ruleDescription,
            startTime: block.timestamp,
            endTime: block.timestamp + ruleProposalVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false
        });
        emit RuleProposalCreated(proposalId, _ruleDescription, msg.sender);
    }

    function voteOnRuleProposal(uint256 _proposalId, bool _vote) external whenNotPaused onlyGovernanceTokenHolder {
        require(!ruleProposals[_proposalId].finalized, "Rule proposal already finalized");
        require(block.timestamp < ruleProposals[_proposalId].endTime, "Voting period ended");

        if (_vote) {
            ruleProposals[_proposalId].yesVotes++;
        } else {
            ruleProposals[_proposalId].noVotes++;
        }
        emit RuleProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeRuleProposal(uint256 _proposalId) external whenNotPaused {
        require(!ruleProposals[_proposalId].finalized, "Rule proposal already finalized");
        require(block.timestamp >= ruleProposals[_proposalId].endTime, "Voting period not ended yet");

        ruleProposals[_proposalId].finalized = true;
        if (ruleProposals[_proposalId].yesVotes > ruleProposals[_proposalId].noVotes) {
            ruleProposals[_proposalId].approved = true;
            // Implement rule execution logic here based on ruleProposals[_proposalId].description
            // This is a placeholder, actual rule execution needs to be designed specifically.
            emit RuleProposalExecuted(_proposalId, true);
        } else {
            ruleProposals[_proposalId].approved = false;
            emit RuleProposalExecuted(_proposalId, false);
        }
    }

    function stakeGovernanceToken(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), "Governance token transfer failed");
        governanceTokenStakes[msg.sender] += _amount;
        emit GovernanceTokenStaked(msg.sender, _amount);
    }

    function unstakeGovernanceToken(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(governanceTokenStakes[msg.sender] >= _amount, "Insufficient staked tokens");
        require(governanceToken.transfer(msg.sender, _amount), "Governance token transfer back failed");
        governanceTokenStakes[msg.sender] -= _amount;
        emit GovernanceTokenUnstaked(msg.sender, _amount);
    }


    // --- Artist and Curator Management ---
    function registerAsArtist() external whenNotPaused {
        require(!isRegisteredArtist[msg.sender], "Already registered as artist");
        isRegisteredArtist[msg.sender] = true;
        emit ArtistRegistered(msg.sender);
    }

    function nominateCurator(address _curatorAddress) external whenNotPaused onlyGovernanceTokenHolder {
        require(!isCurator[_curatorAddress], "Address is already a curator");
        _curatorNominationCounter.increment();
        uint256 nominationId = _curatorNominationCounter.current();
        curatorNominations[nominationId] = CuratorNomination({
            nominationId: nominationId,
            nominatedCurator: _curatorAddress,
            startTime: block.timestamp,
            endTime: block.timestamp + curatorNominationVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false
        });
        emit CuratorNominated(nominationId, _curatorAddress, msg.sender);
    }

    function voteForCurator(uint256 _nominationId, bool _vote) external whenNotPaused onlyGovernanceTokenHolder {
        require(!curatorNominations[_nominationId].finalized, "Curator nomination already finalized");
        require(block.timestamp < curatorNominations[_nominationId].endTime, "Voting period ended");

        if (_vote) {
            curatorNominations[_nominationId].yesVotes++;
        } else {
            curatorNominations[_nominationId].noVotes++;
        }
        emit CuratorVoteCast(_nominationId, msg.sender, _vote);
    }

    function finalizeCuratorVote(uint256 _nominationId) external whenNotPaused {
        require(!curatorNominations[_nominationId].finalized, "Curator nomination already finalized");
        require(block.timestamp >= curatorNominations[_nominationId].endTime, "Voting period not ended yet");

        curatorNominations[_nominationId].finalized = true;
        if (curatorNominations[_nominationId].yesVotes > curatorNominations[_nominationId].noVotes) {
            curatorNominations[_nominationId].approved = true;
            _addCurator(curatorNominations[_nominationId].nominatedCurator);
            emit CuratorNominationFinalized(_nominationId, curatorNominations[_nominationId].nominatedCurator, true);
        } else {
            curatorNominations[_nominationId].approved = false;
            emit CuratorNominationFinalized(_nominationId, curatorNominations[_nominationId].nominatedCurator, false);
        }
    }

    function _addCurator(address _curatorAddress) private {
        isCurator[_curatorAddress] = true;
        curators.push(_curatorAddress);
        emit CuratorAdded(_curatorAddress);
    }

    function removeCurator(address _curatorAddress) external whenNotPaused onlyGovernanceTokenHolder {
        require(isCurator[_curatorAddress], "Address is not a curator");
        // For simplicity, direct removal, in a real DAO, you'd likely want a removal proposal and vote.
        isCurator[_curatorAddress] = false;
        // Remove from curators array (inefficient, but for example, in real use case, might use linked list or better data structure if curator list is frequently modified)
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _curatorAddress) {
                delete curators[i]; // Leave a hole, consider array compaction if necessary
                break;
            }
        }
        emit CuratorRemoved(_curatorAddress);
    }


    // --- Treasury Management ---
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) external whenNotPaused onlyGovernanceTokenHolder {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient treasury balance");

        _treasurySpendingProposalCounter.increment();
        uint256 proposalId = _treasurySpendingProposalCounter.current();
        treasurySpendingProposals[proposalId] = TreasurySpendingProposal({
            proposalId: proposalId,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            startTime: block.timestamp,
            endTime: block.timestamp + treasurySpendingVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false
        });
        emit TreasurySpendingProposed(proposalId, _recipient, _amount, _reason, msg.sender);
    }

    function voteOnTreasurySpending(uint256 _proposalId, bool _vote) external whenNotPaused onlyGovernanceTokenHolder {
        require(!treasurySpendingProposals[_proposalId].finalized, "Treasury spending proposal already finalized");
        require(block.timestamp < treasurySpendingProposals[_proposalId].endTime, "Voting period ended");

        if (_vote) {
            treasurySpendingProposals[_proposalId].yesVotes++;
        } else {
            treasurySpendingProposals[_proposalId].noVotes++;
        }
        emit TreasurySpendingVoted(_proposalId, msg.sender, _vote);
    }

    function executeTreasurySpending(uint256 _proposalId) external whenNotPaused {
        require(!treasurySpendingProposals[_proposalId].finalized, "Treasury spending proposal already finalized");
        require(block.timestamp >= treasurySpendingProposals[_proposalId].endTime, "Voting period not ended yet");

        treasurySpendingProposals[_proposalId].finalized = true;
        if (treasurySpendingProposals[_proposalId].yesVotes > treasurySpendingProposals[_proposalId].noVotes) {
            treasurySpendingProposals[_proposalId].approved = true;
            payable(treasurySpendingProposals[_proposalId].recipient).transfer(treasurySpendingProposals[_proposalId].amount);
            emit TreasurySpendingExecuted(_proposalId, true, treasurySpendingProposals[_proposalId].recipient, treasurySpendingProposals[_proposalId].amount);
        } else {
            treasurySpendingProposals[_proposalId].approved = false;
            emit TreasurySpendingExecuted(_proposalId, false, treasurySpendingProposals[_proposalId].recipient, treasurySpendingProposals[_proposalId].amount);
        }
    }


    // --- Community Features ---
    function likeArtNFT(uint256 _artTokenId) external whenNotPaused {
        require(_exists(_artTokenId), "Art NFT does not exist");
        artNFTs[_artTokenId].likeCount++;
        emit ArtNFTLiked(_artTokenId, msg.sender);
    }

    function commentOnArtNFT(uint256 _artTokenId, string memory _comment) external whenNotPaused {
        require(_exists(_artTokenId), "Art NFT does not exist");
        artNFTs[_artTokenId].comments.push(_comment);
        emit ArtNFTCommented(_artTokenId, artNFTs[_artTokenId].comments.length - 1, msg.sender, _comment);
    }

    function setFeaturedArtOfWeek(uint256 _artTokenId) external whenNotPaused onlyCurator {
        require(_exists(_artTokenId), "Art NFT does not exist");
        featuredArtOfWeekTokenId = _artTokenId;
        emit FeaturedArtOfWeekSet(_artTokenId, msg.sender);
    }

    function getFeaturedArtOfWeek() external view returns (uint256) {
        return featuredArtOfWeekTokenId;
    }


    // --- Utility and Admin Functions ---
    function pauseContract() external whenNotPaused onlyEmergencyAdmin {
        _pause();
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external whenPaused onlyEmergencyAdmin {
        _unpause();
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function setMintingFee(uint256 _fee) external onlyOwner {
        mintingFee = _fee;
        emit MintingFeeSet(_fee, msg.sender);
    }

    function setGovernanceTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        governanceToken = IERC20(_tokenAddress);
        emit GovernanceTokenAddressSet(_tokenAddress, msg.sender);
    }

    function emergencyWithdraw(address _recipient, uint256 _amount) external onlyEmergencyAdmin {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        payable(_recipient).transfer(_amount);
        emit EmergencyWithdrawal(_recipient, _amount, msg.sender);
    }

    // --- View Functions ---
    function getCurators() external view returns (address[] memory) {
        return curators;
    }

    function getArtProposals(uint256 _proposalId) external view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getRuleProposals(uint256 _proposalId) external view returns (RuleProposal memory) {
        return ruleProposals[_proposalId];
    }

    function getTreasurySpendingProposals(uint256 _proposalId) external view returns (TreasurySpendingProposal memory) {
        return treasurySpendingProposals[_proposalId];
    }

    function getCuratorNominations(uint256 _nominationId) external view returns (CuratorNomination memory) {
        return curatorNominations[_nominationId];
    }

    function getGovernanceTokenStake(address _account) external view returns (uint256) {
        return governanceTokenStakes[_account];
    }

    function getMintingFee() external view returns (uint256) {
        return mintingFee;
    }

    function getGovernanceTokenAddress() external view returns (address) {
        return address(governanceToken);
    }

    function getEmergencyAdmins() external view returns (address[] memory) {
        return emergencyAdmins;
    }

    function isContractPaused() external view returns (bool) {
        return paused;
    }
}
```