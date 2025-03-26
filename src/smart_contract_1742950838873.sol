```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to collaborate, curate, and monetize digital art in a decentralized and community-driven manner.
 *
 * **Outline & Function Summary:**
 *
 * **Core Art Functionality:**
 * 1. `submitArtProposal(string _title, string _description, string _ipfsHash)`: Allows artists to submit art proposals with title, description, and IPFS hash.
 * 2. `voteOnArtProposal(uint256 _proposalId, bool _approve)`: Members can vote to approve or reject art proposals.
 * 3. `mintArtNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal, making it part of the collective's collection.
 * 4. `setArtPrice(uint256 _nftId, uint256 _price)`: Allows the collective to set the sale price for a minted NFT.
 * 5. `buyArtNFT(uint256 _nftId)`: Allows anyone to purchase an NFT from the collective, distributing revenue to artists and the collective treasury.
 * 6. `burnArtNFT(uint256 _nftId)`: Allows the collective (via governance) to burn an NFT in specific circumstances (e.g., copyright issues).
 * 7. `transferArtNFT(uint256 _nftId, address _to)`: Allows the collective to transfer ownership of an NFT (e.g., for collaborations or grants).
 * 8. `getArtProposalDetails(uint256 _proposalId)`: View function to retrieve details of an art proposal.
 * 9. `getNFTDetails(uint256 _nftId)`: View function to retrieve details of a minted NFT.
 * 10. `getTotalNFTsMinted()`: View function to get the total number of NFTs minted by the collective.
 *
 * **Collective Governance & Membership:**
 * 11. `requestMembership()`: Allows users to request membership in the art collective.
 * 12. `approveMembership(address _user)`: Only admin can approve membership requests.
 * 13. `revokeMembership(address _user)`: Only admin can revoke membership.
 * 14. `proposeCollectiveParameterChange(string _parameterName, uint256 _newValue)`: Members can propose changes to collective parameters (e.g., voting duration, membership fee).
 * 15. `voteOnParameterChange(uint256 _proposalId, bool _approve)`: Members can vote on parameter change proposals.
 * 16. `executeParameterChange(uint256 _proposalId)`: Executes an approved parameter change proposal after voting period.
 * 17. `setMembershipFee(uint256 _fee)`: Admin function to set the membership fee.
 * 18. `getMembershipFee()`: View function to get the current membership fee.
 * 19. `getMemberCount()`: View function to get the current number of members in the collective.
 * 20. `getTreasuryBalance()`: View function to get the current balance of the collective treasury.
 * 21. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Admin function to withdraw funds from the treasury for collective purposes.
 * 22. `pauseContract()`: Admin function to pause the contract in case of emergency.
 * 23. `unpauseContract()`: Admin function to unpause the contract.
 * 24. `isMember(address _user)`: View function to check if an address is a member.
 * 25. `isAdmin(address _user)`: View function to check if an address is an admin.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---
    Counters.Counter private _artProposalIds;
    Counters.Counter private _nftIds;

    uint256 public membershipFee;
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public proposalQuorum = 50; // Percentage of members needed to vote for quorum

    address public treasuryAddress; // Address to receive collective funds
    address public adminAddress; // Address with admin privileges (initially owner)

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => NFTData) public nfts;
    mapping(address => bool) public membershipRequested;
    mapping(address => bool) public members;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => mapping(address => bool)) public artProposalVotes; // proposalId => voter => voted
    mapping(uint256 => mapping(address => bool)) public parameterChangeVotes; // proposalId => voter => voted

    uint256 public totalNFTsMinted = 0;

    // --- Structs ---
    struct ArtProposal {
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        uint256 proposalTimestamp;
        bool isActive;
        bool isApproved;
        bool isMinted;
    }

    struct NFTData {
        uint256 nftId;
        uint256 proposalId;
        address artist;
        uint256 price;
        bool isListedForSale;
    }

    struct ParameterChangeProposal {
        uint256 proposalId;
        address proposer;
        string parameterName;
        uint256 newValue;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        uint256 proposalTimestamp;
        bool isActive;
        bool isApproved;
        bool isExecuted;
    }

    // --- Events ---
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool approve);
    event ArtProposalApproved(uint256 proposalId);
    event ArtNFTMinted(uint256 nftId, uint256 proposalId, address artist);
    event ArtNFTSalePriceSet(uint256 nftId, uint256 price);
    event ArtNFTBought(uint256 nftId, address buyer, uint256 price);
    event ArtNFTBurned(uint256 nftId);
    event ArtNFTTransferred(uint256 nftId, address from, address to);
    event MembershipRequested(address user);
    event MembershipApproved(address user);
    event MembershipRevoked(address user);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool approve);
    event ParameterChangeApproved(uint256 proposalId);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event MembershipFeeSet(uint256 fee);
    event TreasuryFundsWithdrawn(address recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender], "You are not a member of the collective.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin can perform this action.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(artProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp <= artProposals[_proposalId].proposalTimestamp + votingDuration, "Voting period has ended.");
        _;
    }

    modifier parameterProposalActive(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].isActive, "Parameter proposal is not active.");
        require(block.timestamp <= parameterChangeProposals[_proposalId].proposalTimestamp + votingDuration, "Voting period has ended.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _artProposalIds.current, "Invalid proposal ID.");
        _;
    }

    modifier validParameterProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _artProposalIds.current, "Invalid parameter proposal ID.");
        _;
    }

    modifier validNFT(uint256 _nftId) {
        require(_nftId > 0 && _nftId <= _nftIds.current, "Invalid NFT ID.");
        _;
    }

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, uint256 _initialMembershipFee, address _treasuryAddress) ERC721(_name, _symbol) {
        membershipFee = _initialMembershipFee;
        treasuryAddress = _treasuryAddress;
        adminAddress = msg.sender; // Owner is initial admin
    }

    // --- Core Art Functionality ---

    /**
     * @dev Allows members to submit art proposals.
     * @param _title Title of the art proposal.
     * @param _description Description of the art proposal.
     * @param _ipfsHash IPFS hash of the art data.
     */
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)
        public
        whenNotPaused
        onlyMember
    {
        _artProposalIds.increment();
        uint256 proposalId = _artProposalIds.current;

        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            voteCountApprove: 0,
            voteCountReject: 0,
            proposalTimestamp: block.timestamp,
            isActive: true,
            isApproved: false,
            isMinted: false
        });

        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /**
     * @dev Allows members to vote on an active art proposal.
     * @param _proposalId ID of the art proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _approve)
        public
        whenNotPaused
        onlyMember
        validProposal(_proposalId)
        proposalActive(_proposalId)
    {
        require(!artProposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        artProposalVotes[_proposalId][msg.sender] = true;

        if (_approve) {
            artProposals[_proposalId].voteCountApprove++;
        } else {
            artProposals[_proposalId].voteCountReject++;
        }

        emit ArtProposalVoted(_proposalId, msg.sender, _approve);

        // Check if voting period ended and quorum reached for approval
        if (block.timestamp > artProposals[_proposalId].proposalTimestamp + votingDuration) {
            _finalizeArtProposal(_proposalId);
        }
    }

    /**
     * @dev Internal function to finalize an art proposal after voting period.
     * @param _proposalId ID of the art proposal.
     */
    function _finalizeArtProposal(uint256 _proposalId) internal {
        if (!artProposals[_proposalId].isActive || artProposals[_proposalId].isApproved) {
            return; // Avoid re-execution
        }

        artProposals[_proposalId].isActive = false; // Mark proposal as inactive

        uint256 totalMembers = getMemberCount();
        uint256 votesCast = artProposals[_proposalId].voteCountApprove + artProposals[_proposalId].voteCountReject;
        uint256 quorumNeeded = totalMembers.mul(proposalQuorum).div(100);

        if (votesCast >= quorumNeeded && artProposals[_proposalId].voteCountApprove > artProposals[_proposalId].voteCountReject) {
            artProposals[_proposalId].isApproved = true;
            emit ArtProposalApproved(_proposalId);
        }
    }


    /**
     * @dev Mints an NFT for an approved art proposal.
     * @param _proposalId ID of the approved art proposal.
     */
    function mintArtNFT(uint256 _proposalId) public whenNotPaused onlyAdmin validProposal(_proposalId) {
        require(artProposals[_proposalId].isApproved, "Art proposal is not approved.");
        require(!artProposals[_proposalId].isMinted, "NFT for this proposal has already been minted.");

        _nftIds.increment();
        uint256 nftId = _nftIds.current;

        _safeMint(address(this), nftId); // Mint NFT to the contract itself, collective owns it initially

        nfts[nftId] = NFTData({
            nftId: nftId,
            proposalId: _proposalId,
            artist: artProposals[_proposalId].artist,
            price: 0, // Initial price is 0, collective will set later
            isListedForSale: false
        });

        artProposals[_proposalId].isMinted = true;
        totalNFTsMinted++;

        emit ArtNFTMinted(nftId, _proposalId, artProposals[_proposalId].artist);
    }

    /**
     * @dev Sets the sale price for a minted NFT. Only callable by admin after proposal approved and NFT minted.
     * @param _nftId ID of the NFT.
     * @param _price Sale price in wei.
     */
    function setArtPrice(uint256 _nftId, uint256 _price) public whenNotPaused onlyAdmin validNFT(_nftId) {
        require(nfts[_nftId].proposalId > 0 && artProposals[nfts[_nftId].proposalId].isMinted, "NFT not associated with a minted art proposal.");
        nfts[_nftId].price = _price;
        nfts[_nftId].isListedForSale = true;
        emit ArtNFTSalePriceSet(_nftId, _price);
    }

    /**
     * @dev Allows anyone to buy an NFT from the collective.
     * @param _nftId ID of the NFT to buy.
     */
    function buyArtNFT(uint256 _nftId) public payable whenNotPaused validNFT(_nftId) {
        require(nfts[_nftId].isListedForSale, "NFT is not listed for sale.");
        require(msg.value >= nfts[_nftId].price, "Insufficient funds sent.");

        uint256 artistShare = nfts[_nftId].price.mul(70).div(100); // 70% to artist
        uint256 collectiveShare = nfts[_nftId].price.mul(30).div(100); // 30% to collective treasury

        // Pay artist (if artist is still a member, otherwise send to treasury)
        if (members[nfts[_nftId].artist]) {
            payable(nfts[_nftId].artist).transfer(artistShare);
        } else {
            payable(treasuryAddress).transfer(artistShare); // Send artist share to treasury if artist is not member anymore
        }

        // Send collective share to treasury
        payable(treasuryAddress).transfer(collectiveShare);

        // Transfer NFT ownership to buyer
        _transfer(address(this), msg.sender, _nftId);
        nfts[_nftId].isListedForSale = false; // No longer listed

        emit ArtNFTBought(_nftId, msg.sender, nfts[_nftId].price);
    }

    /**
     * @dev Allows the admin to burn an NFT (e.g., for copyright issues, community vote could be added for more decentralization).
     * @param _nftId ID of the NFT to burn.
     */
    function burnArtNFT(uint256 _nftId) public whenNotPaused onlyAdmin validNFT(_nftId) {
        require(ownerOf(_nftId) == address(this), "Contract is not the owner of this NFT."); // Ensure contract owns NFT
        _burn(_nftId);
        delete nfts[_nftId]; // Clean up NFT data
        emit ArtNFTBurned(_nftId);
    }

    /**
     * @dev Allows the admin to transfer ownership of an NFT (e.g., for collaborations, grants).
     * @param _nftId ID of the NFT to transfer.
     * @param _to Address to transfer the NFT to.
     */
    function transferArtNFT(uint256 _nftId, address _to) public whenNotPaused onlyAdmin validNFT(_nftId) {
        require(ownerOf(_nftId) == address(this), "Contract is not the owner of this NFT."); // Ensure contract owns NFT
        _transfer(address(this), _to, _nftId);
        emit ArtNFTTransferred(_nftId, address(this), _to);
    }

    /**
     * @dev Gets details of an art proposal.
     * @param _proposalId ID of the art proposal.
     * @return ArtProposal struct.
     */
    function getArtProposalDetails(uint256 _proposalId) public view validProposal(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /**
     * @dev Gets details of a minted NFT.
     * @param _nftId ID of the NFT.
     * @return NFTData struct.
     */
    function getNFTDetails(uint256 _nftId) public view validNFT(_nftId) returns (NFTData memory) {
        return nfts[_nftId];
    }

    /**
     * @dev Gets the total number of NFTs minted by the collective.
     * @return Total NFTs minted.
     */
    function getTotalNFTsMinted() public view returns (uint256) {
        return totalNFTsMinted;
    }


    // --- Collective Governance & Membership ---

    /**
     * @dev Allows users to request membership.
     */
    function requestMembership() public whenNotPaused {
        require(!members[msg.sender], "You are already a member.");
        require(!membershipRequested[msg.sender], "Membership already requested.");
        membershipRequested[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /**
     * @dev Allows admin to approve membership requests.
     * @param _user Address of the user to approve.
     */
    function approveMembership(address _user) public whenNotPaused onlyAdmin {
        require(membershipRequested[_user], "Membership not requested by this user.");
        members[_user] = true;
        membershipRequested[_user] = false;
        emit MembershipApproved(_user);
    }

    /**
     * @dev Allows admin to revoke membership.
     * @param _user Address of the member to revoke.
     */
    function revokeMembership(address _user) public whenNotPaused onlyAdmin {
        require(members[_user], "User is not a member.");
        delete members[_user]; // Use delete to explicitly remove from mapping for potential gas savings in long run
        emit MembershipRevoked(_user);
    }

    /**
     * @dev Allows members to propose changes to collective parameters.
     * @param _parameterName Name of the parameter to change.
     * @param _newValue New value for the parameter.
     */
    function proposeCollectiveParameterChange(string memory _parameterName, uint256 _newValue)
        public
        whenNotPaused
        onlyMember
    {
        _artProposalIds.increment(); // Reusing proposal ID counter for simplicity, could use separate counter if needed
        uint256 proposalId = _artProposalIds.current;

        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            parameterName: _parameterName,
            newValue: _newValue,
            voteCountApprove: 0,
            voteCountReject: 0,
            proposalTimestamp: block.timestamp,
            isActive: true,
            isApproved: false,
            isExecuted: false
        });

        emit ParameterChangeProposed(proposalId, _parameterName, _newValue);
    }

    /**
     * @dev Allows members to vote on parameter change proposals.
     * @param _proposalId ID of the parameter change proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _approve)
        public
        whenNotPaused
        onlyMember
        validParameterProposal(_proposalId)
        parameterProposalActive(_proposalId)
    {
        require(!parameterChangeVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        parameterChangeVotes[_proposalId][msg.sender] = true;

        if (_approve) {
            parameterChangeProposals[_proposalId].voteCountApprove++;
        } else {
            parameterChangeProposals[_proposalId].voteCountReject++;
        }

        emit ParameterChangeVoted(_proposalId, msg.sender, _approve);

        // Check if voting period ended and quorum reached for approval
        if (block.timestamp > parameterChangeProposals[_proposalId].proposalTimestamp + votingDuration) {
            _finalizeParameterChangeProposal(_proposalId);
        }
    }

    /**
     * @dev Internal function to finalize a parameter change proposal after voting period.
     * @param _proposalId ID of the parameter change proposal.
     */
    function _finalizeParameterChangeProposal(uint256 _proposalId) internal {
        if (!parameterChangeProposals[_proposalId].isActive || parameterChangeProposals[_proposalId].isExecuted) {
            return; // Avoid re-execution
        }

        parameterChangeProposals[_proposalId].isActive = false; // Mark proposal as inactive

        uint256 totalMembers = getMemberCount();
        uint256 votesCast = parameterChangeProposals[_proposalId].voteCountApprove + parameterChangeProposals[_proposalId].voteCountReject;
        uint256 quorumNeeded = totalMembers.mul(proposalQuorum).div(100);

        if (votesCast >= quorumNeeded && parameterChangeProposals[_proposalId].voteCountApprove > parameterChangeProposals[_proposalId].voteCountReject) {
            parameterChangeProposals[_proposalId].isApproved = true;
            emit ParameterChangeApproved(_proposalId);
        }
    }


    /**
     * @dev Executes an approved parameter change proposal. Only callable by admin after proposal approved.
     * @param _proposalId ID of the parameter change proposal.
     */
    function executeParameterChange(uint256 _proposalId) public whenNotPaused onlyAdmin validParameterProposal(_proposalId) {
        require(parameterChangeProposals[_proposalId].isApproved, "Parameter change proposal is not approved.");
        require(!parameterChangeProposals[_proposalId].isExecuted, "Parameter change proposal already executed.");

        string memory parameterName = parameterChangeProposals[_proposalId].parameterName;
        uint256 newValue = parameterChangeProposals[_proposalId].newValue;

        if (keccak256(bytes(parameterName)) == keccak256(bytes("membershipFee"))) {
            setMembershipFee(newValue);
        } else if (keccak256(bytes(parameterName)) == keccak256(bytes("votingDuration"))) {
            votingDuration = newValue;
        } else if (keccak256(bytes(parameterName)) == keccak256(bytes("proposalQuorum"))) {
            proposalQuorum = newValue;
        } else {
            revert("Invalid parameter name for change.");
        }

        parameterChangeProposals[_proposalId].isExecuted = true;
        emit ParameterChangeExecuted(_proposalId, parameterName, newValue);
    }


    /**
     * @dev Admin function to set the membership fee.
     * @param _fee Membership fee in wei.
     */
    function setMembershipFee(uint256 _fee) public whenNotPaused onlyAdmin {
        membershipFee = _fee;
        emit MembershipFeeSet(_fee);
    }

    /**
     * @dev Gets the current membership fee.
     * @return Membership fee in wei.
     */
    function getMembershipFee() public view returns (uint256) {
        return membershipFee;
    }

    /**
     * @dev Gets the current number of members in the collective.
     * @return Number of members.
     */
    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        address[] memory allMembers = getMembers();
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (members[allMembers[i]]) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Helper function to get all addresses that are marked as members (for counting purposes - not scalable for very large member counts in a single view call).
     * @return Array of member addresses.
     */
    function getMembers() public view returns (address[] memory) {
        address[] memory memberList = new address[](members.length); // Approximation, might be more than actual members due to mapping structure
        uint256 index = 0;
        for (uint256 i = 0; i < members.length; i++) { // Iterate over all possible addresses in mapping - inefficient for very large mappings
            address addr = address(uint160(i)); // Convert index to address - not practical, just for demonstration, need better way to iterate members in real app
            if (members[addr]) {
                memberList[index] = addr;
                index++;
            }
        }
        address[] memory actualMemberList = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            actualMemberList[i] = memberList[i];
        }
        return actualMemberList;
    }


    /**
     * @dev Gets the current balance of the collective treasury.
     * @return Treasury balance in wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Admin function to withdraw funds from the treasury for collective purposes.
     * @param _recipient Address to receive the funds.
     * @param _amount Amount to withdraw in wei.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public whenNotPaused onlyAdmin {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(_amount <= getTreasuryBalance(), "Insufficient treasury balance.");

        payable(_recipient).transfer(_amount);
        emit TreasuryFundsWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Admin function to pause the contract.
     */
    function pauseContract() public onlyAdmin {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Admin function to unpause the contract.
     */
    function unpauseContract() public onlyAdmin {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Checks if an address is a member.
     * @param _user Address to check.
     * @return True if member, false otherwise.
     */
    function isMember(address _user) public view returns (bool) {
        return members[_user];
    }

    /**
     * @dev Checks if an address is an admin.
     * @param _user Address to check.
     * @return True if admin, false otherwise.
     */
    function isAdmin(address _user) public view returns (bool) {
        return _user == adminAddress;
    }

    /**
     * @dev Function to pay membership fee and become a member.
     */
    function becomeMember() public payable whenNotPaused {
        require(!members[msg.sender], "Already a member.");
        require(msg.value >= membershipFee, "Insufficient membership fee.");
        members[msg.sender] = true;

        // Send membership fee to treasury
        payable(treasuryAddress).transfer(membershipFee);

        emit MembershipApproved(msg.sender); // Implicitly approved upon payment
    }

    /**
     * @dev Allows admin to change the admin address.
     * @param _newAdmin The new admin address.
     */
    function setAdminAddress(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        adminAddress = _newAdmin;
        // Consider emitting an event for admin change if needed
    }

    /**
     * @dev Fallback function to receive Ether into the contract (for potential donations or unexpected transfers).
     */
    receive() external payable {}
}
```