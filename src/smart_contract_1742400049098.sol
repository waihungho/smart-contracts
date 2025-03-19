```solidity
/**
 * @title Decentralized Dynamic Content Platform - "Chameleon Canvas"
 * @author Gemini
 * @dev A smart contract for a decentralized platform where content evolves dynamically based on community interaction, environmental data, oracles, and on-chain events.

 * **Outline:**
 *
 * **I. Core Functionality: Content Management & Evolution**
 *   1. `createContent(string _initialContentURI, string _contentType, string _metadataURI)`: Allows users to create new dynamic content pieces.
 *   2. `getContentDetails(uint256 _contentId)`: Retrieves details of a specific content piece.
 *   3. `updateContentMetadata(uint256 _contentId, string _newMetadataURI)`:  Allows content creators to update metadata.
 *   4. `evolveContent(uint256 _contentId)`: Triggers content evolution based on predefined rules (internal logic, oracle data, community vote, etc.).
 *   5. `getContentEvolutionState(uint256 _contentId)`:  Checks the current evolution state of a content piece.
 *   6. `setContentEvolutionRule(uint256 _contentId, EvolutionRule _rule)`: Sets or updates the evolution rule for a content piece (admin/creator function).
 *   7. `getContentEvolutionRule(uint256 _contentId)`: Retrieves the evolution rule for a content piece.

 * **II. Community Interaction & Governance**
 *   8. `interactWithContent(uint256 _contentId, InteractionType _interaction)`: Allows users to interact with content (e.g., like, comment, vote).
 *   9. `getContentInteractionCount(uint256 _contentId, InteractionType _interaction)`: Gets the count of specific interactions for content.
 *  10. `proposeEvolutionParameterChange(uint256 _contentId, string _parameterName, string _newValue)`:  Users can propose changes to content evolution parameters.
 *  11. `voteOnParameterChangeProposal(uint256 _proposalId, bool _vote)`: Community members can vote on parameter change proposals.
 *  12. `executeParameterChange(uint256 _proposalId)`: Executes approved parameter changes after voting (governance mechanism).

 * **III. Oracle Integration & External Data**
 *  13. `setOracleAddress(address _oracleAddress)`: Sets the address of the trusted oracle (admin function).
 *  14. `requestExternalDataForEvolution(uint256 _contentId, string _dataQuery)`: Requests data from an oracle to influence content evolution.
 *  15. `fulfillExternalDataRequest(uint256 _contentId, string _dataQuery, string _dataValue)`: Oracle callback function to provide data.

 * **IV. Monetization & Creator Economy**
 *  16. `setContentPricing(uint256 _contentId, uint256 _price)`: Allows creators to set a price for accessing premium content layers or features.
 *  17. `purchaseContentAccess(uint256 _contentId)`: Users can purchase access to premium content.
 *  18. `withdrawCreatorEarnings()`: Creators can withdraw their earnings.
 *  19. `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage on content purchases (admin function).

 * **V. Utility & Admin Functions**
 *  20. `pauseContract()`: Pauses core contract functionalities (admin function).
 *  21. `unpauseContract()`: Resumes contract functionalities (admin function).
 *  22. `setAdmin(address _newAdmin)`: Changes the contract administrator (admin function).
 *  23. `getContractBalance()`:  Retrieves the contract's ETH balance.
 *  24. `recoverStuckTokens(address _tokenAddress, address _recipient, uint256 _amount)`:  Admin function to recover accidentally sent tokens.

 * **Function Summary:**
 * - `createContent`:  Registers new dynamic content with initial URI and metadata.
 * - `getContentDetails`:  Retrieves comprehensive information about a content piece.
 * - `updateContentMetadata`:  Allows content creators to update the metadata URI.
 * - `evolveContent`:  Triggers the evolution process based on defined rules.
 * - `getContentEvolutionState`:  Checks the current evolution stage of content.
 * - `setContentEvolutionRule`:  Defines or modifies the rules governing content evolution.
 * - `getContentEvolutionRule`:  Retrieves the currently active evolution rule.
 * - `interactWithContent`:  Records user interactions (likes, votes, etc.).
 * - `getContentInteractionCount`:  Counts specific types of user interactions.
 * - `proposeEvolutionParameterChange`:  Allows users to suggest changes to evolution parameters.
 * - `voteOnParameterChangeProposal`:  Enables community voting on parameter change proposals.
 * - `executeParameterChange`:  Implements approved parameter changes after voting.
 * - `setOracleAddress`:  Sets the trusted oracle's address for external data.
 * - `requestExternalDataForEvolution`:  Requests data from the oracle for content evolution.
 * - `fulfillExternalDataRequest`:  Oracle callback to provide requested external data.
 * - `setContentPricing`:  Sets a price for premium content access.
 * - `purchaseContentAccess`:  Allows users to buy access to premium content.
 * - `withdrawCreatorEarnings`:  Enables creators to withdraw their earned funds.
 * - `setPlatformFee`:  Sets the platform fee percentage on content purchases.
 * - `pauseContract`:  Temporarily halts core contract operations.
 * - `unpauseContract`:  Resumes normal contract operations.
 * - `setAdmin`:  Changes the contract administrator address.
 * - `getContractBalance`:  Retrieves the contract's ETH balance.
 * - `recoverStuckTokens`:  Admin function to recover mistakenly sent tokens.
 */
