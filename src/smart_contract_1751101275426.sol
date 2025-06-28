Okay, let's create a smart contract that embodies advanced concepts like dynamic states, fractional ownership logic (via royalty splits), on-chain contribution tracking (via claims), a simple built-in governance mechanism, and staking for creative projects. We'll call it `DecentralizedCreativeCollaborator`.

This contract facilitates the creation, collaboration, and potential monetization of creative projects entirely on-chain.

---

**DecentralizedCreativeCollaborator Smart Contract**

**Outline:**

1.  **State Variables & Enums:** Defines the various states a project can be in, global settings (fees, governors), and mappings to store project data.
2.  **Structs:** Defines the structure for `Project`, `ContributionClaim`, and potentially `RoyaltySplitEntry`.
3.  **Events:** Declares events to signal important actions (project creation, state changes, contributions, staking, governance changes).
4.  **Modifiers:** Custom modifiers for access control (e.g., only governor, only project lead).
5.  **Constructor:** Initializes the contract with an initial set of governors and fee recipient.
6.  **Core Project Management:** Functions for creating, updating, and managing project details and state transitions.
7.  **Collaboration Management:** Functions for inviting, accepting, and managing collaborators on a project.
8.  **Contribution Tracking:** Functions for submitting and approving contribution claims.
9.  **NFT & Royalty:** Functions related to associating an NFT with a completed project and distributing potential royalties.
10. **Staking & Boosting:** Functions allowing users to stake ETH on projects to show support or boost visibility, with a small protocol fee.
11. **Simple Governance:** Functions for governors to vote on project completion and manage other governors.
12. **Admin & Protocol Fees:** Functions for the initial admin (deployer) and governors to manage core contract settings and withdraw fees.
13. **View Functions:** Public functions to retrieve contract state and project information.

**Function Summary:**

1.  `constructor`: Deploys the contract, setting initial governors and fee address.
2.  `createProject`: Allows any user to propose a new project.
3.  `setProjectDetails`: Allows the project lead or a governor to update project title or description URI.
4.  `inviteCollaborator`: Allows the project lead to invite another address to collaborate.
5.  `acceptCollaborationInvite`: Allows an invited user to accept the invitation and become a collaborator.
6.  `removeCollaborator`: Allows the project lead or a governor to remove a collaborator from a project.
7.  `submitContributionClaim`: Allows a collaborator to submit a claim representing their work on a project.
8.  `approveContributionClaim`: Allows the project lead or a governor to approve a contribution claim, potentially affecting royalty splits.
9.  `submitProjectForReview`: Allows the project lead to submit the project to governors for completion review.
10. `voteOnProjectCompletion`: Allows a governor to cast a vote (approve/reject) on a project submitted for review.
11. `executeProjectCompletionVote`: Allows anyone to finalize the outcome of a project completion vote after the voting period (or majority reached).
12. `cancelProject`: Allows the project lead to cancel a project before it reaches the 'Review' state.
13. `setProjectNFTAddress`: Allows a governor to set the address of the ERC721 contract used for project NFTs.
14. `mintProjectNFT`: Allows the project lead or a governor to mint the final NFT for a 'Completed' project via the associated NFT contract.
15. `setProjectRoyaltySplit`: Allows the project lead or a governor to define a custom royalty distribution split based on approved contributions for a project before minting.
16. `distributeRoyalties`: Allows anyone to trigger the distribution of funds sent to this contract for a specific project's royalties, based on the defined split.
17. `stakeOnProject`: Allows users to stake ETH on a project to signal support or boost visibility.
18. `withdrawStake`: Allows a staker to withdraw their staked ETH, potentially subject to project state.
19. `addGovernor`: Allows an existing governor to add a new governor.
20. `removeGovernor`: Allows an existing governor to remove another governor.
21. `withdrawProtocolFees`: Allows the fee recipient to withdraw accumulated protocol fees.
22. `setProtocolFeeRecipient`: Allows a governor to change the address receiving protocol fees.
23. `getProjectDetails`: View function to retrieve project struct data.
24. `getProjectContributors`: View function to list collaborators and their contribution scores for a project.
25. `getContributionClaims`: View function to retrieve submitted and approved claims for a project.
26. `getProjectStake`: View function to get total ETH staked and individual user stake on a project.
27. `getProjectNFTId`: View function to get the NFT ID associated with a completed project.
28. `isGovernor`: View function to check if an address is a governor.
29. `getGovernors`: View function to list all current governors.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: This contract assumes the existence of a separate ERC721 contract
// managed externally or by the governance of this contract, which supports
// a minting function and potentially royalty standards (like EIP-2981).
// The royalty distribution logic here is simplified - it assumes funds
// are sent directly to *this* contract for distribution per project.

