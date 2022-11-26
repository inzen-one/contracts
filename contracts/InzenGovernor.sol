// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol';
import './extensions/EasyGovernor.sol';
import './InzenFunds.sol';

contract InzenGovernor is GovernorVotesQuorumFraction, GovernorCountingSimple, EasyGovernor {
    bytes32 public constant PORTFOLIO_ENGINEER_ROLE = keccak256('PORTFOLIO_ENGINEER_ROLE');

    uint256 public period;

    address[] private _defaultTargets;
    uint256[] private _defaultValues;

    event NewPortfolioEngineer(uint256 indexed proposalId, EasyGovernor.EventState state, address user);
    event RemovePortfolioEngineer(uint256 indexed proposalId, EasyGovernor.EventState state, address user);
    event Reconfigure(uint256 indexed proposalId, EasyGovernor.EventState state, uint256[] weights);
    event NewAsset(
        uint256 indexed proposalId,
        EasyGovernor.EventState state,
        ERC20 token,
        AggregatorV3Interface priceFeed
    );
    event UpdateRebalanceBonus(uint256 indexed proposalId, EasyGovernor.EventState state, uint256 bonus);
    event UpdateMinRebalanceInterval(uint256 indexed proposalId, EasyGovernor.EventState state, uint256 interval);

    constructor(
        string memory _name,
        ERC20Votes _tokenAddress,
        uint256 _period,
        uint256 _quorum
    ) Governor(_name) GovernorVotes(_tokenAddress) GovernorVotesQuorumFraction(_quorum) {
        period = _period;
        _defaultTargets.push(address(_tokenAddress));
        _defaultValues.push(0);
    }

    function proposalTopics() external override pure returns (bytes32[] memory topics) {
        topics = new bytes32[](6);
        topics[0] = NewPortfolioEngineer.selector;
        topics[1] = RemovePortfolioEngineer.selector;
        topics[2] = Reconfigure.selector;
        topics[3] = NewAsset.selector;
        topics[4] = UpdateRebalanceBonus.selector;
        topics[5] = UpdateMinRebalanceInterval.selector;
        return topics;
    }

    function votingDelay() public override pure returns (uint256) {
        return 0;
    }

    function votingPeriod() public override view returns (uint256) {
        return period;
    }

    function proposeNewPortfolioEngineer(address _user) public returns (uint256 proposalId) {
        require(!AccessControl(address(token)).hasRole(PORTFOLIO_ENGINEER_ROLE, _user), 'Role granted');
        proposalId = defaultPropose(
            abi.encodeWithSelector(AccessControl.grantRole.selector, PORTFOLIO_ENGINEER_ROLE, _user)
        );
        emit NewPortfolioEngineer(proposalId, EventState.Propose, _user);
    }

    function executeNewPortfolioEngineer(address _user) public returns (uint256 proposalId) {
        proposalId = defaultExecute(
            abi.encodeWithSelector(AccessControl.grantRole.selector, PORTFOLIO_ENGINEER_ROLE, _user)
        );
        emit NewPortfolioEngineer(proposalId, EventState.Execute, _user);
    }

    function proposeRemovePortfolioEngineer(address _user) public returns (uint256 proposalId) {
        require(AccessControl(address(token)).hasRole(PORTFOLIO_ENGINEER_ROLE, _user), 'Role not granted');
        proposalId = defaultPropose(
            abi.encodeWithSelector(AccessControl.revokeRole.selector, PORTFOLIO_ENGINEER_ROLE, _user)
        );
        emit RemovePortfolioEngineer(proposalId, EventState.Propose, _user);
    }

    function executeRemovePortfolioEngineer(address _user) public returns (uint256 proposalId) {
        proposalId = defaultExecute(
            abi.encodeWithSelector(AccessControl.revokeRole.selector, PORTFOLIO_ENGINEER_ROLE, _user)
        );
        emit RemovePortfolioEngineer(proposalId, EventState.Execute, _user);
    }

    function proposeReconfigure(uint256[] memory _weights) public returns (uint256 proposalId) {
        proposalId = defaultPropose(abi.encodeWithSelector(InzenFunds.reconfigure.selector, _weights));
        emit Reconfigure(proposalId, EventState.Propose, _weights);
    }

    function executeReconfigure(uint256[] memory _weights) public returns (uint256 proposalId) {
        proposalId = defaultExecute(abi.encodeWithSelector(InzenFunds.reconfigure.selector, _weights));
        emit Reconfigure(proposalId, EventState.Execute, _weights);
    }

    function proposeNewAsset(ERC20 _token, AggregatorV3Interface _priceFeed) public returns (uint256 proposalId) {
        proposalId = defaultPropose(abi.encodeWithSelector(InzenFunds.addAsset.selector, _token, _priceFeed));
        emit NewAsset(proposalId, EventState.Propose, _token, _priceFeed);
    }

    function executeNewAsset(ERC20 _token, AggregatorV3Interface _priceFeed) public returns (uint256 proposalId) {
        proposalId = defaultExecute(abi.encodeWithSelector(InzenFunds.addAsset.selector, _token, _priceFeed));
        emit NewAsset(proposalId, EventState.Execute, _token, _priceFeed);
    }

    function proposeUpdateRebalanceBonus(uint256 _rebalanceBonus) public returns (uint256 proposalId) {
        proposalId = defaultPropose(abi.encodeWithSelector(InzenFunds.updateRebalanceBonus.selector, _rebalanceBonus));
        emit UpdateRebalanceBonus(proposalId, EventState.Propose, _rebalanceBonus);
    }

    function executeUpdateRebalanceBonus(uint256 _rebalanceBonus) public returns (uint256 proposalId) {
        proposalId = defaultExecute(abi.encodeWithSelector(InzenFunds.updateRebalanceBonus.selector, _rebalanceBonus));
        emit UpdateRebalanceBonus(proposalId, EventState.Execute, _rebalanceBonus);
    }

    function proposeUpdateMinRebalanceInterval(uint256 _interval) public returns (uint256 proposalId) {
        proposalId = defaultPropose(abi.encodeWithSelector(InzenFunds.updateMinRebalanceInterval.selector, _interval));
        emit UpdateMinRebalanceInterval(proposalId, EventState.Propose, _interval);
    }

    function executeUpdateMinRebalanceInterval(uint256 _interval) public returns (uint256 proposalId) {
        proposalId = defaultExecute(abi.encodeWithSelector(InzenFunds.updateMinRebalanceInterval.selector, _interval));
        emit UpdateMinRebalanceInterval(proposalId, EventState.Execute, _interval);
    }

    function defaultPropose(bytes memory data) internal returns (uint256) {
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = data;
        return propose(_defaultTargets, _defaultValues, calldatas, '');
    }

    function defaultExecute(bytes memory data) internal returns (uint256) {
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = data;
        return execute(_defaultTargets, _defaultValues, calldatas, keccak256(bytes('')));
    }

    function supportsInterface(bytes4 interfaceId) public virtual override(Governor, EasyGovernor) view returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
