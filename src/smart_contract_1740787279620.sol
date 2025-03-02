```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Content Co-Creation and Royalty Distribution (DCCRD)
 * @author Bard (Example, replace with your name/pseudonym)
 * @notice This contract implements a system for collaborative content creation where multiple contributors can participate
 *         in the creation of a digital asset (e.g., a song, a video, a document). It handles royalty distribution
 *         based on pre-agreed-upon contribution shares.  It incorporates a "Commit and Reveal" scheme for
 *         content submissions to ensure fairness and prevent contributors from copying others' work before the deadline.
 *
 * **Outline:**
 *  1.  **Content Creation Phase:**  Contributors register with their intended contribution using a commit-reveal mechanism.
 *  2.  **Voting Phase:**  Registered contributions are revealed, and a community vote determines which contributions are accepted.
 *  3.  **Assembly Phase:**  Accepted contributions are combined (off-chain) into the final content.  The content URI is then registered on-chain.
 *  4.  **Royalty Distribution:**  Royalties earned from the content are distributed to contributors based on their agreed-upon shares.
 *
 * **Function Summary:**
 *  - `registerContribution(bytes32 commitment, uint256 _contributionShare)`: Registers a contributor with a commitment to their content and their requested royalty share.
 *  - `revealContribution(bytes32 _commitment, string memory _contentHash, string memory _originalContent)`: Reveals the contribution associated with a given commitment.
 *  - `voteOnContribution(address _contributor, bool _approve)`:  Allows users to vote on whether a contribution should be included in the final content.
 *  - `setFinalContentURI(string memory _uri)`:  Sets the URI of the final assembled content (only callable by the designated assembler).
 *  - `distributeRoyalties(uint256 _amount)`: Distributes royalties to contributors based on their share.
 *  - `withdrawRoyalties()`: Allows contributors to withdraw their earned royalties.
 *  - `setVotingDuration(uint256 _durationSeconds)`:  Sets the duration of the voting phase.  (Governance function).
 *  - `setAssembler(address _newAssembler)`:  Sets the address allowed to set the final content URI. (Governance function).
 *  - `getContributionShare(address _contributor)`:  Retrieves a contributor's royalty share.
 *  - `getRoyaltyBalance(address _contributor)`: Retrieves a contributor's earned royalty balance.
 *  - `getContentHash(address _contributor)`: Retrieves the content hash of a contributor's contribution.
 */

contract DCCRD {

    // Struct to store contributor information
    struct Contributor {
        bytes32 commitment;
        string contentHash; // SHA-256 Hash of the contribution.
        string originalContent; // Original Content submitted.
        uint256 contributionShare; // Percentage of royalties (0-100).  Total must <= 100.
        uint256 royaltyBalance;
        bool accepted; // Whether the contribution was approved during voting.
        bool revealed; // Whether the contribution was revealed.
    }

    // State variables
    mapping(address => Contributor) public contributors;
    address[] public contributorList;
    uint256 public totalShares; // Sum of all contribution shares, must be <= 100.
    string public finalContentURI; // URI of the final assembled content.
    address public assembler; // Address allowed to set the final content URI.
    uint256 public votingStartTime;
    uint256 public votingDuration;
    mapping(address => mapping(address => bool)) public votes; // Mapping of voter -> contributor -> vote
    address public owner;

    // Events
    event ContributionRegistered(address indexed contributor, bytes32 commitment, uint256 share);
    event ContributionRevealed(address indexed contributor, string contentHash);
    event ContributionVoted(address indexed voter, address indexed contributor, bool approve);
    event FinalContentURISet(string uri);
    event RoyaltiesDistributed(uint256 amount);
    event RoyaltiesWithdrawn(address indexed contributor, uint256 amount);

    // Modifiers
    modifier onlyAssembler() {
        require(msg.sender == assembler, "Only the assembler can call this function.");
        _;
    }

    modifier onlyDuringVoting() {
        require(block.timestamp >= votingStartTime && block.timestamp <= votingStartTime + votingDuration, "Voting is not active.");
        _;
    }

    constructor(uint256 _initialVotingDuration, address _initialAssembler) {
        owner = msg.sender;
        votingDuration = _initialVotingDuration;
        assembler = _initialAssembler;
    }


    /**
     * @notice Registers a contributor and their commitment to the content.
     * @param _commitment A keccak256 hash of the contributor's content hash and original content to prevent pre-submission viewing.
     * @param _contributionShare The desired royalty share percentage (0-100).
     */
    function registerContribution(bytes32 _commitment, uint256 _contributionShare) public {
        require(contributors[msg.sender].commitment == bytes32(0), "Contributor already registered.");
        require(_contributionShare > 0 && _contributionShare <= 100, "Contribution share must be between 1 and 100.");
        require(totalShares + _contributionShare <= 100, "Total contribution shares cannot exceed 100.");

        contributors[msg.sender] = Contributor({
            commitment: _commitment,
            contentHash: "",
            originalContent: "",
            contributionShare: _contributionShare,
            royaltyBalance: 0,
            accepted: false,
            revealed: false
        });

        totalShares += _contributionShare;
        contributorList.push(msg.sender);

        emit ContributionRegistered(msg.sender, _commitment, _contributionShare);
    }

    /**
     * @notice Reveals a contributor's content hash and original content, enabling verification of commitment.
     * @param _commitment The commitment provided during registration.
     * @param _contentHash The SHA-256 hash of the content.
     * @param _originalContent The actual content string.
     */
    function revealContribution(bytes32 _commitment, string memory _contentHash, string memory _originalContent) public {
        require(contributors[msg.sender].commitment != bytes32(0), "Contributor not registered.");
        require(contributors[msg.sender].revealed == false, "Contributor already revealed.");
        require(contributors[msg.sender].commitment == _commitment, "Commitment does not match.");

        bytes32 expectedCommitment = keccak256(abi.encode(_contentHash, _originalContent));
        require(_commitment == expectedCommitment, "Revealed content does not match the commitment.");

        contributors[msg.sender].contentHash = _contentHash;
        contributors[msg.sender].originalContent = _originalContent;
        contributors[msg.sender].revealed = true;

        emit ContributionRevealed(msg.sender, _contentHash);
    }


    /**
     * @notice Allows users to vote on whether a contributor's contribution should be accepted.
     * @param _contributor The address of the contributor being voted on.
     * @param _approve Whether the vote is to approve or reject the contribution.
     */
    function voteOnContribution(address _contributor, bool _approve) public onlyDuringVoting {
        require(contributors[_contributor].commitment != bytes32(0), "Contributor does not exist.");
        require(!votes[msg.sender][_contributor], "You have already voted on this contribution.");

        votes[msg.sender][_contributor] = true;
        contributors[_contributor].accepted = _approve; // Simplified: assumes majority wins.  A more robust voting system would track votes.

        emit ContributionVoted(msg.sender, _contributor, _approve);
    }

    /**
     * @notice Sets the URI of the final assembled content (only callable by the assembler).
     * @param _uri The URI of the final content.
     */
    function setFinalContentURI(string memory _uri) public onlyAssembler {
        require(bytes(_uri).length > 0, "URI cannot be empty.");
        finalContentURI = _uri;
        emit FinalContentURISet(_uri);
    }

    /**
     * @notice Distributes royalties to contributors based on their share.
     * @param _amount The total amount of royalties to distribute.
     */
    function distributeRoyalties(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0.");

        for (uint256 i = 0; i < contributorList.length; i++) {
            address contributor = contributorList[i];
            if(contributors[contributor].accepted){ // Only distribute to accepted contributions.
                uint256 share = contributors[contributor].contributionShare;
                uint256 royalty = (_amount * share) / 100;  // Avoid floating point math

                contributors[contributor].royaltyBalance += royalty;
                emit RoyaltiesDistributed(_amount); // Emit once, not per contributor.
            }
        }
    }

    /**
     * @notice Allows contributors to withdraw their earned royalties.
     */
    function withdrawRoyalties() public {
        uint256 amount = contributors[msg.sender].royaltyBalance;
        require(amount > 0, "No royalties to withdraw.");

        contributors[msg.sender].royaltyBalance = 0;
        payable(msg.sender).transfer(amount);

        emit RoyaltiesWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Sets the duration of the voting phase.  Only callable by the owner.
     * @param _durationSeconds The duration of the voting phase in seconds.
     */
    function setVotingDuration(uint256 _durationSeconds) public {
        require(msg.sender == owner, "Only the owner can call this function.");
        votingDuration = _durationSeconds;
    }

    /**
     * @notice Sets the address allowed to set the final content URI.  Only callable by the owner.
     * @param _newAssembler The address of the new assembler.
     */
    function setAssembler(address _newAssembler) public {
         require(msg.sender == owner, "Only the owner can call this function.");
        assembler = _newAssembler;
    }

    /**
     * @notice Starts the voting phase.  Can only be called once.
     */
    function startVoting() public {
        require(votingStartTime == 0, "Voting has already started.");
        votingStartTime = block.timestamp;
    }

    /**
     * @notice Retrieves a contributor's royalty share.
     * @param _contributor The address of the contributor.
     * @return The contributor's royalty share percentage.
     */
    function getContributionShare(address _contributor) public view returns (uint256) {
        return contributors[_contributor].contributionShare;
    }

     /**
     * @notice Retrieves a contributor's royalty balance.
     * @param _contributor The address of the contributor.
     * @return The contributor's royalty balance.
     */
    function getRoyaltyBalance(address _contributor) public view returns (uint256) {
        return contributors[_contributor].royaltyBalance;
    }

    /**
     * @notice Retrieves a contributor's content hash.
     * @param _contributor The address of the contributor.
     * @return The contributor's content hash.
     */
    function getContentHash(address _contributor) public view returns (string memory) {
        return contributors[_contributor].contentHash;
    }

    /**
     * @notice Retrieves a contributor's original content.
     * @param _contributor The address of the contributor.
     * @return The contributor's original content.
     */
    function getOriginalContent(address _contributor) public view returns (string memory) {
        return contributors[_contributor].originalContent;
    }

    /**
     * @notice Check if a contributor's contribution was accepted.
     * @param _contributor The address of the contributor.
     * @return True if the contribution was accepted, false otherwise.
     */
    function isContributionAccepted(address _contributor) public view returns (bool) {
        return contributors[_contributor].accepted;
    }


     /**
     * @notice allows owner to withdraw any ether in contract balance.
     */
    function withdrawEther(address payable _to) public {
        require(msg.sender == owner, "only owner can withdraw.");
        uint256 amount = address(this).balance;
        _to.transfer(amount);
    }


    receive() external payable {}
}
```

