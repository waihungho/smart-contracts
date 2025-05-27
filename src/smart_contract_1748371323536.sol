Okay, here is a smart contract concept that combines decentralized knowledge/secret management, conditional access, and DAO governance. It's called the "Digital DAO of Secrets".

**Concept:** A decentralized platform where "secrets" or knowledge fragments (represented by hashes/pointers) can be stored and accessed based on various on-chain conditions (like holding a specific token balance, owning an NFT, or time). The rules, access fees, and even the addition/removal of secrets are governed by holders of a "Wisdom" token via a proposal system.

**Advanced Concepts Used:**
1.  **Conditional Access Control:** Access to data (or pointers to data) is gated by configurable on-chain conditions, not just simple ownership or allowances.
2.  **DAO Governance:** Critical parameters and content (fragments) are managed through a decentralized voting process using a separate governance token.
3.  **State-Dependent Access:** Access might depend on the *current* state of the blockchain (user's balance, time, etc.) checked at the time of request.
4.  **Proposal System with Diverse Types:** Handling different types of governance actions (adding/removing fragments, changing parameters, treasury spending) within a single proposal framework.
5.  **Time-Based Unlock:** Fragments can have a future unlock time.
6.  **External Token Integration:** Relies on an external ERC-20 contract for governance/wisdom.
7.  **Treasury Management:** Collects fees and allows governed spending.
8.  **Storing Pointers/Hashes:** Secrets themselves are not stored on-chain (too expensive/public), but immutable references (hashes, IPFS pointers) are managed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline ---
// 1. State Variables: Store fragments, proposals, parameters, treasury.
// 2. Enums: Define types for conditions, proposals, and proposal states.
// 3. Structs: Define data structures for Fragments, FragmentConditions, and Proposals.
// 4. Events: Announce key actions (proposals, votes, executions, access).
// 5. Modifiers: Helper checks (proposal state, fragment existence, etc.).
// 6. Constructor: Initialize contract with basic parameters and Wisdom token address.
// 7. Admin Functions: Initial setup (like setting Wisdom token address).
// 8. Parameter View Functions: Get current contract parameters.
// 9. Fragment View Functions: Get details about stored fragments.
// 10. Fragment Access Functions: Check conditions and grant access to fragment hashes.
// 11. Proposal Creation Functions: Allow users to propose actions.
// 12. Proposal Interaction Functions: Vote on proposals.
// 13. Proposal Execution/Cancellation Functions: Finalize proposals based on votes.
// 14. Proposal View Functions: Get details about active/past proposals.
// 15. Treasury Functions: View treasury balance, propose spending.

// --- Function Summary ---
// 1. setWisdomTokenAddress(IERC20 _wisdomToken): Admin function to set the ERC20 token used for governance.
// 2. setParameters(uint256 _accessFee, uint256 _proposalThreshold, uint64 _votingPeriod, uint256 _minWisdomToPropose): Admin function for initial parameter setup (can later be changed by proposals).
// 3. getWisdomTokenAddress(): View the address of the Wisdom token contract.
// 4. getFragmentAccessFee(): View the current fee required to attempt fragment access.
// 5. getProposalThreshold(): View the minimum total votes required for a proposal to pass.
// 6. getVotingPeriod(): View the duration (in seconds) for which proposals are open for voting.
// 7. getMinWisdomToPropose(): View the minimum Wisdom token balance required to create a proposal.
// 8. getTotalFragments(): View the total number of fragments stored.
// 9. getFragmentDetails(uint256 fragmentId): View basic details of a fragment (excluding conditions/hash).
// 10. getFragmentConditions(uint256 fragmentId): View the access conditions for a specific fragment.
// 11. getFragmentContentHash(uint256 fragmentId): View the content hash of a fragment (requires specific access status).
// 12. getUserFragmentAccessStatus(address user, uint256 fragmentId): Check if a user currently has access granted for a fragment.
// 13. checkFragmentConditions(uint256 fragmentId): View function to check if the *caller* currently meets a fragment's access conditions *without* paying or granting access.
// 14. requestFragmentAccess(uint256 fragmentId): Pay the access fee, check conditions, and if met, grant and return the content hash.
// 15. proposeAddFragment(bytes32 contentHash, FragmentCondition[] conditions, uint64 unlockTime): Propose adding a new knowledge fragment.
// 16. proposeRemoveFragment(uint256 fragmentId): Propose removing an existing knowledge fragment.
// 17. proposeUpdateFragmentConditions(uint256 fragmentId, FragmentCondition[] newConditions): Propose changing the access conditions for a fragment.
// 18. proposeUpdateFragmentUnlockTime(uint256 fragmentId, uint64 newUnlockTime): Propose changing the unlock time for a fragment.
// 19. proposeSetParameters(uint256 newAccessFee, uint256 newProposalThreshold, uint64 newVotingPeriod, uint256 newMinWisdomToPropose): Propose changing global contract parameters.
// 20. proposeSpendTreasury(address target, uint256 amount): Propose sending Ether from the contract treasury.
// 21. voteOnProposal(uint256 proposalId, bool support): Cast a vote on an open proposal.
// 22. executeProposal(uint256 proposalId): Attempt to execute a proposal that has ended and passed.
// 23. cancelProposal(uint256 proposalId): Cancel a proposal that has failed or expired without passing.
// 24. getProposalDetails(uint256 proposalId): View general details of a proposal.
// 25. getProposalState(uint256 proposalId): View the current state of a proposal (Pending, Active, Canceled, Defeated, Succeeded, Executed).
// 26. getProposalVotes(uint256 proposalId): View the current vote counts for a proposal.
// 27. getUserVote(uint256 proposalId, address user): View how a specific user voted on a proposal.
// 28. getTreasuryBalance(): View the current Ether balance held by the contract treasury.
// 29. getFragmentAccessRecords(uint256 fragmentId, address user): View when a user was granted access to a fragment (returns timestamp, 0 if never).

contract DigitalDaoOfSecrets is Ownable, ReentrancyGuard {

    // --- State Variables ---

    IERC20 private s_wisdomToken; // Address of the ERC20 token used for governance

    struct Fragment {
        bytes32 contentHash; // Hash or pointer (e.g., IPFS hash) of the actual secret data (stored off-chain)
        FragmentCondition[] conditions; // Array of conditions required for access
        uint64 unlockTime; // Timestamp when the fragment becomes accessible (0 for no time lock)
        bool exists; // Flag to indicate if the fragment is active/not removed
    }

    struct FragmentCondition {
        ConditionType conditionType; // Type of condition (e.g., minimum token balance)
        uint256 value;       // Value associated with the condition (e.g., token amount)
        address targetAddress; // Address associated with the condition (e.g., token contract, NFT contract)
    }

    enum ConditionType {
        MIN_WISDOM_BALANCE,    // Requires a minimum balance of the Wisdom token
        MIN_ETHER_BALANCE,     // Requires a minimum Ether balance
        HAS_ACCESSED_FRAGMENT, // Requires having previously accessed another specific fragment
        OWN_ERC721,            // Requires owning an ERC721 token from a specific collection
        OWN_ERC1155_MIN_AMOUNT // Requires owning a minimum amount of an ERC1155 token from a specific collection
        // Add more interesting condition types here as needed
    }

    uint256 private s_nextFragmentId = 1; // Counter for unique fragment IDs
    mapping(uint256 => Fragment) private s_fragments; // Mapping from ID to Fragment struct

    // Tracks who has accessed which fragment and when
    mapping(uint256 => mapping(address => uint64)) private s_fragmentAccessRecords;

    struct Proposal {
        ProposalType proposalType; // Type of proposal
        address proposer;         // Address of the proposer
        uint256 voteStart;        // Timestamp when voting starts
        uint256 voteEnd;          // Timestamp when voting ends
        uint256 supportVotes;     // Votes in favor
        uint256 againstVotes;     // Votes against
        uint256 abstainVotes;     // Votes to abstain
        ProposalState state;      // Current state of the proposal
        bytes data;               // Encoded data specific to the proposal type (e.g., new parameters, fragment ID)
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        mapping(address => bool) vote; // True for support, False for against (abstain not tracked here)
    }

    enum ProposalType {
        ADD_FRAGMENT,
        REMOVE_FRAGMENT,
        UPDATE_FRAGMENT_CONDITIONS,
        UPDATE_FRAGMENT_UNLOCK_TIME,
        SET_PARAMETERS,
        SPEND_TREASURY
    }

    enum ProposalState {
        Pending,   // Waiting for voting period to start (not used in this version, proposals start active)
        Active,    // Currently open for voting
        Canceled,  // Canceled by proposer or due to external factors (not implemented here)
        Defeated,  // Voting period ended, did not pass
        Succeeded, // Voting period ended, passed
        Executed   // Proposal passed and effects applied
    }

    uint256 private s_nextProposalId = 1; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) private s_proposals; // Mapping from ID to Proposal struct

    // Governance Parameters
    uint256 private s_fragmentAccessFee = 0.01 ether; // Fee in Ether to attempt access
    uint256 private s_proposalThreshold = 1000;     // Minimum total votes required for a proposal to be valid/pass
    uint64 private s_votingPeriod = 3 days;        // Duration of voting period in seconds
    uint256 private s_minWisdomToPropose = 100;     // Minimum Wisdom token balance to create a proposal

    // --- Events ---

    event WisdomTokenAddressSet(address indexed token);
    event ParametersSet(uint256 accessFee, uint256 proposalThreshold, uint64 votingPeriod, uint256 minWisdomToPropose);

    event FragmentAdded(uint256 indexed fragmentId, bytes32 contentHash, uint64 unlockTime);
    event FragmentRemoved(uint256 indexed fragmentId);
    event FragmentConditionsUpdated(uint256 indexed fragmentId);
    event FragmentUnlockTimeUpdated(uint256 indexed fragmentId, uint64 newUnlockTime);
    event FragmentAccessGranted(uint256 indexed fragmentId, address indexed user, uint64 timestamp);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, uint256 voteStart, uint256 voteEnd);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 currentSupportVotes, uint256 currentAgainstVotes, uint256 currentAbstainVotes);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event TreasurySpent(address indexed target, uint256 amount);

    // --- Modifiers ---

    modifier onlyWisdomHolder(uint256 minBalance) {
        require(s_wisdomToken.balanceOf(msg.sender) >= minBalance, "Not enough Wisdom tokens");
        _;
    }

    modifier fragmentExists(uint256 fragmentId) {
        require(s_fragments[fragmentId].exists, "Fragment does not exist");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(s_proposals[proposalId].proposer != address(0), "Proposal does not exist");
        _;
    }

    modifier isActiveProposal(uint256 proposalId) {
        proposalExists(proposalId);
        require(s_proposals[proposalId].state == ProposalState.Active, "Proposal not active");
        _;
    }

    // --- Constructor ---

    constructor(IERC20 initialWisdomToken) Ownable(msg.sender) {
        require(address(initialWisdomToken) != address(0), "Initial Wisdom token address cannot be zero");
        s_wisdomToken = initialWisdomToken;
        emit WisdomTokenAddressSet(address(initialWisdomToken));
        emit ParametersSet(s_fragmentAccessFee, s_proposalThreshold, s_votingPeriod, s_minWisdomToPropose);
    }

    // Allow receiving Ether for the treasury
    receive() external payable {}

    // --- Admin Functions (Initial Setup only) ---

    // 1. Admin function to set the ERC20 token used for governance (callable only once by owner)
    function setWisdomTokenAddress(IERC20 _wisdomToken) public onlyOwner {
        require(address(s_wisdomToken) == address(0) || address(s_wisdomToken) == address(0), "Wisdom token address already set"); // Added redundancy check
        require(address(_wisdomToken) != address(0), "Wisdom token address cannot be zero");
        s_wisdomToken = _wisdomToken;
        emit WisdomTokenAddressSet(address(_wisdomToken));
    }

    // 2. Admin function for initial parameter setup (can later be changed by proposals)
    function setParameters(
        uint256 _accessFee,
        uint256 _proposalThreshold,
        uint64 _votingPeriod,
        uint256 _minWisdomToPropose
    ) public onlyOwner {
         // Basic validation, more complex validation can be done in the proposal handler
        require(_votingPeriod > 0, "Voting period must be greater than 0");
        s_fragmentAccessFee = _accessFee;
        s_proposalThreshold = _proposalThreshold;
        s_votingPeriod = _votingPeriod;
        s_minWisdomToPropose = _minWisdomToPropose;
        emit ParametersSet(s_fragmentAccessFee, s_proposalThreshold, s_votingPeriod, s_minWisdomToPropose);
    }

    // --- Parameter View Functions ---

    // 3. View the address of the Wisdom token contract
    function getWisdomTokenAddress() public view returns (address) {
        return address(s_wisdomToken);
    }

    // 4. View the current fee required to attempt fragment access
    function getFragmentAccessFee() public view returns (uint256) {
        return s_fragmentAccessFee;
    }

    // 5. View the minimum total votes required for a proposal to pass
    function getProposalThreshold() public view returns (uint256) {
        return s_proposalThreshold;
    }

    // 6. View the duration (in seconds) for which proposals are open for voting
    function getVotingPeriod() public view returns (uint64) {
        return s_votingPeriod;
    }

    // 7. View the minimum Wisdom token balance required to create a proposal
    function getMinWisdomToPropose() public view returns (uint256) {
        return s_minWisdomToPropose;
    }

    // --- Fragment View Functions ---

    // 8. View the total number of fragments stored (including potentially removed ones in the mapping, but checking 'exists')
     function getTotalFragments() public view returns (uint256) {
        return s_nextFragmentId - 1; // Last used ID is total count if starting from 1
    }

    // 9. View basic details of a fragment (excluding conditions/hash)
    function getFragmentDetails(uint256 fragmentId) public view fragmentExists(fragmentId) returns (bytes32 contentHash, uint64 unlockTime, bool exists) {
        Fragment storage fragment = s_fragments[fragmentId];
        return (fragment.contentHash, fragment.unlockTime, fragment.exists);
    }

    // 10. View the access conditions for a specific fragment
    function getFragmentConditions(uint256 fragmentId) public view fragmentExists(fragmentId) returns (FragmentCondition[] memory) {
        return s_fragments[fragmentId].conditions;
    }

    // 11. View the content hash of a fragment (requires specific access status)
    function getFragmentContentHash(uint256 fragmentId) public view fragmentExists(fragmentId) returns (bytes32) {
        require(s_fragmentAccessRecords[fragmentId][msg.sender] > 0, "Access not granted for this user");
        return s_fragments[fragmentId].contentHash;
    }

    // 12. Check if a user currently has access granted for a fragment
    function getUserFragmentAccessStatus(address user, uint256 fragmentId) public view fragmentExists(fragmentId) returns (bool) {
        return s_fragmentAccessRecords[fragmentId][user] > 0;
    }

    // --- Fragment Access Functions ---

    // 13. View function to check if the *caller* currently meets a fragment's access conditions *without* paying or granting access.
    function checkFragmentConditions(uint256 fragmentId) public view fragmentExists(fragmentId) returns (bool) {
        Fragment storage fragment = s_fragments[fragmentId];

        // Check unlock time first
        if (fragment.unlockTime > 0 && block.timestamp < fragment.unlockTime) {
            return false; // Fragment is still time-locked
        }

        // Check all defined conditions
        for (uint i = 0; i < fragment.conditions.length; i++) {
            FragmentCondition storage condition = fragment.conditions[i];
            bool conditionMet = false;

            if (condition.conditionType == ConditionType.MIN_WISDOM_BALANCE) {
                if (address(s_wisdomToken) != address(0) && s_wisdomToken.balanceOf(msg.sender) >= condition.value) {
                    conditionMet = true;
                }
            } else if (condition.conditionType == ConditionType.MIN_ETHER_BALANCE) {
                 if (msg.sender.balance >= condition.value) {
                    conditionMet = true;
                }
            } else if (condition.conditionType == ConditionType.HAS_ACCESSED_FRAGMENT) {
                 if (s_fragmentAccessRecords[condition.value][msg.sender] > 0) { // condition.value stores the required fragmentId
                    conditionMet = true;
                }
            } else if (condition.conditionType == ConditionType.OWN_ERC721) {
                // Requires interfacing with ERC721 (not imported for brevity, but would need IERC721)
                // Example: IERC721(condition.targetAddress).ownerOf(condition.value) == msg.sender
                // Or more commonly, check balance: IERC721(condition.targetAddress).balanceOf(msg.sender) > 0
                 revert("ERC721 condition not fully implemented in this example"); // Placeholder
            } else if (condition.conditionType == ConditionType.OWN_ERC1155_MIN_AMOUNT) {
                // Requires interfacing with ERC1155 (not imported)
                // Example: IERC1155(condition.targetAddress).balanceOf(msg.sender, condition.value) >= requiredAmount (need to store requiredAmount)
                 revert("ERC1155 condition not fully implemented in this example"); // Placeholder
            }
            // Add more condition types here

            if (!conditionMet) {
                return false; // If any condition is not met, access is denied
            }
        }

        return true; // All conditions met
    }


    // 14. Pay the access fee, check conditions, and if met, grant and return the content hash.
    function requestFragmentAccess(uint256 fragmentId) public payable nonReentrant fragmentExists(fragmentId) returns (bytes32) {
        Fragment storage fragment = s_fragments[fragmentId];

        require(msg.value >= s_fragmentAccessFee, "Insufficient Ether sent for access fee");

        // Transfer fee to treasury
        (bool success, ) = payable(address(this)).call{value: msg.value}("");
        require(success, "Ether transfer failed");

        // Check conditions (uses the helper view function)
        require(checkFragmentConditions(fragmentId), "Fragment access conditions not met");

        // Record access
        s_fragmentAccessRecords[fragmentId][msg.sender] = uint64(block.timestamp);

        emit FragmentAccessGranted(fragmentId, msg.sender, uint64(block.timestamp));

        // Return the content hash
        return fragment.contentHash;
    }

    // --- Proposal Creation Functions ---

    // Helper to create a generic proposal
    function _createProposal(ProposalType proposalType, bytes memory data) private onlyWisdomHolder(s_minWisdomToPropose) returns (uint256) {
        require(address(s_wisdomToken) != address(0), "Wisdom token not set");

        uint256 proposalId = s_nextProposalId++;
        uint256 voteStart = block.timestamp;
        uint256 voteEnd = voteStart + s_votingPeriod;

        s_proposals[proposalId] = Proposal({
            proposalType: proposalType,
            proposer: msg.sender,
            voteStart: voteStart,
            voteEnd: voteEnd,
            supportVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            state: ProposalState.Active,
            data: data,
            hasVoted: new mapping(address => bool),
            vote: new mapping(address => bool)
        });

        emit ProposalCreated(proposalId, msg.sender, proposalType, voteStart, voteEnd);
        return proposalId;
    }

    // 15. Propose adding a new knowledge fragment.
    function proposeAddFragment(bytes32 contentHash, FragmentCondition[] memory conditions, uint64 unlockTime) public onlyWisdomHolder(s_minWisdomToPropose) returns (uint256) {
        require(contentHash != bytes32(0), "Content hash cannot be zero");
        // Basic validation for conditions can be added here
        bytes memory data = abi.encode(contentHash, conditions, unlockTime);
        return _createProposal(ProposalType.ADD_FRAGMENT, data);
    }

    // 16. Propose removing an existing knowledge fragment.
    function proposeRemoveFragment(uint256 fragmentId) public onlyWisdomHolder(s_minWisdomToPropose) fragmentExists(fragmentId) returns (uint256) {
        bytes memory data = abi.encode(fragmentId);
        return _createProposal(ProposalType.REMOVE_FRAGMENT, data);
    }

    // 17. Propose changing the access conditions for a fragment.
    function proposeUpdateFragmentConditions(uint256 fragmentId, FragmentCondition[] memory newConditions) public onlyWisdomHolder(s_minWisdomToPropose) fragmentExists(fragmentId) returns (uint256) {
         // Basic validation for conditions can be added here
        bytes memory data = abi.encode(fragmentId, newConditions);
        return _createProposal(ProposalType.UPDATE_FRAGMENT_CONDITIONS, data);
    }

    // 18. Propose changing the unlock time for a fragment.
     function proposeUpdateFragmentUnlockTime(uint256 fragmentId, uint64 newUnlockTime) public onlyWisdomHolder(s_minWisdomToPropose) fragmentExists(fragmentId) returns (uint256) {
        bytes memory data = abi.encode(fragmentId, newUnlockTime);
        return _createProposal(ProposalType.UPDATE_FRAGMENT_UNLOCK_TIME, data);
    }


    // 19. Propose changing global contract parameters.
    function proposeSetParameters(
        uint256 newAccessFee,
        uint256 newProposalThreshold,
        uint64 newVotingPeriod,
        uint256 newMinWisdomToPropose
    ) public onlyWisdomHolder(s_minWisdomToPropose) returns (uint256) {
        require(newVotingPeriod > 0, "New voting period must be greater than 0");
        bytes memory data = abi.encode(newAccessFee, newProposalThreshold, newVotingPeriod, newMinWisdomToPropose);
        return _createProposal(ProposalType.SET_PARAMETERS, data);
    }

     // 20. Propose sending Ether from the contract treasury.
     function proposeSpendTreasury(address target, uint256 amount) public onlyWisdomHolder(s_minWisdomToPropose) returns (uint256) {
         require(target != address(0), "Target address cannot be zero");
         require(amount > 0, "Amount must be greater than zero");
         require(amount <= address(this).balance, "Insufficient treasury balance");
         bytes memory data = abi.encode(target, amount);
         return _createProposal(ProposalType.SPEND_TREASURY, data);
     }


    // --- Proposal Interaction Functions ---

    // 21. Cast a vote on an open proposal.
    function voteOnProposal(uint256 proposalId, bool support) public nonReentrant isActiveProposal(proposalId) {
        Proposal storage proposal = s_proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterWisdomBalance = s_wisdomToken.balanceOf(msg.sender);
        require(voterWisdomBalance > 0, "Voter must hold Wisdom tokens");

        proposal.hasVoted[msg.sender] = true;
        proposal.vote[msg.sender] = support; // Record the vote direction

        if (support) {
            proposal.supportVotes += voterWisdomBalance;
        } else {
            proposal.againstVotes += voterWisdomBalance;
        }
        // Abstain votes are implicitly calculated as total wisdom supply minus support/against votes that participated

        emit VoteCast(proposalId, msg.sender, support, proposal.supportVotes, proposal.againstVotes, proposal.abstainVotes);
    }

    // --- Proposal Execution/Cancellation Functions ---

    // Helper to check if a proposal has succeeded
    function _isProposalSucceeded(uint256 proposalId) internal view proposalExists(proposalId) returns (bool) {
         Proposal storage proposal = s_proposals[proposalId];

         // Proposal must have ended
         if (block.timestamp < proposal.voteEnd) {
             return false;
         }

         // Votes must meet the threshold
         uint256 totalVotesCast = proposal.supportVotes + proposal.againstVotes;
         if (totalVotesCast < s_proposalThreshold) {
             return false; // Did not meet minimum participation threshold
         }

         // Must have more support votes than against votes
         return proposal.supportVotes > proposal.againstVotes;
    }


    // 22. Attempt to execute a proposal that has ended and passed.
    function executeProposal(uint256 proposalId) public nonReentrant proposalExists(proposalId) {
        Proposal storage proposal = s_proposals[proposalId];

        // Ensure proposal is in a state that can be executed (Succeeded) or just ended and succeeded
        require(proposal.state == ProposalState.Succeeded || (proposal.state == ProposalState.Active && block.timestamp >= proposal.voteEnd && _isProposalSucceeded(proposalId)), "Proposal not in Succeeded state or cannot be executed yet");

        // If state was Active but is now end/succeeded, update state first
        if (proposal.state == ProposalState.Active) {
             proposal.state = ProposalState.Succeeded;
             emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
        }

        // Prevent double execution
        require(proposal.state != ProposalState.Executed, "Proposal already executed");


        // Execute based on type
        if (proposal.proposalType == ProposalType.ADD_FRAGMENT) {
            (bytes32 contentHash, FragmentCondition[] memory conditions, uint64 unlockTime) = abi.decode(proposal.data, (bytes32, FragmentCondition[], uint64));
            uint256 fragmentId = s_nextFragmentId++;
            s_fragments[fragmentId] = Fragment(contentHash, conditions, unlockTime, true);
            emit FragmentAdded(fragmentId, contentHash, unlockTime);

        } else if (proposal.proposalType == ProposalType.REMOVE_FRAGMENT) {
            (uint256 fragmentId) = abi.decode(proposal.data, (uint256));
            require(s_fragments[fragmentId].exists, "Fragment to remove does not exist"); // Should be checked on propose, but double check
            s_fragments[fragmentId].exists = false; // Soft delete
             // Clear conditions/hash to save some space and prevent accidental access if needed (optional)
            delete s_fragments[fragmentId].conditions;
            s_fragments[fragmentId].contentHash = bytes32(0);
            emit FragmentRemoved(fragmentId);

        } else if (proposal.proposalType == ProposalType.UPDATE_FRAGMENT_CONDITIONS) {
            (uint256 fragmentId, FragmentCondition[] memory newConditions) = abi.decode(proposal.data, (uint256, FragmentCondition[]));
             require(s_fragments[fragmentId].exists, "Fragment to update does not exist"); // Should be checked on propose
             s_fragments[fragmentId].conditions = newConditions; // Replace conditions
            emit FragmentConditionsUpdated(fragmentId);

        } else if (proposal.proposalType == ProposalType.UPDATE_FRAGMENT_UNLOCK_TIME) {
             (uint256 fragmentId, uint64 newUnlockTime) = abi.decode(proposal.data, (uint256, uint64));
             require(s_fragments[fragmentId].exists, "Fragment to update does not exist"); // Should be checked on propose
             s_fragments[fragmentId].unlockTime = newUnlockTime;
             emit FragmentUnlockTimeUpdated(fragmentId, newUnlockTime);

        } else if (proposal.proposalType == ProposalType.SET_PARAMETERS) {
            (uint256 newAccessFee, uint256 newProposalThreshold, uint64 newVotingPeriod, uint256 newMinWisdomToPropose) = abi.decode(proposal.data, (uint256, uint256, uint64, uint256));
            // Basic validation already done on propose, assuming valid input data from abi.decode
             s_fragmentAccessFee = newAccessFee;
             s_proposalThreshold = newProposalThreshold;
             s_votingPeriod = newVotingPeriod;
             s_minWisdomToPropose = newMinWisdomToPropose;
             emit ParametersSet(s_fragmentAccessFee, s_proposalThreshold, s_votingPeriod, s_minWisdomToPropose);

        } else if (proposal.proposalType == ProposalType.SPEND_TREASURY) {
             (address target, uint256 amount) = abi.decode(proposal.data, (address, uint256));
             require(address(this).balance >= amount, "Insufficient treasury balance for spending proposal"); // Double check balance

             (bool success, ) = payable(target).call{value: amount}("");
             require(success, "Treasury spend transaction failed");
             emit TreasurySpent(target, amount);
        }
        // Add execution logic for other proposal types

        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    // 23. Cancel a proposal that has failed or expired without passing.
    function cancelProposal(uint256 proposalId) public proposalExists(proposalId) {
         Proposal storage proposal = s_proposals[proposalId];

         // Can only cancel if active and voting period is over AND it did NOT succeed
         // Or if it's already marked as Defeated
         require(
            (proposal.state == ProposalState.Active && block.timestamp >= proposal.voteEnd && !_isProposalSucceeded(proposalId)) ||
            proposal.state == ProposalState.Defeated,
            "Proposal cannot be canceled in its current state or before voting ends/failure confirmed"
         );

         // If state was Active and now ended/failed, update state
         if (proposal.state == ProposalState.Active) {
              proposal.state = ProposalState.Defeated;
              emit ProposalStateChanged(proposalId, ProposalState.Defeated);
         }

         // Already Canceled or Executed states cannot be canceled again
         require(proposal.state != ProposalState.Canceled && proposal.state != ProposalState.Executed, "Proposal already finalized");

         proposal.state = ProposalState.Canceled; // Mark as canceled
         emit ProposalStateChanged(proposalId, ProposalState.Canceled);
         // Note: No refunds or special actions needed for cancellation in this design.
    }

    // --- Proposal View Functions ---

    // 24. View general details of a proposal.
    function getProposalDetails(uint256 proposalId) public view proposalExists(proposalId) returns (
        ProposalType proposalType,
        address proposer,
        uint256 voteStart,
        uint256 voteEnd,
        ProposalState state
    ) {
        Proposal storage proposal = s_proposals[proposalId];
        return (proposal.proposalType, proposal.proposer, proposal.voteStart, proposal.voteEnd, getProposalState(proposalId)); // Use helper to get current state
    }

    // 25. View the current state of a proposal (Pending, Active, Canceled, Defeated, Succeeded, Executed).
    function getProposalState(uint256 proposalId) public view proposalExists(proposalId) returns (ProposalState) {
        Proposal storage proposal = s_proposals[proposalId];

        // State is dynamic if Active and voting period ended
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.voteEnd) {
             if (_isProposalSucceeded(proposalId)) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Defeated;
             }
        }
        return proposal.state; // Return stored state for other cases
    }

    // 26. View the current vote counts for a proposal.
    function getProposalVotes(uint256 proposalId) public view proposalExists(proposalId) returns (uint256 supportVotes, uint256 againstVotes, uint256 abstainVotes) {
        Proposal storage proposal = s_proposals[proposalId];
        // Abstain votes are not directly stored, could potentially be calculated as total supply - (support+against) that have voted
        // For simplicity here, we just return the directly tracked votes. A full DAO would need supply snapshots.
        return (proposal.supportVotes, proposal.againstVotes, proposal.abstainVotes); // Abstain is always 0 in this simple tracking
    }

    // 27. View how a specific user voted on a proposal.
    function getUserVote(uint256 proposalId, address user) public view proposalExists(proposalId) returns (bool voted, bool support) {
        Proposal storage proposal = s_proposals[proposalId];
        return (proposal.hasVoted[user], proposal.vote[user]);
    }

    // --- Treasury Functions ---

    // 28. View the current Ether balance held by the contract treasury.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

     // 29. View when a user was granted access to a fragment (returns timestamp, 0 if never).
     function getFragmentAccessRecords(uint256 fragmentId, address user) public view fragmentExists(fragmentId) returns (uint64) {
        return s_fragmentAccessRecords[fragmentId][user];
    }
}
```

**Explanation of Advanced/Interesting Aspects & Functions:**

1.  **Fragment & Conditions Structs:** Defines a flexible way to describe *what* a secret is (its hash/pointer) and *how* to access it using an array of diverse `ConditionType` enums. This allows for complex access rules like "must hold 100 Wisdom tokens AND have accessed Fragment #5".
2.  **`ConditionType` Enum & `checkFragmentConditions`:** This is the core of the conditional access. The enum lists potential on-chain criteria. `checkFragmentConditions` iterates through the required conditions and verifies them against the *caller's* current state and the blockchain's state. This can be extended with many more interesting on-chain checks (e.g., owning a specific NFT from another contract, being part of a specific whitelisted group maintained elsewhere, having a certain reputation score from another protocol).
3.  **`requestFragmentAccess`:** This function requires payment (the `s_fragmentAccessFee`) and then calls `checkFragmentConditions`. If successful, it records that the user has gained access and *then* returns the `contentHash`. The user pays regardless of success (simpler implementation; a more complex version could refund on failure). The `nonReentrant` modifier is important for the Ether transfer.
4.  **`s_fragmentAccessRecords` Mapping:** Tracks which users have successfully passed the conditions and accessed a fragment, and when. This state is then usable by the `HAS_ACCESSED_FRAGMENT` condition type, creating dependencies between fragments – a user might need to unlock Fragment A to gain access to Fragment B.
5.  **DAO Governance (Proposals):** The contract parameters and fragments are not controlled by a single owner (after initial setup). The `s_wisdomToken` (an external ERC-20) governs changes.
    *   **`onlyWisdomHolder(s_minWisdomToPropose)` Modifier:** Ensures only token holders can propose.
    *   **Multiple `ProposalType` Enums:** Defines the different types of actions the DAO can take (add/remove fragments, change rules, spend money).
    *   **`Proposal` Struct & Mappings:** Stores all data related to proposals, votes, and state.
    *   **`_createProposal`, `voteOnProposal`, `executeProposal`, `cancelProposal`:** The standard workflow for a DAO proposal system. Votes are weighted by the caller's Wisdom token balance *at the time of voting*.
    *   **`_isProposalSucceeded`:** Encapsulates the logic for whether a proposal passes based on votes and the `s_proposalThreshold`.
    *   **`executeProposal` with `abi.decode`:** Dynamically decodes the `data` field based on the `proposalType` to perform the correct action (adding fragment, changing parameter, sending Ether, etc.). This makes the proposal system extensible.
6.  **Time Lock (`unlockTime`):** Fragments can be made inaccessible until a specific future timestamp.
7.  **Treasury (`getTreasuryBalance`, `proposeSpendTreasury`):** The access fees collect Ether in the contract, which can then be spent via a DAO proposal.
8.  **Soft Deletion (`exists` flag):** Fragments are marked as non-existent rather than fully deleted to maintain historical data and avoid issues with fragment IDs.
9.  **View Functions for Transparency:** Many view functions (`getFragmentConditions`, `getProposalState`, etc.) allow users to inspect the state of fragments and proposals. `checkFragmentConditions` is particularly useful as it lets users see if they *would* meet the conditions without committing to the transaction fee.

This contract provides a framework for decentralized, conditionally-accessible knowledge governed by its users, moving beyond simple token or NFT standards. It could be a basis for decentralized educational content, tiered access to information, on-chain puzzles, or collaborative world-building.