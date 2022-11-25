// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol';
import './InzenFunds.sol';

contract InzenGovernor is GovernorVotesQuorumFraction, GovernorCountingSimple {
    bytes32 public constant PORTFOLIO_ENGINEER_ROLE = keccak256('PORTFOLIO_ENGINEER_ROLE');

    uint256 public period;

    address[] private _defaultTargets;
    uint256[] private _defaultValues;

    event ProposeNewPortfolioEngineer(uint256 indexed proposalId, address user);
    event ExecuteNewPortfolioEngineer(uint256 indexed proposalId, address user);
    event ProposeRemovePortfolioEngineer(uint256 indexed proposalId, address user);
    event ExecuteRemovePortfolioEngineer(uint256 indexed proposalId, address user);
    event ProposeReconfigure(uint256 indexed proposalId, uint256[] weights);
    event ExecuteReconfigure(uint256 indexed proposalId, uint256[] weights);
    event ProposeNewAsset(uint256 indexed proposalId, ERC20 indexed token, AggregatorV3Interface priceFeed);
    event ExecuteNewAsset(uint256 indexed proposalId, ERC20 indexed token, AggregatorV3Interface priceFeed);

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

    function votingDelay() public pure override returns (uint256) {
        return 0;
    }

    function votingPeriod() public view override returns (uint256) {
        return period;
    }

    function proposeNewPortfolioEngineer(address user) public returns (uint256 proposalId) {
        require(!AccessControl(address(token)).hasRole(PORTFOLIO_ENGINEER_ROLE, user), 'Role granted');
        proposalId = defaultPropose(
            abi.encodeWithSelector(AccessControl.grantRole.selector, PORTFOLIO_ENGINEER_ROLE, user)
        );
        emit ProposeNewPortfolioEngineer(proposalId, user);
    }

    function executeNewPortfolioEngineer(address user) public returns (uint256 proposalId) {
        proposalId = defaultExecute(
            abi.encodeWithSelector(AccessControl.grantRole.selector, PORTFOLIO_ENGINEER_ROLE, user)
        );
        emit ExecuteNewPortfolioEngineer(proposalId, user);
    }

    function proposeRemovePortfolioEngineer(address user) public returns (uint256 proposalId) {
        require(AccessControl(address(token)).hasRole(PORTFOLIO_ENGINEER_ROLE, user), 'Role not granted');
        proposalId = defaultPropose(
            abi.encodeWithSelector(AccessControl.revokeRole.selector, PORTFOLIO_ENGINEER_ROLE, user)
        );
        emit ProposeRemovePortfolioEngineer(proposalId, user);
    }

    function executeRemovePortfolioEngineer(address user) public returns (uint256 proposalId) {
        proposalId = defaultExecute(
            abi.encodeWithSelector(AccessControl.revokeRole.selector, PORTFOLIO_ENGINEER_ROLE, user)
        );
        emit ExecuteRemovePortfolioEngineer(proposalId, user);
    }

    function proposeReconfigure(uint256[] memory _weights) public returns (uint256 proposalId) {
        proposalId = defaultPropose(abi.encodeWithSelector(InzenFunds.reconfigure.selector, _weights));
        emit ProposeReconfigure(proposalId, _weights);
    }

    function executeReconfigure(uint256[] memory _weights) public returns (uint256 proposalId) {
        proposalId = defaultExecute(abi.encodeWithSelector(InzenFunds.reconfigure.selector, _weights));
        emit ExecuteReconfigure(proposalId, _weights);
    }

    function proposeNewAsset(ERC20 _token, AggregatorV3Interface _priceFeed) public returns (uint256 proposalId) {
        proposalId = defaultPropose(abi.encodeWithSelector(InzenFunds.addAsset.selector, _token, _priceFeed));
        emit ProposeNewAsset(proposalId, _token, _priceFeed);
    }

    function executeNewAsset(ERC20 _token, AggregatorV3Interface _priceFeed) public returns (uint256 proposalId) {
        proposalId = defaultExecute(abi.encodeWithSelector(InzenFunds.addAsset.selector, _token, _priceFeed));
        emit ExecuteNewAsset(proposalId, _token, _priceFeed);
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
}