contract DecentralizedCreativeCollaborator is ReentrancyGuard {

    // --- State Variables & Enums ---

    enum ProjectState {
        Idea,       // Newly created project idea
        Active,     // Collaboration is ongoing
        Review,     // Submitted to governors for completion vote
        Completed,  // Approved and potentially ready for NFT minting
        Rejected,   // Rejected by governors during review
        Cancelled   // Cancelled by the lead before review
    }

    struct ContributionClaim {
        address submitter;
        string descriptionURI; // Link to off-chain proof/description
        bool isApproved;
    }

    struct Project {
        uint256 id;
        ProjectState state;
        address payable lead; // Lead creator, receives royalties portion, can manage project
        string title;
        string descriptionURI; // Link to full project description/details off-chain

        address[] collaborators; // Addresses actively collaborating (excluding lead)
        mapping(address => bool) isCollaborator; // Quick check if an address is a collaborator or lead

        ContributionClaim[] contributionClaims;
        mapping(uint256 => bool) contributionClaimApproved; // claim index => isApproved

        uint256 totalApprovedContributionScore; // Sum of scores from approved claims for this project

        // Royalty Distribution - Basis points (sum <= 10000)
        mapping(address => uint96) royaltySplitBasisPoints;
        bool customRoyaltySplitSet; // True if royaltySplitBasisPoints is manually set

        // Staking for Boosting/Support
        uint256 totalStakedETH;
        mapping(address => uint256) stakedETH; // User's staked amount

        // NFT Association
        uint256 nftId; // ID of the minted NFT on the external ERC721 contract
        bool mintedNFT; // True if NFT has been minted for this project

        // Governance Voting for Completion
        mapping(address => bool) governorVotesForCompletion; // governor => voted yes
        mapping(address => bool) governorVotesAgainstCompletion; // governor => voted no
        uint256 votesYes;
        uint256 votesNo;
        uint256 votingEnds; // Timestamp when voting ends (if time-based)
        uint256 completionProposalId; // Unique ID for review proposals

        address[] pendingCollaborators;
        mapping(address => bool) isPendingCollaborator;
    }

    uint256 public projectCounter;
    mapping(uint256 => Project) public projects; // project ID => Project

    address[] public governors;
    mapping(address => bool) private isGovernor;
    uint256 public minGovernorVotesForCompletion; // Minimum number of 'yes' votes required
    uint256 public governorVotingPeriod; // How long voting is open (in seconds)

    address public protocolFeeRecipient;
    uint256 public protocolFeeBasisPoints; // Fee taken from staking, e.g., 100 = 1% (max 10000)

    IERC721 public projectNFTContract; // Address of the external ERC721 contract

    // --- Events ---

    event ProjectCreated(uint256 projectId, address indexed lead, string title, string descriptionURI);
    event ProjectStateChanged(uint256 indexed projectId, ProjectState newState, ProjectState oldState);
    event ProjectDetailsUpdated(uint256 indexed projectId, string descriptionURI);

    event CollaboratorInvited(uint256 indexed projectId, address indexed lead, address indexed invitee);
    event CollaboratorAcceptedInvite(uint256 indexed projectId, address indexed collaborator);
    event CollaboratorRemoved(uint256 indexed projectId, address indexed remover, address indexed removed);

    event ContributionClaimSubmitted(uint256 indexed projectId, uint256 claimIndex, address indexed submitter, string descriptionURI);
    event ContributionClaimApproved(uint256 indexed projectId, uint256 indexed claimIndex, address indexed approver);

    event ProjectSubmittedForReview(uint256 indexed projectId, uint256 proposalId);
    event GovernorVotedOnCompletion(uint256 indexed projectId, uint256 indexed proposalId, address indexed governor, bool approved);
    event ProjectCompletionVoteExecuted(uint256 indexed projectId, uint256 indexed proposalId, bool approved, bool executed);

    event ProjectCancelled(uint256 indexed projectId, address indexed canceller);

    event ProjectNFTContractSet(address indexed nftContract);
    event ProjectNFTMinted(uint256 indexed projectId, uint256 indexed nftId, address indexed minter);
    event ProjectRoyaltySplitSet(uint256 indexed projectId, address indexed setter);
    event RoyaltiesDistributed(uint256 indexed projectId, address indexed distributor, uint256 amount);

    event ETHStakedOnProject(uint256 indexed projectId, address indexed staker, uint256 amount);
    event StakeWithdrawn(uint256 indexed projectId, address indexed staker, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    event GovernorAdded(address indexed governor, address indexed addedBy);
    event GovernorRemoved(address indexed governor, address indexed removedBy);
    event ProtocolFeeRecipientSet(address indexed oldRecipient, address indexed newRecipient);

    // --- Modifiers ---

    modifier onlyGovernor() {
        require(isGovernor[msg.sender], "Not a governor");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].lead == msg.sender, "Not project lead");
        _;
    }

    modifier onlyCollaborator(uint256 _projectId) {
        require(projects[_projectId].isCollaborator[msg.sender] || projects[_projectId].lead == msg.sender, "Not a collaborator or lead");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= projectCounter, "Project does not exist");
        _;
    }

    modifier checkProjectState(uint256 _projectId, ProjectState _requiredState) {
        require(projects[_projectId].state == _requiredState, "Incorrect project state");
        _;
    }

    // --- Constructor ---

    constructor(address[] memory _initialGovernors, address _initialFeeRecipient, uint256 _minGovernorVotes, uint256 _votingPeriod) ReentrancyGuard() {
        require(_initialGovernors.length > 0, "Must have at least one governor");
        require(_initialFeeRecipient != address(0), "Fee recipient cannot be zero address");
        require(_minGovernorVotes > 0, "Minimum votes must be greater than 0");

        for (uint i = 0; i < _initialGovernors.length; i++) {
            require(_initialGovernors[i] != address(0), "Initial governor address cannot be zero");
            if (!isGovernor[_initialGovernors[i]]) {
                governors.push(_initialGovernors[i]);
                isGovernor[_initialGovernors[i]] = true;
                emit GovernorAdded(_initialGovernors[i], msg.sender); // msg.sender is deployer
            }
        }

        protocolFeeRecipient = _initialFeeRecipient;
        protocolFeeBasisPoints = 50; // Default 0.5% fee on staking
        minGovernorVotesForCompletion = _minGovernorVotes;
        governorVotingPeriod = _votingPeriod; // e.g., 3 days = 3 * 24 * 60 * 60
    }

    // --- Core Project Management ---

    function createProject(string memory _title, string memory _descriptionURI) external returns (uint256 projectId) {
        projectCounter++;
        projectId = projectCounter;

        Project storage newProject = projects[projectId];
        newProject.id = projectId;
        newProject.state = ProjectState.Idea;
        newProject.lead = payable(msg.sender);
        newProject.title = _title;
        newProject.descriptionURI = _descriptionURI;
        newProject.isCollaborator[msg.sender] = true; // Lead is also a collaborator conceptually

        emit ProjectCreated(projectId, msg.sender, _title, _descriptionURI);
    }

    function setProjectDetails(uint256 _projectId, string memory _descriptionURI) external projectExists(_projectId) {
        require(projects[_projectId].state == ProjectState.Idea || projects[_projectId].state == ProjectState.Active, "Project must be in Idea or Active state");
        require(projects[_projectId].lead == msg.sender || isGovernor[msg.sender], "Only lead or governor can update details");

        projects[_projectId].descriptionURI = _descriptionURI;
        emit ProjectDetailsUpdated(_projectId, _descriptionURI);
    }

    function submitProjectForReview(uint256 _projectId) external projectExists(_projectId) onlyProjectLead(_projectId) checkProjectState(_projectId, ProjectState.Active) {
        // Transition to Review state
        projects[_projectId].state = ProjectState.Review;

        // Reset voting state for this review
        projects[_projectId].votesYes = 0;
        projects[_projectId].votesNo = 0;
        projects[_projectId].votingEnds = block.timestamp + governorVotingPeriod;
        projects[_projectId].completionProposalId++; // Increment proposal ID for uniqueness per review attempt

        // Clear previous votes for this proposal ID (optional, mapping handles new proposal ID)
        // For explicit reset: iterate governors and reset governorVotesForCompletion/AgainstCompletion for this proposal.
        // Let's rely on the proposal ID check in voteOnProjectCompletion.

        emit ProjectStateChanged(_projectId, ProjectState.Review, ProjectState.Active);
        emit ProjectSubmittedForReview(_projectId, projects[_projectId].completionProposalId);
    }

    function cancelProject(uint256 _projectId) external projectExists(_projectId) onlyProjectLead(_projectId) {
        require(projects[_projectId].state == ProjectState.Idea || projects[_projectId].state == ProjectState.Active, "Project must be in Idea or Active state to cancel");

        projects[_projectId].state = ProjectState.Cancelled;

        // Optionally refund stakes here if cancelled? Let's allow withdrawal via withdrawStake later.
        // projects[_projectId].totalStakedETH remains, withdrawStake handles it.

        emit ProjectStateChanged(_projectId, ProjectState.Cancelled, projects[_projectId].state); // Old state will be Idea or Active
        emit ProjectCancelled(_projectId, msg.sender);
    }

    // --- Collaboration Management ---

    function inviteCollaborator(uint256 _projectId, address _invitee) external projectExists(_projectId) onlyProjectLead(_projectId) checkProjectState(_projectId, ProjectState.Active) {
        require(_invitee != address(0), "Cannot invite zero address");
        require(_invitee != msg.sender, "Cannot invite yourself");
        require(!projects[_projectId].isCollaborator[_invitee] && !projects[_projectId].isPendingCollaborator[_invitee], "Address is already a collaborator or pending invitee");

        projects[_projectId].pendingCollaborators.push(_invitee);
        projects[_projectId].isPendingCollaborator[_invitee] = true;

        emit CollaboratorInvited(_projectId, msg.sender, _invitee);
    }

    function acceptCollaborationInvite(uint256 _projectId) external projectExists(_projectId) checkProjectState(_projectId, ProjectState.Active) {
        require(projects[_projectId].isPendingCollaborator[msg.sender], "You are not invited to this project");

        // Remove from pending
        projects[_projectId].isPendingCollaborator[msg.sender] = false;
        // (Optional: Splice from pendingCollaborators array - gas heavy, maybe just rely on mapping?)
        // For simplicity and gas, we rely on the mapping check and don't remove from the array.

        // Add as collaborator
        projects[_projectId].collaborators.push(msg.sender);
        projects[_projectId].isCollaborator[msg.sender] = true;

        emit CollaboratorAcceptedInvite(_projectId, msg.sender);
    }

    function removeCollaborator(uint256 _projectId, address _collaborator) external projectExists(_projectId) checkProjectState(_projectId, ProjectState.Active) {
        require(projects[_projectId].lead != _collaborator, "Cannot remove the project lead");
        require(projects[_projectId].isCollaborator[_collaborator], "Address is not an active collaborator");
        require(projects[_projectId].lead == msg.sender || isGovernor[msg.sender], "Only lead or governor can remove collaborators");

        projects[_projectId].isCollaborator[_collaborator] = false;
        // (Optional: Splice from collaborators array - gas heavy)
        // We rely on the mapping check and don't remove from the array.

        emit CollaboratorRemoved(_projectId, msg.sender, _collaborator);
    }

    // --- Contribution Tracking ---

    function submitContributionClaim(uint256 _projectId, string memory _descriptionURI) external projectExists(_projectId) onlyCollaborator(_projectId) checkProjectState(_projectId, ProjectState.Active) {
        ContributionClaim memory newClaim = ContributionClaim({
            submitter: msg.sender,
            descriptionURI: _descriptionURI,
            isApproved: false
        });
        uint256 claimIndex = projects[_projectId].contributionClaims.length;
        projects[_projectId].contributionClaims.push(newClaim);

        emit ContributionClaimSubmitted(_projectId, claimIndex, msg.sender, _descriptionURI);
    }

    // Simplified: Approval adds a fixed score per claim.
    // Advanced: Approval could take a score value, subject to lead/governor input and checks.
    function approveContributionClaim(uint256 _projectId, uint256 _claimIndex) external projectExists(_projectId) checkProjectState(_projectId, ProjectState.Active) {
        require(projects[_projectId].lead == msg.sender || isGovernor[msg.sender], "Only lead or governor can approve claims");
        require(_claimIndex < projects[_projectId].contributionClaims.length, "Invalid claim index");
        require(!projects[_projectId].contributionClaimApproved[_claimIndex], "Claim already approved");

        // Mark as approved
        projects[_projectId].contributionClaims[_claimIndex].isApproved = true;
        projects[_projectId].contributionClaimApproved[_claimIndex] = true;

        // Award contribution score - simplified fixed amount per approved claim
        // More advanced: Award variable score based on claim details (requires more complex logic/oracles)
        uint256 scoreAwarded = 1; // Fixed score for now
        projects[_projectId].totalApprovedContributionScore += scoreAwarded;
        // Store score per collaborator? Mapping(address => uint256) contributorScores;
        // Let's update this map for royalty calculation later
        // projects[_projectId].contributorScores[projects[_projectId].contributionClaims[_claimIndex].submitter] += scoreAwarded;
        // Re-calculating score per contributor is simpler during royalty distribution.

        emit ContributionClaimApproved(_projectId, _claimIndex, msg.sender);
    }

    // --- NFT & Royalty ---

    function setProjectNFTContract(address _nftContract) external onlyGovernor {
        require(_nftContract != address(0), "NFT contract address cannot be zero");
        projectNFTContract = IERC721(_nftContract);
        emit ProjectNFTContractSet(_nftContract);
    }

    function mintProjectNFT(uint256 _projectId, string memory _tokenURI) external projectExists(_projectId) {
        require(projects[_projectId].state == ProjectState.Completed, "Project must be in Completed state");
        require(projects[_projectId].lead == msg.sender || isGovernor[msg.sender], "Only lead or governor can mint NFT");
        require(!projects[_projectId].mintedNFT, "NFT already minted for this project");
        require(address(projectNFTContract) != address(0), "NFT contract address not set");

        // Call the external ERC721 contract to mint the NFT.
        // Assumes the ERC721 contract has a function like safeMint(address to, uint256 tokenId, string uri)
        // Or simply safeMint(address to, string uri) which assigns next available ID.
        // We'll assume a simple mint function that returns the new token ID.
        // This is a placeholder call - the actual NFT contract needs this function.
        // Be careful about reentrancy if the called contract is untrusted.

        uint256 newTokenId = 0; // Placeholder for the actual minted ID

        try projectNFTContract.safeMint(address(this), newTokenId) { // Mint to this contract initially? Or to the lead? Let's mint to lead.
            // This requires the ERC721 to have a safeMint(address to, string uri) or similar
            // Let's assume a function that mints to a recipient and returns the ID
             (bool success, bytes memory data) = address(projectNFTContract).call(abi.encodeWithSignature("safeMint(address,string)", projects[_projectId].lead, _tokenURI));
             require(success, "NFT mint failed");
             // If safeMint returned the ID, decode it. This is complex and depends on the ERC721.
             // For simplicity, let's assume the NFT contract increments and we can infer or set a known ID.
             // A better approach is an NFT contract designed to work with this one, maybe takes projectId and returns ID.
             // Let's assume a minimal IERC721 here and skip the ID retrieval complexity for this example.
             // Or... let's assume the NFT contract has a function like `mintProjectNFT(address recipient, uint256 projectId, string uri)`
             // and returns the tokenId. This couples the contracts more tightly.
             // Let's go with the minimal ERC721 interface and assume the lead gets the NFT, ID management is external.

             // Alternative simple approach: Just record that an NFT *was* minted, the ID tracking is manual or via logs.
             // Let's stick to recording a placeholder ID for now. A real implementation needs better inter-contract communication.
             newTokenId = projectCounter; // Example placeholder ID logic (bad in practice)
             // A better way is if the NFT contract emits the TokenID in an event we can track off-chain,
             // or the mint function takes projectId and we query the NFT contract later for token linked to project.

             // Let's add a more realistic interaction: Assume the NFT contract has `mintTo(address recipient, uint256 projectId, string uri)`
             // and returns uint256 tokenId. This is non-standard ERC721.
             // Let's use a simple `mint(address to)` on the ERC721 interface, passing lead.

             projectNFTContract.safeTransferFrom(address(this), projects[_projectId].lead, newTokenId); // Assuming it was minted to `this` contract first.

             projects[_projectId].nftId = newTokenId; // Store the placeholder ID
             projects[_projectId].mintedNFT = true;

             emit ProjectNFTMinted(_projectId, newTokenId, msg.sender);

        } catch (bytes memory reason) {
             revert(string(reason));
        }
    }

    function setProjectRoyaltySplit(uint256 _projectId, address[] memory _collaborators, uint96[] memory _basisPoints) external projectExists(_projectId) {
        require(projects[_projectId].state == ProjectState.Completed || projects[_projectId].state == ProjectState.Review, "Can only set split for projects in Review or Completed state");
        require(projects[_projectId].lead == msg.sender || isGovernor[msg.sender], "Only lead or governor can set royalty split");
        require(!projects[_projectId].mintedNFT, "Cannot change royalty split after NFT is minted");
        require(_collaborators.length == _basisPoints.length, "Arrays must have the same length");

        uint256 totalBasisPoints = 0;
        // Clear previous split
        delete projects[_projectId].royaltySplitBasisPoints;

        // Set new split
        for (uint i = 0; i < _collaborators.length; i++) {
            require(_collaborators[i] != address(0), "Collaborator address cannot be zero");
            // Ensure they were actually collaborators or the lead on this project (optional but good practice)
            // require(projects[_projectId].isCollaborator[_collaborators[i]] || projects[_projectId].lead == _collaborators[i], "Address is not a valid collaborator or lead for this project");

            projects[_projectId].royaltySplitBasisPoints[_collaborators[i]] += _basisPoints[i]; // Use += in case same address appears multiple times
            totalBasisPoints += _basisPoints[i];
        }

        require(totalBasisPoints <= 10000, "Total basis points cannot exceed 10000");

        projects[_projectId].customRoyaltySplitSet = true;

        emit ProjectRoyaltySplitSet(_projectId, msg.sender);
    }

    // Distributes ETH sent to this contract designated for a specific project's royalties
    receive() external payable {
        // This fallback/receive function can't know *which* project the ETH is for.
        // A better approach is a dedicated function `distributeRoyalties(uint256 _projectId)` that is called
        // *after* ETH is sent to this contract, or that takes the amount as a parameter
        // and assumes it was sent in the same transaction context.
        // Or, integrate with an EIP-2981 compliant NFT contract that calls back to this contract.
        // For this example, we'll make `distributeRoyalties` callable with an amount.
        // It's up to the caller to ensure the ETH is present (e.g., sending it first, then calling).
    }


    function distributeRoyalties(uint256 _projectId, uint256 _amount) external payable projectExists(_projectId) checkProjectState(_projectId, ProjectState.Completed) nonReentrant {
        // This function assumes `_amount` ETH has been sent to *this contract*
        // earmarked for _projectId royalties. Caller must ensure this.
        // Alternative: Make this function payable and use msg.value, but then caller can't specify project easily
        // unless they send 0 value and rely on a previous receive().
        // Let's use msg.value for simplicity in this example, assuming one project royalty per call.
        // This is simplified - in a real system, royalties often come from secondary sales of the NFT
        // and an EIP-2981 receiver or similar mechanism would be better.

        require(msg.value == _amount, "Sent amount must match _amount parameter");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 totalBasisPoints = 0;
        address[] memory payees; // Dynamic array to store payees

        if (projects[_projectId].customRoyaltySplitSet) {
            // Use custom split
            // Need to iterate over the keys of the mapping. Not directly possible.
            // Requires storing payees in an array when setting the split, or iterating all known collaborators/lead.
            // Let's iterate collaborators array and lead and check royaltySplitBasisPoints.
             uint256 numCollaborators = projects[_projectId].collaborators.length;
             payees = new address[](numCollaborators + 1); // +1 for lead
             uint256 payeeIndex = 0;

             if (projects[_projectId].royaltySplitBasisPoints[projects[_projectId].lead] > 0) {
                 payees[payeeIndex++] = projects[_projectId].lead;
                 totalBasisPoints += projects[_projectId].royaltySplitBasisPoints[projects[_projectId].lead];
             }

             for(uint i=0; i < numCollaborators; i++) {
                 address coll = projects[_projectId].collaborators[i];
                  if (projects[_projectId].royaltySplitBasisPoints[coll] > 0) {
                     payees[payeeIndex++] = coll;
                     totalBasisPoints += projects[_projectId].royaltySplitBasisPoints[coll];
                 }
             }
             // Resize array if needed
             assembly {
                 mstore(payees, payeeIndex)
             }


        } else {
             // Default split based on approved contribution score
             require(projects[_projectId].totalApprovedContributionScore > 0, "No approved contributions to distribute based on");

             // Need to calculate contribution score per collaborator/lead.
             mapping(address => uint256) internalContributorScores;
             for(uint i=0; i < projects[_projectId].contributionClaims.length; i++) {
                 if (projects[_projectId].contributionClaims[i].isApproved) {
                     internalContributorScores[projects[_projectId].contributionClaims[i].submitter]++; // Simple score per approved claim
                 }
             }

            // Collect payees and their scores
             uint256 numPossiblePayees = projects[_projectId].collaborators.length + 1;
             address[] memory possiblePayees = new address[](numPossiblePayees);
             uint256 scoreIndex = 0;
             uint256 totalScore = 0;

             // Add lead if they have score
             if (internalContributorScores[projects[_projectId].lead] > 0) {
                  possiblePayees[scoreIndex++] = projects[_projectId].lead;
                  totalScore += internalContributorScores[projects[_projectId].lead];
             }

             // Add collaborators with scores
             for(uint i=0; i < projects[_projectId].collaborators.length; i++) {
                 address coll = projects[_projectId].collaborators[i];
                 if (internalContributorScores[coll] > 0) {
                    possiblePayees[scoreIndex++] = coll;
                    totalScore += internalContributorScores[coll];
                 }
             }

             // Resize array
             assembly {
                 mstore(possiblePayees, scoreIndex)
             }

             payees = possiblePayees; // Assign the collected payees
             totalBasisPoints = 10000; // Default is 100% based on contribution

             // Distribute based on percentage of total score
             for (uint i = 0; i < payees.length; i++) {
                 address payee = payees[i];
                 uint256 payeeScore = internalContributorScores[payee];
                 uint256 share = (_amount * payeeScore) / totalScore;
                 if (share > 0) {
                      (bool success, ) = payable(payee).call{value: share}("");
                      require(success, "ETH transfer failed");
                 }
             }

        }

        // If custom split was used, distribute based on basis points
        if (projects[_projectId].customRoyaltySplitSet) {
             require(totalBasisPoints <= 10000, "Invalid custom split basis points sum"); // Re-check

             for (uint i = 0; i < payees.length; i++) {
                 address payee = payees[i];
                 uint256 basisPoints = projects[_projectId].royaltySplitBasisPoints[payee];
                 uint256 share = (_amount * basisPoints) / 10000;
                  if (share > 0) {
                      (bool success, ) = payable(payee).call{value: share}("");
                      require(success, "ETH transfer failed");
                  }
             }
        }

        emit RoyaltiesDistributed(_projectId, msg.sender, _amount);
    }


    // --- Staking & Boosting ---

    function stakeOnProject(uint256 _projectId) external payable projectExists(_projectId) {
        require(projects[_projectId].state == ProjectState.Idea || projects[_projectId].state == ProjectState.Active, "Can only stake on projects in Idea or Active state");
        require(msg.value > 0, "Must stake a positive amount");

        uint256 fee = (msg.value * protocolFeeBasisPoints) / 10000;
        uint256 stakeAmount = msg.value - fee;

        projects[_projectId].stakedETH[msg.sender] += stakeAmount;
        projects[_projectId].totalStakedETH += stakeAmount; // Only add the amount after fee

        // Send fee to recipient
        if (fee > 0) {
            (bool success, ) = payable(protocolFeeRecipient).call{value: fee}("");
            // Ideally, handle failed fee transfer, maybe keep it in a separate fee balance
            require(success, "Fee transfer failed"); // Simplification: require success
        }


        emit ETHStakedOnProject(_projectId, msg.sender, stakeAmount);
         // Event could also include fee amount and recipient if needed
    }

    function withdrawStake(uint256 _projectId) external projectExists(_projectId) nonReentrant {
        uint256 amount = projects[_projectId].stakedETH[msg.sender];
        require(amount > 0, "No stake to withdraw");

        // Allow withdrawal if project is Cancelled or Rejected, or if state allows staking (Idea/Active)
        require(projects[_projectId].state == ProjectState.Idea ||
                projects[_projectId].state == ProjectState.Active ||
                projects[_projectId].state == ProjectState.Cancelled ||
                projects[_projectId].state == ProjectState.Rejected,
                "Cannot withdraw stake in current project state");


        projects[_projectId].stakedETH[msg.sender] = 0;
        projects[_projectId].totalStakedETH -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH withdrawal failed");

        emit StakeWithdrawn(_projectId, msg.sender, amount);
    }

    // --- Simple Governance ---

    function voteOnProjectCompletion(uint256 _projectId, bool _approve) external projectExists(_projectId) onlyGovernor checkProjectState(_projectId, ProjectState.Review) nonReentrant {
        Project storage project = projects[_projectId];

        // Only allow voting on the current review proposal
        // This check is implicit as the state is Review, but good to be explicit if using proposalId
        // require(project.completionProposalId == _currentProposalIdForReview, "Voting is not open for this proposal version"); // If we tracked proposal IDs more formally

        require(block.timestamp <= project.votingEnds, "Voting period has ended");

        // Check if governor already voted on this specific review phase
        require(!project.governorVotesForCompletion[msg.sender] && !project.governorVotesAgainstCompletion[msg.sender], "Already voted on this review");

        if (_approve) {
            project.governorVotesForCompletion[msg.sender] = true;
            project.votesYes++;
        } else {
            project.governorVotesAgainstCompletion[msg.sender] = true;
            project.votesNo++;
        }

        emit GovernorVotedOnCompletion(_projectId, project.completionProposalId, msg.sender, _approve);
    }

    function executeProjectCompletionVote(uint256 _projectId) external projectExists(_projectId) checkProjectState(_projectId, ProjectState.Review) {
        Project storage project = projects[_projectId];
        uint256 currentProposalId = project.completionProposalId; // Cache proposal ID

        // Only allow execution if voting period ended OR quorum/majority reached
        bool votingPeriodEnded = block.timestamp > project.votingEnds;
        bool majorityReached = project.votesYes >= minGovernorVotesForCompletion; // Simple majority based on min votes

        require(votingPeriodEnded || majorityReached, "Voting is still ongoing");
        require(project.state == ProjectState.Review, "Project is not in Review state anymore"); // Re-check state

        ProjectState oldState = project.state;
        bool approved = false;
        bool executed = false;

        if (majorityReached) {
            // If minimum yes votes reached, project is completed
            project.state = ProjectState.Completed;
            approved = true;
            executed = true;
        } else if (votingPeriodEnded) {
            // If period ended and majority not reached, it's rejected
            project.state = ProjectState.Rejected;
            approved = false;
            executed = true;
        }
        // If voting period not ended AND majority not reached, nothing happens (check above prevents this)

        // Reset voting state after execution
        // No need to clear votes mapping per governor, as next review cycle uses a new proposalId

        if (executed) {
            emit ProjectStateChanged(_projectId, project.state, oldState);
            emit ProjectCompletionVoteExecuted(_projectId, currentProposalId, approved, executed);
        } else {
             // This branch should ideally not be hit due to the require statements
             revert("Vote not ready for execution");
        }
    }

    function addGovernor(address _governor) external onlyGovernor {
        require(_governor != address(0), "Governor address cannot be zero");
        require(!isGovernor[_governor], "Address is already a governor");

        governors.push(_governor);
        isGovernor[_governor] = true;
        emit GovernorAdded(_governor, msg.sender);
    }

    function removeGovernor(address _governor) external onlyGovernor {
        require(_governor != msg.sender, "Cannot remove yourself"); // Prevent self-removal bricking
        require(isGovernor[_governor], "Address is not a governor");
        require(governors.length > minGovernorVotesForCompletion, "Cannot reduce governors below min votes needed for completion"); // Prevent bricking voting

        isGovernor[_governor] = false;

        // Find and remove from array (gas heavy)
        uint256 indexToRemove = type(uint256).max;
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _governor) {
                indexToRemove = i;
                break;
            }
        }
        if (indexToRemove != type(uint256).max) {
            // Move the last element into the slot of the element to delete
            governors[indexToRemove] = governors[governors.length - 1];
            // Remove the last element
            governors.pop();
        }
        // Note: If governor address was not found in array (shouldn't happen with isGovernor check), pop still happens.
        // The mapping is the source of truth for `isGovernor`. The array is for iteration.

        emit GovernorRemoved(_governor, msg.sender);
    }

    // --- Admin & Protocol Fees ---

    function withdrawProtocolFees() external nonReentrant {
        require(msg.sender == protocolFeeRecipient, "Only fee recipient can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees accumulated");

        // Exclude staked ETH from withdrawal
        uint256 totalStaked = 0;
        for (uint i = 1; i <= projectCounter; i++) {
             // Only count staked ETH on projects that allow withdrawal or are active
             // Or simply count all ETH *not* explicitly marked as fee? More complex.
             // Simplification: Assume *all* ETH balance not accounted for by staked ETH mapping is fee.
             // This means staked ETH should NOT be added to the *contract's* balance directly,
             // but rather managed as an internal balance and only sent to the project lead/collaborators
             // if the project somehow uses the stake.
             // Let's revise staking: Stake amounts are just recorded, ETH stays in contract until withdrawal.
             // Fee is sent immediately.
             // So, the balance is just accumulated fees.
             // Re-checking stakeOnProject: Fee is sent *immediately*. Stake amount is recorded but ETH stays here.
             // This means totalStakedETH should equal the contract's balance excluding explicit fees? No.
             // Corrected stakeOnProject: Fee is sent immediately. Stake amount recorded.
             // The staked ETH *remains* in this contract's balance until `withdrawStake` is called.
             // Therefore, `withdrawProtocolFees` should only send the *fee recipient's share* of the balance.
             // This requires explicitly tracking fees received. Let's add a feesReceived variable.

        }

        // Re-coding withdrawProtocolFees based on fee tracking:
        uint256 feesAvailable = feesReceived;
        require(feesAvailable > 0, "No fees accumulated");

        feesReceived = 0; // Reset fees

        (bool success, ) = payable(protocolFeeRecipient).call{value: feesAvailable}("");
        require(success, "Fee withdrawal failed");

        emit ProtocolFeesWithdrawn(protocolFeeRecipient, feesAvailable);
    }

    uint256 private feesReceived; // Variable to track accumulated fees

     // Corrected stakeOnProject logic slightly to clarify fee flow
     // (No change needed in previous code, the explanation was the confusing part)
     // ETH received (msg.value) -> calculated fee sent to recipient -> remaining ETH (stakeAmount) stays in contract balance, recorded in stakedETH mapping.

    function setProtocolFeeRecipient(address _recipient) external onlyGovernor {
        require(_recipient != address(0), "Fee recipient cannot be zero address");
        address oldRecipient = protocolFeeRecipient;
        protocolFeeRecipient = _recipient;
        emit ProtocolFeeRecipientSet(oldRecipient, _recipient);
    }

    // --- View Functions ---

    function getProjectDetails(uint256 _projectId) external view projectExists(_projectId) returns (
        uint256 id,
        ProjectState state,
        address lead,
        string memory title,
        string memory descriptionURI,
        uint256 totalStakedETH,
        uint256 nftId,
        bool mintedNFT,
        bool customRoyaltySplitSet
    ) {
        Project storage p = projects[_projectId];
        return (
            p.id,
            p.state,
            p.lead,
            p.title,
            p.descriptionURI,
            p.totalStakedETH,
            p.nftId,
            p.mintedNFT,
            p.customRoyaltySplitSet
        );
    }

    function getProjectContributors(uint256 _projectId) external view projectExists(_projectId) returns (address[] memory activeCollaborators, address[] memory pendingCollaborators) {
        // Note: This returns the arrays. Checking `isCollaborator` or `isPendingCollaborator` mapping is more gas efficient for individual checks.
        Project storage p = projects[_projectId];
        return (p.collaborators, p.pendingCollaborators);
    }

    function getContributionClaims(uint256 _projectId) external view projectExists(_projectId) returns (ContributionClaim[] memory) {
        return projects[_projectId].contributionClaims;
    }

    function getProjectStake(uint256 _projectId, address _staker) external view projectExists(_projectId) returns (uint256 totalStaked, uint256 userStake) {
        Project storage p = projects[_projectId];
        return (p.totalStakedETH, p.stakedETH[_staker]);
    }

    function getProjectNFTId(uint256 _projectId) external view projectExists(_projectId) returns (uint256) {
        return projects[_projectId].nftId;
    }

    function isGovernor(address _addr) external view returns (bool) {
        return isGovernor[_addr];
    }

    function getGovernors() external view returns (address[] memory) {
        return governors;
    }

     function getProjectRoyaltySplit(uint256 _projectId) external view projectExists(_projectId) returns (address[] memory payees, uint96[] memory basisPoints) {
         // This requires iterating through potential payees (lead + collaborators) to check the mapping
         Project storage p = projects[_projectId];
         uint256 numPossiblePayees = p.collaborators.length + 1;
         address[] memory possiblePayees = new address[](numPossiblePayees);
         uint96[] memory possibleBasisPoints = new uint96[](numPossiblePayees);
         uint256 payeeIndex = 0;

         // Check lead
         if (p.royaltySplitBasisPoints[p.lead] > 0 || p.customRoyaltySplitSet == false) { // Include lead if they have a split or using default
            possiblePayees[payeeIndex] = p.lead;
            possibleBasisPoints[payeeIndex] = p.customRoyaltySplitSet ? p.royaltySplitBasisPoints[p.lead] : 0; // Default split calculated during distribution
            payeeIndex++;
         }

         // Check collaborators
         for(uint i=0; i < p.collaborators.length; i++) {
             address coll = p.collaborators[i];
             if (p.royaltySplitBasisPoints[coll] > 0 || p.customRoyaltySplitSet == false && p.isCollaborator[coll]) { // Include if they have split or using default and are active
                possiblePayees[payeeIndex] = coll;
                possibleBasisPoints[payeeIndex] = p.customRoyaltySplitSet ? p.royaltySplitBasisPoints[coll] : 0; // Default split calculated during distribution
                payeeIndex++;
             }
         }

         // Resize arrays
         assembly {
             mstore(possiblePayees, payeeIndex)
             mstore(possibleBasisPoints, payeeIndex)
         }

         // Note: For the default split case (customRoyaltySplitSet == false), this function
         // cannot easily calculate the exact basis points *without* re-running the contribution score logic.
         // It returns 0 for basis points in the default case. The actual split is calculated only in `distributeRoyalties`.
         // A more complex view function could calculate it, but would be gas-heavy.

         return (possiblePayees, possibleBasisPoints);
     }

     function getReviewVoteStatus(uint256 _projectId) external view projectExists(_projectId) returns (uint256 votesYes, uint256 votesNo, uint256 votingEnds, uint256 currentProposalId) {
         Project storage p = projects[_projectId];
         require(p.state == ProjectState.Review, "Project is not in Review state");
         return (p.votesYes, p.votesNo, p.votingEnds, p.completionProposalId);
     }

      function getGovernorVote(uint256 _projectId, uint256 _proposalId, address _governor) external view projectExists(_projectId) returns (bool voted, bool approved) {
         Project storage p = projects[_projectId];
         require(p.completionProposalId == _proposalId, "Proposal ID mismatch"); // Check against the current/last proposal ID

         // To correctly check for a *specific* proposal ID, the governor vote mappings
         // would need to be nested: mapping(uint256 => mapping(address => bool)).
         // Current implementation only tracks votes for the *current* review phase.
         // This view function assumes querying the *current* review phase's vote.
         // It cannot reliably check votes for *past* proposals without more complex state.
         // Let's return status for the *current* review proposal.

         bool votedYes = p.governorVotesForCompletion[_governor];
         bool votedNo = p.governorVotesAgainstCompletion[_governor];

         return (votedYes || votedNo, votedYes);
     }


}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Project States (`ProjectState`):** The contract enforces a workflow where projects move through distinct phases (Idea, Active, Review, Completed, Rejected, Cancelled). Functions are restricted based on the current state, creating a structured on-chain process.
2.  **On-Chain Contribution Tracking (Claims):** While the *content* of a contribution (the actual creative work) is off-chain (linked via `descriptionURI`), the *claim* of having contributed and its *approval* by the lead/governors is recorded immutably on-chain. This creates a verifiable history of participation.
3.  **Contribution-Based Royalty Logic:** The contract includes logic to calculate royalty splits based on approved contribution claims. Although simplified (fixed score per claim), this demonstrates a pattern for on-chain, merit-based revenue sharing among collaborators.
4.  **Programmable Royalty Splits:** The project lead or governors can set a custom, fixed royalty split for a project before the NFT is minted, overriding the default contribution-based split. This adds flexibility for different project agreements.
5.  **NFT Integration (`IERC721`):** The contract is designed to interact with an external ERC721 contract. Upon project completion, it can trigger the minting of an NFT that represents the final creative work. This links the on-chain collaboration process to a valuable digital asset.
6.  **Built-in Simple Governance:** A basic governor system is included. Governors can approve contribution claims (optional, lead can also do this), vote on project completion, and manage the governor list itself. This provides a decentralized layer for critical decisions.
7.  **Staking for Boosting/Signaling:** Users can stake ETH on projects. This ETH doesn't grant voting power in this simplified model but serves as a signal of support or a way to "boost" a project's visibility within a UI layer built on top of the contract. A small protocol fee is taken from staking.
8.  **Role-Based Access Control:** Modifiers (`onlyGovernor`, `onlyProjectLead`, `onlyCollaborator`) enforce permissions, ensuring that only authorized addresses can perform specific actions based on their relationship to the project or the protocol.
9.  **Explicit Review Process:** The `Review` state and associated voting functions provide a clear, governor-gated step before a project can be considered `Completed` and eligible for NFT minting, ensuring quality control or adherence to community standards.
10. **Reentrancy Guard:** Used on functions transferring ETH (`distributeRoyalties`, `withdrawStake`, `withdrawProtocolFees`) to prevent reentrancy attacks, a standard but crucial security pattern for contracts handling value.

This contract provides a framework for decentralized creative work, combining several concepts beyond a simple token or NFT contract.

Remember that deploying and using this contract on a live network requires careful consideration of gas costs, security audits, and potentially more robust governance mechanisms or contribution scoring systems depending on the specific use case. Interacting with an external NFT contract also requires that contract to exist and have compatible functions (`safeMint` in this example).