pragma solidity ^0.8.0;

contract ChameleonCanvas {
    // -------- State Variables --------

    address public admin;
    bool public paused;
    address public oracleAddress;
    uint256 public platformFeePercentage;

    uint256 public nextContentId;
    mapping(uint256 => Content) public contentRegistry;
    mapping(uint256 => EvolutionRule) public contentEvolutionRules;
    mapping(uint256 => ContentEvolutionState) public contentEvolutionStates;
    mapping(uint256 => uint256) public contentPrices; // Content ID => Price in Wei
    mapping(uint256 => mapping(address => bool)) public contentAccessPurchased; // Content ID => User Address => Has Access
    mapping(address => uint256) public creatorEarnings; // Creator Address => Earnings Balance

    uint256 public nextProposalId;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Proposal ID => Voter Address => Vote (true=yes, false=no)

    mapping(uint256 => mapping(InteractionType => uint256)) public contentInteractionCounts; // Content ID => Interaction Type => Count

    enum InteractionType { LIKE, COMMENT, VOTE_UP, VOTE_DOWN }

    struct Content {
        uint256 id;
        address creator;
        string initialContentURI;
        string contentType;
        string metadataURI;
        uint256 createdAtTimestamp;
    }

    struct EvolutionRule {
        EvolutionType evolutionType;
        string ruleDetails; // JSON or URI describing the evolution logic
        uint256 lastEvolutionTimestamp;
    }

    enum EvolutionType {
        NONE,
        TIME_BASED,
        INTERACTION_BASED,
        ORACLE_BASED,
        COMMUNITY_VOTE_BASED,
        EXTERNAL_EVENT_BASED // e.g., specific on-chain event triggers evolution
    }

    struct ContentEvolutionState {
        uint256 contentId;
        uint256 currentEvolutionStage;
        string currentContentURI;
        string evolutionStateDetails; // JSON or URI detailing the current state
        uint256 lastStateUpdateTimestamp;
    }

    struct ParameterChangeProposal {
        uint256 proposalId;
        uint256 contentId;
        address proposer;
        string parameterName;
        string newValue;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }


    // -------- Events --------
    event ContentCreated(uint256 contentId, address creator, string initialContentURI, string contentType);
    event ContentMetadataUpdated(uint256 contentId, string newMetadataURI);
    event ContentEvolved(uint256 contentId, uint256 newEvolutionStage, string newContentURI);
    event EvolutionRuleSet(uint256 contentId, EvolutionType evolutionType, string ruleDetails);
    event ContentInteractionRecorded(uint256 contentId, address user, InteractionType interactionType);
    event ParameterChangeProposed(uint256 proposalId, uint256 contentId, address proposer, string parameterName, string newValue);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, uint256 contentId, string parameterName, string newValue);
    event OracleAddressSet(address oracleAddress);
    event ExternalDataRequested(uint256 contentId, string dataQuery);
    event ExternalDataFulfilled(uint256 contentId, string dataQuery, string dataValue);
    event ContentPriceSet(uint256 contentId, uint256 price);
    event ContentAccessPurchased(uint256 contentId, address buyer, uint256 price);
    event CreatorEarningsWithdrawn(address creator, uint256 amount);
    event PlatformFeeSet(uint256 feePercentage);
    event ContractPaused();
    event ContractUnpaused();
    event AdminChanged(address newAdmin);
    event TokensRecovered(address tokenAddress, address recipient, uint256 amount);


    // -------- Modifiers --------
    modifier onlyOwner() {
        require(msg.sender == admin, "Only admin can call this function.");
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

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only the oracle can call this function.");
        _;
    }

    // -------- Constructor --------
    constructor(address _initialAdmin, address _initialOracleAddress, uint256 _initialPlatformFeePercentage) {
        admin = _initialAdmin;
        oracleAddress = _initialOracleAddress;
        platformFeePercentage = _initialPlatformFeePercentage;
        paused = false;
        nextContentId = 1;
        nextProposalId = 1;
    }

    // -------- I. Core Functionality: Content Management & Evolution --------

    /// @notice Allows users to create new dynamic content pieces.
    /// @param _initialContentURI URI for the initial content.
    /// @param _contentType Type of content (e.g., "image", "video", "interactive").
    /// @param _metadataURI URI for content metadata.
    function createContent(string memory _initialContentURI, string memory _contentType, string memory _metadataURI) external whenNotPaused {
        uint256 contentId = nextContentId++;
        contentRegistry[contentId] = Content({
            id: contentId,
            creator: msg.sender,
            initialContentURI: _initialContentURI,
            contentType: _contentType,
            metadataURI: _metadataURI,
            createdAtTimestamp: block.timestamp
        });
        contentEvolutionStates[contentId] = ContentEvolutionState({
            contentId: contentId,
            currentEvolutionStage: 0,
            currentContentURI: _initialContentURI,
            evolutionStateDetails: "Initial State",
            lastStateUpdateTimestamp: block.timestamp
        });
        emit ContentCreated(contentId, msg.sender, _initialContentURI, _contentType);
    }

    /// @notice Retrieves details of a specific content piece.
    /// @param _contentId ID of the content.
    /// @return Content struct containing content details.
    function getContentDetails(uint256 _contentId) external view whenNotPaused returns (Content memory) {
        require(contentRegistry[_contentId].id != 0, "Content not found.");
        return contentRegistry[_contentId];
    }

    /// @notice Allows content creators to update metadata.
    /// @param _contentId ID of the content to update.
    /// @param _newMetadataURI New URI for content metadata.
    function updateContentMetadata(uint256 _contentId, string memory _newMetadataURI) external whenNotPaused {
        require(contentRegistry[_contentId].creator == msg.sender, "Only creator can update metadata.");
        contentRegistry[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI);
    }

    /// @notice Triggers content evolution based on predefined rules.
    /// @param _contentId ID of the content to evolve.
    function evolveContent(uint256 _contentId) external whenNotPaused {
        require(contentRegistry[_contentId].id != 0, "Content not found.");
        EvolutionRule memory rule = contentEvolutionRules[_contentId];
        ContentEvolutionState memory currentState = contentEvolutionStates[_contentId];

        if (rule.evolutionType == EvolutionType.TIME_BASED) {
            // Example: Evolve every 24 hours
            uint256 timeElapsed = block.timestamp - rule.lastEvolutionTimestamp;
            if (timeElapsed >= 24 hours) {
                _performTimeBasedEvolution(_contentId, currentState, rule);
            }
        } else if (rule.evolutionType == EvolutionType.INTERACTION_BASED) {
            // Example: Evolve after 1000 likes
            uint256 likeCount = contentInteractionCounts[_contentId][InteractionType.LIKE];
            // Rule details might specify the threshold for likes.
            uint256 interactionThreshold = _parseInteractionThreshold(rule.ruleDetails); // Placeholder function to parse ruleDetails
            if (likeCount >= interactionThreshold) {
                _performInteractionBasedEvolution(_contentId, currentState, rule);
            }
        } else if (rule.evolutionType == EvolutionType.ORACLE_BASED) {
            // Request external data if needed for evolution logic.
            requestExternalDataForEvolution(_contentId, rule.ruleDetails); // ruleDetails might be the data query.
            // Evolution will be completed in `fulfillExternalDataRequest` callback.
        } else if (rule.evolutionType == EvolutionType.COMMUNITY_VOTE_BASED) {
            // Example: Evolution triggered after a community vote (separate voting mechanism needed).
            // Placeholder - assume a function `isCommunityVotePassed(_contentId)` exists.
            if (_isCommunityVotePassed(_contentId)) { // Placeholder function
                _performCommunityVoteBasedEvolution(_contentId, currentState, rule);
            }
        } else if (rule.evolutionType == EvolutionType.EXTERNAL_EVENT_BASED) {
            // Example: Evolution triggered by another on-chain event (e.g., a specific token transfer).
            // Logic to detect external event and trigger evolution needs to be implemented (event listeners, etc.).
            // Placeholder - assume a function `isExternalEventOccurred(_contentId)` exists.
            if (_isExternalEventOccurred(_contentId)) { // Placeholder function
                 _performExternalEventBasedEvolution(_contentId, currentState, rule);
            }
        }
        // Add more evolution types here.
    }

    /// @notice Checks the current evolution state of a content piece.
    /// @param _contentId ID of the content.
    /// @return ContentEvolutionState struct detailing the current state.
    function getContentEvolutionState(uint256 _contentId) external view whenNotPaused returns (ContentEvolutionState memory) {
        require(contentEvolutionStates[_contentId].contentId != 0, "Content not found.");
        return contentEvolutionStates[_contentId];
    }

    /// @notice Sets or updates the evolution rule for a content piece (admin/creator function).
    /// @param _contentId ID of the content.
    /// @param _rule EvolutionRule struct defining the rule.
    function setContentEvolutionRule(uint256 _contentId, EvolutionRule memory _rule) external whenNotPaused {
        require(contentRegistry[_contentId].creator == msg.sender || msg.sender == admin, "Only creator or admin can set evolution rule.");
        contentEvolutionRules[_contentId] = _rule;
        contentEvolutionRules[_contentId].lastEvolutionTimestamp = block.timestamp; // Initialize timestamp
        emit EvolutionRuleSet(_contentId, _rule.evolutionType, _rule.ruleDetails);
    }

    /// @notice Retrieves the evolution rule for a content piece.
    /// @param _contentId ID of the content.
    /// @return EvolutionRule struct.
    function getContentEvolutionRule(uint256 _contentId) external view whenNotPaused returns (EvolutionRule memory) {
        return contentEvolutionRules[_contentId];
    }


    // -------- II. Community Interaction & Governance --------

    /// @notice Allows users to interact with content (e.g., like, comment, vote).
    /// @param _contentId ID of the content.
    /// @param _interaction Type of interaction (enum InteractionType).
    function interactWithContent(uint256 _contentId, InteractionType _interaction) external whenNotPaused {
        contentInteractionCounts[_contentId][_interaction]++;
        emit ContentInteractionRecorded(_contentId, msg.sender, _interaction);

        // Example: Trigger interaction-based evolution after enough interactions.
        if (contentEvolutionRules[_contentId].evolutionType == EvolutionType.INTERACTION_BASED) {
            evolveContent(_contentId); // Check if interaction triggers evolution.
        }
    }

    /// @notice Gets the count of specific interactions for content.
    /// @param _contentId ID of the content.
    /// @param _interaction Type of interaction (enum InteractionType).
    /// @return Interaction count.
    function getContentInteractionCount(uint256 _contentId, InteractionType _interaction) external view whenNotPaused returns (uint256) {
        return contentInteractionCounts[_contentId][_interaction];
    }

    /// @notice Users can propose changes to content evolution parameters.
    /// @param _contentId ID of the content to modify.
    /// @param _parameterName Name of the parameter to change.
    /// @param _newValue New value for the parameter.
    function proposeEvolutionParameterChange(uint256 _contentId, string memory _parameterName, string memory _newValue) external whenNotPaused {
        require(contentRegistry[_contentId].id != 0, "Content not found.");
        uint256 proposalId = nextProposalId++;
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            proposalId: proposalId,
            contentId: _contentId,
            proposer: msg.sender,
            parameterName: _parameterName,
            newValue: _newValue,
            votingDeadline: block.timestamp + 7 days, // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit ParameterChangeProposed(proposalId, _contentId, msg.sender, _parameterName, _newValue);
    }

    /// @notice Community members can vote on parameter change proposals.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(parameterChangeProposals[_proposalId].proposalId != 0, "Proposal not found.");
        require(block.timestamp < parameterChangeProposals[_proposalId].votingDeadline, "Voting deadline expired.");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted.");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            parameterChangeProposals[_proposalId].yesVotes++;
        } else {
            parameterChangeProposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes approved parameter changes after voting (governance mechanism).
    /// @param _proposalId ID of the proposal to execute.
    function executeParameterChange(uint256 _proposalId) external whenNotPaused {
        require(parameterChangeProposals[_proposalId].proposalId != 0, "Proposal not found.");
        require(block.timestamp >= parameterChangeProposals[_proposalId].votingDeadline, "Voting not finished.");
        require(!parameterChangeProposals[_proposalId].executed, "Proposal already executed.");
        require(parameterChangeProposals[_proposalId].yesVotes > parameterChangeProposals[_proposalId].noVotes, "Proposal not approved.");

        // Example: Assume 'ruleDetails' is a JSON string, and we are updating a specific parameter within it.
        EvolutionRule storage rule = contentEvolutionRules[parameterChangeProposals[_proposalId].contentId];
        string memory updatedRuleDetails = _updateRuleDetailsParameter(rule.ruleDetails, parameterChangeProposals[_proposalId].parameterName, parameterChangeProposals[_proposalId].newValue); // Placeholder function
        rule.ruleDetails = updatedRuleDetails;

        parameterChangeProposals[_proposalId].executed = true;
        emit ParameterChangeExecuted(_proposalId, parameterChangeProposals[_proposalId].contentId, parameterChangeProposals[_proposalId].parameterName, parameterChangeProposals[_proposalId].newValue);
    }


    // -------- III. Oracle Integration & External Data --------

    /// @notice Sets the address of the trusted oracle (admin function).
    /// @param _oracleAddress Address of the oracle contract or account.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /// @notice Requests data from an oracle to influence content evolution.
    /// @param _contentId ID of the content requiring external data.
    /// @param _dataQuery Query string for the oracle (e.g., API endpoint, data path).
    function requestExternalDataForEvolution(uint256 _contentId, string memory _dataQuery) internal {
        require(oracleAddress != address(0), "Oracle address not set.");
        // In a real implementation, you would use an oracle service like Chainlink, Band Protocol, or similar to make a request.
        // This is a simplified example.
        // Placeholder: Assume a function `oracleService.requestData(dataQuery, this.fulfillExternalDataRequest.selector, _contentId, _dataQuery)`
        // exists in a hypothetical `oracleService` contract at `oracleAddress`.
        // For simplicity in this example, we'll just emit an event and assume an off-chain oracle listener will call `fulfillExternalDataRequest`.

        emit ExternalDataRequested(_contentId, _dataQuery);
        // In a real application, you would typically use a proper oracle library to make a request.
    }


    /// @notice Oracle callback function to provide data.
    /// @param _contentId ID of the content for which data is provided.
    /// @param _dataQuery Original data query.
    /// @param _dataValue Data value returned by the oracle.
    function fulfillExternalDataRequest(uint256 _contentId, string memory _dataQuery, string memory _dataValue) external onlyOracle {
        require(contentRegistry[_contentId].id != 0, "Content not found.");
        require(contentEvolutionRules[_contentId].evolutionType == EvolutionType.ORACLE_BASED, "Evolution type is not oracle-based.");

        emit ExternalDataFulfilled(_contentId, _dataQuery, _dataValue);

        // Process the data value and trigger content evolution.
        _performOracleBasedEvolution(_contentId, contentEvolutionStates[_contentId], contentEvolutionRules[_contentId], _dataValue);
    }


    // -------- IV. Monetization & Creator Economy --------

    /// @notice Allows creators to set a price for accessing premium content layers or features.
    /// @param _contentId ID of the content to price.
    /// @param _price Price in Wei. Set to 0 for free access.
    function setContentPricing(uint256 _contentId, uint256 _price) external whenNotPaused {
        require(contentRegistry[_contentId].creator == msg.sender, "Only creator can set price.");
        contentPrices[_contentId] = _price;
        emit ContentPriceSet(_contentId, _price);
    }

    /// @notice Users can purchase access to premium content.
    /// @param _contentId ID of the content to access.
    function purchaseContentAccess(uint256 _contentId) external payable whenNotPaused {
        uint256 price = contentPrices[_contentId];
        require(price > 0, "Content is free.");
        require(msg.value >= price, "Insufficient payment.");
        require(!contentAccessPurchased[_contentId][msg.sender], "Access already purchased.");

        contentAccessPurchased[_contentId][msg.sender] = true;

        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 creatorShare = price - platformFee;

        creatorEarnings[contentRegistry[_contentId].creator] += creatorShare;
        payable(admin).transfer(platformFee); // Platform fee goes to admin.

        emit ContentAccessPurchased(_contentId, msg.sender, price);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price); // Return excess payment.
        }
    }

    /// @notice Creators can withdraw their earnings.
    function withdrawCreatorEarnings() external whenNotPaused {
        uint256 earnings = creatorEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");

        creatorEarnings[msg.sender] = 0;
        payable(msg.sender).transfer(earnings);
        emit CreatorEarningsWithdrawn(msg.sender, earnings);
    }

    /// @notice Sets the platform fee percentage on content purchases (admin function).
    /// @param _feePercentage Fee percentage (e.g., 5 for 5%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }


    // -------- V. Utility & Admin Functions --------

    /// @notice Pauses core contract functionalities (admin function).
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Resumes contract functionalities (admin function).
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Changes the contract administrator (admin function).
    /// @param _newAdmin Address of the new administrator.
    function setAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Invalid admin address.");
        emit AdminChanged(_newAdmin);
        admin = _newAdmin;
    }

    /// @notice Retrieves the contract's ETH balance.
    function getContractBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    /// @notice Admin function to recover accidentally sent tokens.
    /// @param _tokenAddress Address of the ERC-20 token. Use address(0) for ETH.
    /// @param _recipient Address to receive the recovered tokens.
    /// @param _amount Amount of tokens to recover.
    function recoverStuckTokens(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address.");
        if (_tokenAddress == address(0)) {
            payable(_recipient).transfer(_amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            uint256 contractBalance = token.balanceOf(address(this));
            require(_amount <= contractBalance, "Insufficient token balance in contract.");
            token.transfer(_recipient, _amount);
        }
        emit TokensRecovered(_tokenAddress, _recipient, _amount);
    }


    // -------- Internal Helper Functions (Examples - Need to be implemented based on specific evolution logic) --------

    function _performTimeBasedEvolution(uint256 _contentId, ContentEvolutionState memory _currentState, EvolutionRule memory _rule) internal {
        // Logic for time-based evolution. Examples:
        // - Change content URI to a new version based on time.
        // - Update metadata to reflect the new time-based state.
        string memory newContentURI = _determineNewContentURI(_contentId, _currentState.currentEvolutionStage + 1, _rule.ruleDetails, "time"); // Placeholder function
        contentEvolutionStates[_contentId].currentEvolutionStage++;
        contentEvolutionStates[_contentId].currentContentURI = newContentURI;
        contentEvolutionStates[_contentId].evolutionStateDetails = "Evolved based on time.";
        contentEvolutionStates[_contentId].lastStateUpdateTimestamp = block.timestamp;
        contentEvolutionRules[_contentId].lastEvolutionTimestamp = block.timestamp; // Update last evolution time
        emit ContentEvolved(_contentId, contentEvolutionStates[_contentId].currentEvolutionStage, newContentURI);
    }

    function _performInteractionBasedEvolution(uint256 _contentId, ContentEvolutionState memory _currentState, EvolutionRule memory _rule) internal {
        // Logic for interaction-based evolution. Examples:
        // - Change content based on reaching a certain number of likes/votes.
        // - Unlock new features or layers of content.
        string memory newContentURI = _determineNewContentURI(_contentId, _currentState.currentEvolutionStage + 1, _rule.ruleDetails, "interaction"); // Placeholder function
        contentEvolutionStates[_contentId].currentEvolutionStage++;
        contentEvolutionStates[_contentId].currentContentURI = newContentURI;
        contentEvolutionStates[_contentId].evolutionStateDetails = "Evolved based on interactions.";
        contentEvolutionStates[_contentId].lastStateUpdateTimestamp = block.timestamp;
        contentEvolutionRules[_contentId].lastEvolutionTimestamp = block.timestamp; // Update last evolution time
        emit ContentEvolved(_contentId, contentEvolutionStates[_contentId].currentEvolutionStage, newContentURI);
    }

    function _performOracleBasedEvolution(uint256 _contentId, ContentEvolutionState memory _currentState, EvolutionRule memory _rule, string memory _oracleData) internal {
        // Logic for oracle-based evolution. Examples:
        // - Change content based on weather data, stock prices, random numbers, etc. from oracle.
        string memory newContentURI = _determineNewContentURI(_contentId, _currentState.currentEvolutionStage + 1, _rule.ruleDetails, "oracle", _oracleData); // Placeholder function
        contentEvolutionStates[_contentId].currentEvolutionStage++;
        contentEvolutionStates[_contentId].currentContentURI = newContentURI;
        contentEvolutionStates[_contentId].evolutionStateDetails = "Evolved based on oracle data: " + _oracleData;
        contentEvolutionStates[_contentId].lastStateUpdateTimestamp = block.timestamp;
        contentEvolutionRules[_contentId].lastEvolutionTimestamp = block.timestamp; // Update last evolution time
        emit ContentEvolved(_contentId, contentEvolutionStates[_contentId].currentEvolutionStage, newContentURI);
    }

    function _performCommunityVoteBasedEvolution(uint256 _contentId, ContentEvolutionState memory _currentState, EvolutionRule memory _rule) internal {
        // Logic for community vote-based evolution.
        string memory newContentURI = _determineNewContentURI(_contentId, _currentState.currentEvolutionStage + 1, _rule.ruleDetails, "vote"); // Placeholder function
        contentEvolutionStates[_contentId].currentEvolutionStage++;
        contentEvolutionStates[_contentId].currentContentURI = newContentURI;
        contentEvolutionStates[_contentId].evolutionStateDetails = "Evolved based on community vote.";
        contentEvolutionStates[_contentId].lastStateUpdateTimestamp = block.timestamp;
        contentEvolutionRules[_contentId].lastEvolutionTimestamp = block.timestamp; // Update last evolution time
        emit ContentEvolved(_contentId, contentEvolutionStates[_contentId].currentEvolutionStage, newContentURI);
    }

    function _performExternalEventBasedEvolution(uint256 _contentId, ContentEvolutionState memory _currentState, EvolutionRule memory _rule) internal {
        // Logic for external event-based evolution.
        string memory newContentURI = _determineNewContentURI(_contentId, _currentState.currentEvolutionStage + 1, _rule.ruleDetails, "event"); // Placeholder function
        contentEvolutionStates[_contentId].currentEvolutionStage++;
        contentEvolutionStates[_contentId].currentContentURI = newContentURI;
        contentEvolutionStates[_contentId].evolutionStateDetails = "Evolved based on external event.";
        contentEvolutionStates[_contentId].lastStateUpdateTimestamp = block.timestamp;
        contentEvolutionRules[_contentId].lastEvolutionTimestamp = block.timestamp; // Update last evolution time
        emit ContentEvolved(_contentId, contentEvolutionStates[_contentId].currentEvolutionStage, newContentURI);
    }


    // -------- Placeholder Functions - Implement based on specific logic --------

    function _parseInteractionThreshold(string memory _ruleDetails) internal pure returns (uint256) {
        // Example: Parse interaction threshold from ruleDetails (e.g., from JSON string)
        // For simplicity, return a fixed value for now.
        return 1000;
    }

    function _isCommunityVotePassed(uint256 _contentId) internal pure returns (bool) {
        // Placeholder: Logic to check if a community vote for evolution has passed.
        // This would likely involve a separate voting mechanism outside of this simplified example.
        return true; // Example: Assume vote always passes for now.
    }

    function _isExternalEventOccurred(uint256 _contentId) internal pure returns (bool) {
        // Placeholder: Logic to check if an external on-chain event has occurred that should trigger evolution.
        // This would require event listeners or other mechanisms to detect external events.
        return false; // Example: Assume event has not occurred yet.
    }

    function _determineNewContentURI(uint256 _contentId, uint256 _nextStage, string memory _ruleDetails, string memory _evolutionType, string memory _oracleData) internal pure returns (string memory) {
        // Placeholder: Logic to determine the new content URI based on evolution type, rules, and potentially oracle data.
        // This would be highly specific to the desired evolution behavior.
        // For now, return a generic URI indicating evolution stage.
        if (keccak256(abi.encodePacked(_evolutionType)) == keccak256(abi.encodePacked("oracle"))) {
            return string(abi.encodePacked("ipfs://evolved_content_", Strings.toString(_contentId), "_stage_", Strings.toString(_nextStage), "_oracle_", _oracleData));
        } else {
             return string(abi.encodePacked("ipfs://evolved_content_", Strings.toString(_contentId), "_stage_", Strings.toString(_nextStage), "_type_", _evolutionType));
        }
    }

    function _determineNewContentURI(uint256 _contentId, uint256 _nextStage, string memory _ruleDetails, string memory _evolutionType) internal pure returns (string memory) {
         return _determineNewContentURI(_contentId, _nextStage, _ruleDetails, _evolutionType, "");
    }


    function _updateRuleDetailsParameter(string memory _ruleDetails, string memory _parameterName, string memory _newValue) internal pure returns (string memory) {
        // Placeholder: Logic to update a parameter within the ruleDetails string (e.g., JSON parsing and modification).
        // For now, return the original ruleDetails string (no actual update).
        // In a real implementation, you would need to parse and modify the JSON or other rule format.
        return _ruleDetails;
    }
}

// --- Interfaces ---
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
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
}
```