Key improvements and explanations:

* **Commit and Reveal:**  The `registerContribution` and `revealContribution` functions implement a commit-reveal scheme.  Contributors register by committing to a hash of their content.  This prevents them from seeing other people's contributions before submitting their own, ensuring fair and independent creation.  The `keccak256(abi.encode(_contentHash, _originalContent))` generates the commitment.
* **Voting Phase:** A voting mechanism determines which contributions are included in the final content.  This allows the community (or a designated group) to curate the content.  The `voteOnContribution` allows voting.
* **Assembler Role:** A designated `assembler` address is responsible for setting the `finalContentURI`. This adds a layer of control over the final content deployment.
* **Royalty Distribution:** Royalties are distributed proportionally to contributors based on their agreed-upon `contributionShare`.  This is a core feature for rewarding collaboration. Uses integer arithmetic to avoid floating point issues.  Only accepted contributions receive royalties.
* **Withdrawal:** Contributors can withdraw their earned royalties using `withdrawRoyalties()`.
* **Governance:**  `setVotingDuration` and `setAssembler` functions provide governance controls, allowing the contract owner to adjust voting parameters and the content assembly process.
* **Clear State Management:**  Uses a `Contributor` struct to organize contributor data, and mappings to track votes and contribution status.
* **Events:** Events are emitted for key actions, making it easier to track the contract's state and history off-chain.
* **Error Handling:**  `require` statements are used to enforce constraints and prevent invalid operations.
* **Security Considerations:**  This is a basic example and requires further security auditing before being used in a production environment.  Considerations include:
    * **Reentrancy:** The `withdrawRoyalties()` function *could* be vulnerable to reentrancy attacks.  Consider using a reentrancy guard.
    * **Overflow/Underflow:**  Use SafeMath libraries (OpenZeppelin's is a good choice) to prevent potential overflow or underflow issues when performing arithmetic operations (especially royalty calculations).  Solidity 0.8+ has built-in overflow checks, but explicit use of a library enhances readability and maintainability.
    * **Denial-of-Service (DoS):**  The loop in `distributeRoyalties()` could become expensive if there are a very large number of contributors.  Consider limiting the number of contributors or using a more efficient distribution method.
    * **Front-running:** The commit-reveal scheme mitigates some front-running, but further measures might be needed depending on the application.
* **Efficiency:** The `distributeRoyalties()` function iterates through the `contributorList`.  If the list becomes very long, this could be inefficient.  Consider alternative data structures or approaches if performance is critical.
* **Voting System:** The current voting system is very basic (a single vote flips the accepted state). A real-world voting system would need to be more robust (e.g., using weighted votes, tracking individual votes, implementing a quorum).
* **Content Hashing:** Using a standard hashing algorithm like SHA-256 (represented as a string in this example) is crucial.  In a real-world application, ensure the hashing is done securely and consistently off-chain. Libraries that provide hashing functions with solidity are also available.

This improved example provides a more comprehensive foundation for a decentralized content co-creation platform.  Remember to thoroughly test and audit the contract before deploying it.  Also, consider incorporating additional features and security measures to meet the specific requirements of your application.
