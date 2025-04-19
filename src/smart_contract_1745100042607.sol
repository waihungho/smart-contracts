```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling collaborative art creation, curation, and NFT management.
 *
 * **Outline:**
 *
 * **I. Membership & Governance:**
 *    1. `joinCollective()`: Allow users to join the art collective by staking governance tokens.
 *    2. `leaveCollective()`: Allow members to leave the collective and unstake their tokens.
 *    3. `delegateVote(address _delegate)`: Allow members to delegate their voting power to another address.
 *    4. `proposeParameterChange(string _parameterName, uint256 _newValue)`: Members propose changes to contract parameters.
 *    5. `voteOnParameterChange(uint256 _proposalId, bool _vote)`: Members vote on proposed parameter changes.
 *    6. `executeParameterChange(uint256 _proposalId)`: Executes a parameter change if approved by quorum.
 *
 * **II. Art Proposal & Creation:**
 *    7. `submitArtProposal(string _title, string _description, string _artStyle, string _requiredInputsDescription)`: Members propose new art projects.
 *    8. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members vote on submitted art proposals.
 *    9. `executeArtProposal(uint256 _proposalId)`: Executes an approved art proposal, moving it to the 'input contribution' stage.
 *    10. `contributeArtisticInput(uint256 _proposalId, string _inputData)`: Members contribute artistic inputs (prompts, seeds, etc.) to approved art proposals.
 *    11. `voteOnArtisticInputs(uint256 _proposalId, uint256 _inputIndex, bool _vote)`: Members vote on submitted artistic inputs for each proposal.
 *    12. `selectWinningInputs(uint256 _proposalId)`: After voting, select the winning artistic inputs based on quorum for art generation.
 *    13. `markArtGenerated(uint256 _proposalId, string _ipfsHash)`:  (Off-chain generation assumed) Mark an art proposal as generated and link to IPFS hash of the artwork.
 *
 * **III. NFT Management & Marketplace:**
 *    14. `mintArtNFT(uint256 _proposalId)`: Mint an NFT representing the generated artwork associated with a proposal.
 *    15. `setNFTPrice(uint256 _tokenId, uint256 _price)`: Set the sale price for an NFT minted by the collective.
 *    16. `buyArtNFT(uint256 _tokenId)`: Allow users to buy NFTs minted by the collective.
 *    17. `transferNFT(uint256 _tokenId, address _to)`: Allow the collective (governance) to transfer NFTs (e.g., for collaborations, giveaways).
 *    18. `burnNFT(uint256 _tokenId)`: Allow the collective (governance) to burn NFTs (e.g., if deemed inappropriate or failed generation).
 *
 * **IV. Treasury & Revenue Management:**
 *    19. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allow the collective (governance) to withdraw funds from the treasury.
 *    20. `setRoyaltyRecipient(address _recipient)`: Set the address to receive royalty payments on secondary sales of collective NFTs.
 *    21. `setRoyaltyPercentage(uint256 _percentage)`: Set the royalty percentage for secondary sales (e.g., 500 for 5%).
 *
 * **Function Summary:**
 * This contract facilitates a decentralized art collective where members govern art creation from proposal to NFT minting.
 * It includes membership management, proposal submission & voting, artistic input contribution & selection, NFT minting & marketplace features, and treasury management.
 * The contract assumes off-chain art generation based on selected inputs, and focuses on the on-chain governance and management of the art collective and its outputs.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedArtCollective is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _parameterProposalIdCounter;

    IERC20 public governanceToken; // Governance token for membership and voting
    uint256 public stakingAmount; // Amount of governance tokens required to join
    uint256 public votingQuorumPercentage = 50; // Percentage of members needed to vote for quorum
    uint256 public votingDurationBlocks = 100; // Number of blocks for voting periods
    uint256 public royaltyPercentage = 500; // Default royalty percentage (5% = 500)
    address public royaltyRecipient; // Default royalty recipient

    struct Member {
        address memberAddress;
        uint256 stakedTokens;
        address delegate;
    }

    struct ArtProposal {
        uint256 proposalId;
        string title;
        string description;
        string artStyle;
        string requiredInputsDescription;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool active;
        ProposalStage stage;
        mapping(address => bool) votes; // Members who voted
        ArtisticInput[] artisticInputs;
        string generatedArtIPFSHash;
        uint256 winningInputIndex; // Index of the winning artistic input after voting
    }

    struct ArtisticInput {
        address contributor;
        string inputData;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 startTime;
        uint256 endTime;
        bool active;
        mapping(address => bool) votes; // Members who voted
        bool selectedAsWinner;
    }

    struct ParameterProposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool active;
        mapping(address => bool) votes; // Members who voted
    }

    enum ProposalStage {
        PROPOSAL_SUBMITTED,
        VOTING_ON_PROPOSAL,
        INPUT_CONTRIBUTION,
        VOTING_ON_INPUTS,
        ART_GENERATION,
        NFT_MINTING,
        COMPLETED
    }

    mapping(address => Member) public members;
    address[] public memberList;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => ParameterProposal) public parameterProposals;
    mapping(uint256 => uint256) public nftPrices; // tokenId => price in wei
    mapping(uint256 => address) public nftOwners; // tokenId => owner (for marketplace tracking, even though ERC721 tracks ownership)

    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event VoteDelegated(address delegator, address delegate);
    event ParameterProposalSubmitted(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterVoteCast(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ArtProposalSubmitted(uint256 proposalId, string title, address proposer);
    event ArtProposalVoteCast(uint256 proposalId, address voter, bool vote);
    event ArtProposalExecuted(uint256 proposalId);
    event ArtisticInputSubmitted(uint256 proposalId, uint256 inputIndex, address contributor);
    event ArtisticInputVoteCast(uint256 proposalId, uint256 inputIndex, address voter, bool vote);
    event WinningInputsSelected(uint256 proposalId, uint256 winningInputIndex);
    event ArtGenerated(uint256 proposalId, string ipfsHash);
    event NFTMinted(uint256 tokenId, uint256 proposalId);
    event NFTPriceSet(uint256 tokenId, uint256 price);
    event NFTBought(uint256 tokenId, address buyer, uint256 price);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event RoyaltyRecipientSet(address recipient);
    event RoyaltyPercentageSet(uint256 percentage);

    constructor(string memory _name, string memory _symbol, address _governanceTokenAddress, uint256 _stakingAmount) ERC721(_name, _symbol) {
        governanceToken = IERC20(_governanceTokenAddress);
        stakingAmount = _stakingAmount;
        royaltyRecipient = msg.sender; // Default royalty recipient is contract deployer
    }

    modifier onlyMembers() {
        require(isMember(msg.sender), "Not a member of the collective");
        _;
    }

    modifier onlyParameterProposalActive(uint256 _proposalId) {
        require(parameterProposals[_proposalId].active, "Parameter proposal is not active");
        require(block.number <= parameterProposals[_proposalId].endTime, "Parameter proposal voting period ended");
        _;
    }

    modifier onlyArtProposalActive(uint256 _proposalId) {
        require(artProposals[_proposalId].active, "Art proposal is not active");
        require(block.number <= artProposals[_proposalId].endTime, "Art proposal voting period ended");
        _;
    }

    modifier onlyInputVotingActive(uint256 _proposalId, uint256 _inputIndex) {
        require(artProposals[_proposalId].stage == ProposalStage.VOTING_ON_INPUTS, "Proposal is not in input voting stage");
        require(artProposals[_proposalId].artisticInputs[_inputIndex].active, "Artistic input voting is not active");
        require(block.number <= artProposals[_proposalId].artisticInputs[_inputIndex].endTime, "Artistic input voting period ended");
        _;
    }


    function isMember(address _address) public view returns (bool) {
        return members[_address].memberAddress != address(0);
    }

    function getMemberCount() public view returns (uint256) {
        return memberList.length;
    }

    function getDelegatedVote(address _member) public view returns (address) {
        return members[_member].delegate;
    }

    function getVotingPower(address _voter) public view returns (uint256) {
        address delegate = members[_voter].delegate;
        if (delegate != address(0)) {
            return getVotingPower(delegate); // Recursive delegation check
        }
        return isMember(_voter) ? 1 : 0; // Simple voting power: 1 if member, 0 otherwise. Can be weighted by staked tokens if desired in a more advanced version.
    }


    // -------- I. Membership & Governance --------

    function joinCollective() external nonReentrant {
        require(!isMember(msg.sender), "Already a member");
        require(governanceToken.allowance(msg.sender, address(this)) >= stakingAmount, "Approve governance tokens first");
        require(governanceToken.transferFrom(msg.sender, address(this), stakingAmount), "Governance token transfer failed");

        members[msg.sender] = Member({
            memberAddress: msg.sender,
            stakedTokens: stakingAmount,
            delegate: address(0)
        });
        memberList.push(msg.sender);

        emit MemberJoined(msg.sender);
    }

    function leaveCollective() external nonReentrant {
        require(isMember(msg.sender), "Not a member");

        uint256 stakedAmount = members[msg.sender].stakedTokens;
        delete members[msg.sender];

        // Remove from memberList (inefficient for large lists, consider alternative in production)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        require(governanceToken.transfer(msg.sender, stakedAmount), "Governance token return failed");
        emit MemberLeft(msg.sender);
    }

    function delegateVote(address _delegate) external onlyMembers {
        members[msg.sender].delegate = _delegate;
        emit VoteDelegated(msg.sender, _delegate);
    }

    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyMembers {
        _parameterProposalIdCounter.increment();
        uint256 proposalId = _parameterProposalIdCounter.current();

        parameterProposals[proposalId] = ParameterProposal({
            proposalId: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            active: true,
            votes: mapping(address => bool)()
        });

        emit ParameterProposalSubmitted(proposalId, _parameterName, _newValue, msg.sender);
    }

    function voteOnParameterChange(uint256 _proposalId, bool _vote) external onlyMembers onlyParameterProposalActive(_proposalId) {
        require(!parameterProposals[_proposalId].votes[msg.sender], "Already voted on this proposal");
        parameterProposals[_proposalId].votes[msg.sender] = true;

        if (_vote) {
            parameterProposals[_proposalId].yesVotes += getVotingPower(msg.sender);
        } else {
            parameterProposals[_proposalId].noVotes += getVotingPower(msg.sender);
        }
        emit ParameterVoteCast(_proposalId, msg.sender, _vote);
    }

    function executeParameterChange(uint256 _proposalId) external onlyMembers onlyParameterProposalActive(_proposalId) {
        require(!parameterProposals[_proposalId].executed, "Parameter proposal already executed");
        require(block.number > parameterProposals[_proposalId].endTime, "Voting period not ended");

        uint256 totalMembers = memberList.length;
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;
        require(parameterProposals[_proposalId].yesVotes >= quorum, "Proposal does not meet quorum");
        require(parameterProposals[_proposalId].yesVotes > parameterProposals[_proposalId].noVotes, "Proposal not approved by majority");

        parameterProposals[_proposalId].executed = true;
        parameterProposals[_proposalId].active = false;

        string memory paramName = parameterProposals[_proposalId].parameterName;
        uint256 newValue = parameterProposals[_proposalId].newValue;

        if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("stakingAmount"))) {
            stakingAmount = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("votingQuorumPercentage"))) {
            votingQuorumPercentage = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("votingDurationBlocks"))) {
            votingDurationBlocks = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("royaltyPercentage"))) {
            royaltyPercentage = newValue;
        } else {
            revert("Invalid parameter name");
        }

        emit ParameterChangeExecuted(_proposalId, paramName, newValue);
    }

    // -------- II. Art Proposal & Creation --------

    function submitArtProposal(string memory _title, string memory _description, string memory _artStyle, string memory _requiredInputsDescription) external onlyMembers {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            title: _title,
            description: _description,
            artStyle: _artStyle,
            requiredInputsDescription: _requiredInputsDescription,
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            active: true,
            stage: ProposalStage.PROPOSAL_SUBMITTED,
            votes: mapping(address => bool)(),
            artisticInputs: new ArtisticInput[](0),
            generatedArtIPFSHash: "",
            winningInputIndex: 0
        });

        emit ArtProposalSubmitted(proposalId, _title, msg.sender);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMembers onlyArtProposalActive(_proposalId) {
        require(artProposals[_proposalId].stage == ProposalStage.PROPOSAL_SUBMITTED || artProposals[_proposalId].stage == ProposalStage.VOTING_ON_PROPOSAL, "Proposal not in voting stage");
        if(artProposals[_proposalId].stage == ProposalStage.PROPOSAL_SUBMITTED){
            artProposals[_proposalId].stage = ProposalStage.VOTING_ON_PROPOSAL; // Transition to voting stage only on the first vote
        }
        require(!artProposals[_proposalId].votes[msg.sender], "Already voted on this proposal");
        artProposals[_proposalId].votes[msg.sender] = true;

        if (_vote) {
            artProposals[_proposalId].yesVotes += getVotingPower(msg.sender);
        } else {
            artProposals[_proposalId].noVotes += getVotingPower(msg.sender);
        }
        emit ArtProposalVoteCast(_proposalId, msg.sender, _vote);
    }

    function executeArtProposal(uint256 _proposalId) external onlyMembers onlyArtProposalActive(_proposalId) {
        require(artProposals[_proposalId].stage == ProposalStage.VOTING_ON_PROPOSAL, "Proposal not in voting stage");
        require(!artProposals[_proposalId].executed, "Art proposal already executed");
        require(block.number > artProposals[_proposalId].endTime, "Voting period not ended");

        uint256 totalMembers = memberList.length;
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;
        require(artProposals[_proposalId].yesVotes >= quorum, "Proposal does not meet quorum");
        require(artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes, "Proposal not approved by majority");

        artProposals[_proposalId].executed = true;
        artProposals[_proposalId].active = false;
        artProposals[_proposalId].stage = ProposalStage.INPUT_CONTRIBUTION;

        emit ArtProposalExecuted(_proposalId);
    }

    function contributeArtisticInput(uint256 _proposalId, string memory _inputData) external onlyMembers {
        require(artProposals[_proposalId].stage == ProposalStage.INPUT_CONTRIBUTION, "Proposal not in input contribution stage");

        ArtisticInput memory newInput = ArtisticInput({
            contributor: msg.sender,
            inputData: _inputData,
            yesVotes: 0,
            noVotes: 0,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            active: true,
            votes: mapping(address => bool)(),
            selectedAsWinner: false
        });
        artProposals[_proposalId].artisticInputs.push(newInput);

        emit ArtisticInputSubmitted(_proposalId, artProposals[_proposalId].artisticInputs.length - 1, msg.sender);
    }

    function voteOnArtisticInputs(uint256 _proposalId, uint256 _inputIndex, bool _vote) external onlyMembers onlyInputVotingActive(_proposalId, _inputIndex) {
        require(artProposals[_proposalId].stage == ProposalStage.VOTING_ON_INPUTS || artProposals[_proposalId].stage == ProposalStage.INPUT_CONTRIBUTION, "Proposal not in input voting stage");
        if (artProposals[_proposalId].stage == ProposalStage.INPUT_CONTRIBUTION) {
            artProposals[_proposalId].stage = ProposalStage.VOTING_ON_INPUTS; // Transition to voting stage only on the first vote
        }
        require(!artProposals[_proposalId].artisticInputs[_inputIndex].votes[msg.sender], "Already voted on this input");
        artProposals[_proposalId].artisticInputs[_inputIndex].votes[msg.sender] = true;

        if (_vote) {
            artProposals[_proposalId].artisticInputs[_inputIndex].yesVotes += getVotingPower(msg.sender);
        } else {
            artProposals[_proposalId].artisticInputs[_inputIndex].noVotes += getVotingPower(msg.sender);
        }
        emit ArtisticInputVoteCast(_proposalId, _inputIndex, msg.sender, _vote);
    }

    function selectWinningInputs(uint256 _proposalId) external onlyMembers {
        require(artProposals[_proposalId].stage == ProposalStage.VOTING_ON_INPUTS, "Proposal not in input voting stage");
        require(block.number > artProposals[_proposalId].artisticInputs[0].endTime, "Input voting period not ended"); // Assuming all inputs have same end time for simplicity

        uint256 winningInputIndex = 0;
        uint256 maxVotes = 0;
        uint256 totalMembers = memberList.length;
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;

        for (uint256 i = 0; i < artProposals[_proposalId].artisticInputs.length; i++) {
            require(artProposals[_proposalId].artisticInputs[i].yesVotes >= quorum, "Input proposal does not meet quorum"); // Ensure quorum for each selected input
            if (artProposals[_proposalId].artisticInputs[i].yesVotes > maxVotes) {
                maxVotes = artProposals[_proposalId].artisticInputs[i].yesVotes;
                winningInputIndex = i;
            }
            artProposals[_proposalId].artisticInputs[i].active = false; // Deactivate input voting
        }

        artProposals[_proposalId].winningInputIndex = winningInputIndex;
        artProposals[_proposalId].stage = ProposalStage.ART_GENERATION;
        emit WinningInputsSelected(_proposalId, winningInputIndex);
    }

    function markArtGenerated(uint256 _proposalId, string memory _ipfsHash) external onlyMembers {
        require(artProposals[_proposalId].stage == ProposalStage.ART_GENERATION, "Proposal not in art generation stage");
        require(bytes(artProposals[_proposalId].generatedArtIPFSHash).length == 0, "Art already marked as generated"); // Prevent re-marking

        artProposals[_proposalId].generatedArtIPFSHash = _ipfsHash;
        artProposals[_proposalId].stage = ProposalStage.NFT_MINTING;
        emit ArtGenerated(_proposalId, _ipfsHash);
    }


    // -------- III. NFT Management & Marketplace --------

    function mintArtNFT(uint256 _proposalId) external onlyMembers {
        require(artProposals[_proposalId].stage == ProposalStage.NFT_MINTING, "Proposal not in NFT minting stage");
        require(bytes(artProposals[_proposalId].generatedArtIPFSHash).length > 0, "Art generation IPFS hash not set");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(address(this), tokenId); // Mint NFT to the contract itself initially, collective owns it
        nftOwners[tokenId] = address(this); // Track contract ownership
        artProposals[_proposalId].stage = ProposalStage.COMPLETED;

        _setTokenURI(tokenId, artProposals[_proposalId].generatedArtIPFSHash); // Set metadata URI to IPFS hash
        emit NFTMinted(tokenId, _proposalId);
    }

    function setNFTPrice(uint256 _tokenId, uint256 _price) external onlyMembers {
        require(ownerOf(_tokenId) == address(this), "Not collective owned NFT"); // Ensure collective owns the NFT
        nftPrices[_tokenId] = _price;
        emit NFTPriceSet(_tokenId, _price);
    }

    function buyArtNFT(uint256 _tokenId) external payable nonReentrant {
        require(ownerOf(_tokenId) == address(this), "Not collective owned NFT"); // Ensure collective owns the NFT
        require(nftPrices[_tokenId] > 0, "NFT price not set");
        require(msg.value >= nftPrices[_tokenId], "Insufficient payment");

        uint256 price = nftPrices[_tokenId];
        address currentOwner = address(this); // Collective address

        // Transfer NFT to buyer
        _transfer(currentOwner, msg.sender, _tokenId);
        nftOwners[_tokenId] = msg.sender; // Update marketplace tracking
        delete nftPrices[_tokenId]; // Remove price after sale

        // Transfer funds to contract treasury
        payable(owner()).transfer(msg.value); // Send funds to contract deployer (owner) as treasury for simplicity. In real DAO, treasury management would be more complex.

        emit NFTBought(_tokenId, msg.sender, price);
    }

    function transferNFT(uint256 _tokenId, address _to) external onlyMembers {
        require(ownerOf(_tokenId) == address(this), "Not collective owned NFT"); // Ensure collective owns the NFT
        address currentOwner = address(this); // Collective address
        _transfer(currentOwner, _to, _tokenId);
        nftOwners[_tokenId] = _to; // Update marketplace tracking
        delete nftPrices[_tokenId]; // Remove price if set

        emit NFTTransferred(_tokenId, currentOwner, _to);
    }

    function burnNFT(uint256 _tokenId) external onlyMembers {
        require(ownerOf(_tokenId) == address(this), "Not collective owned NFT"); // Ensure collective owns the NFT
        _burn(_tokenId);
        delete nftOwners[_tokenId]; // Clear marketplace tracking
        delete nftPrices[_tokenId]; // Remove price if set
        emit NFTBurned(_tokenId);
    }


    // -------- IV. Treasury & Revenue Management --------

    function withdrawTreasuryFunds(address payable _recipient, uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount); // Basic withdrawal to contract owner for simplicity. In real DAO, governance would control treasury.
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    function setRoyaltyRecipient(address _recipient) external onlyOwner {
        royaltyRecipient = _recipient;
        emit RoyaltyRecipientSet(_recipient);
    }

    function setRoyaltyPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 10000, "Royalty percentage too high (max 100%)"); // Max 100% royalty
        royaltyPercentage = _percentage;
        emit RoyaltyPercentageSet(_percentage);
    }

    // Override _transfer to implement royalty payment on secondary sales
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);

        if (from != address(0) && to != address(0) && from != address(this)) { // Secondary sale check (excluding mint and transfers from contract)
            uint256 salePrice; // Assume sale price retrieval from external marketplace or some agreed upon mechanism would be needed in real world.  Placeholder for now.
            // In a real implementation, you'd need to integrate with a marketplace or have a function to record sale price.
            // For this example, we'll assume 0 sale price for simplicity as we don't have a marketplace integration.

            uint256 royaltyAmount = (salePrice * royaltyPercentage) / 10000;
            if (royaltyAmount > 0) {
                payable(royaltyRecipient).transfer(royaltyAmount); // Send royalty to recipient
                // Remaining amount goes to the seller (or is already with them if sale price is handled externally)
            }
        }
    }

    // -------- Utility Functions --------

    function getArtProposalStage(uint256 _proposalId) public view returns (ProposalStage) {
        return artProposals[_proposalId].stage;
    }

    function getArtisticInputCount(uint256 _proposalId) public view returns (uint256) {
        return artProposals[_proposalId].artisticInputs.length;
    }

    function getArtisticInputDetails(uint256 _proposalId, uint256 _inputIndex) public view returns (string memory, address, uint256, uint256, uint256, uint256, bool) {
        ArtisticInput memory input = artProposals[_proposalId].artisticInputs[_inputIndex];
        return (
            input.inputData,
            input.contributor,
            input.yesVotes,
            input.noVotes,
            input.startTime,
            input.endTime,
            input.active
        );
    }

    function getParameterProposalDetails(uint256 _proposalId) public view returns (string memory, uint256, address, uint256, uint256, uint256, uint256, bool) {
        ParameterProposal memory proposal = parameterProposals[_proposalId];
        return (
            proposal.parameterName,
            proposal.newValue,
            proposal.proposer,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.active
        );
    }

    function getNFTPrice(uint256 _tokenId) public view returns (uint256) {
        return nftPrices[_tokenId];
    }

    function getNFTOwner(uint256 _tokenId) public view returns (address) {
        return nftOwners[_tokenId];
    }

    function getRoyaltyInfo() public view returns (address, uint256) {
        return (royaltyRecipient, royaltyPercentage);
    }

    receive() external payable {} // Allow contract to receive ETH

    fallback() external payable {} // Allow contract to receive ETH
}
```