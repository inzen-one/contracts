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

    constructor(
        string memory _name,
        ERC20Votes _tokenAddress,
        uint256 _period,
        uint256 _quorum
    ) public Governor(_name) GovernorVotes(_tokenAddress) GovernorVotesQuorumFraction(_quorum) {
        period = _period;
        _defaultTargets.push(address(_tokenAddress));
        _defaultValues.push(0);
    }

    function votingDelay() public override pure returns (uint256) {
        return 0;
    }

    function votingPeriod() public override view returns (uint256) {
        return period;
    }

    function proposeNewPortfolioEngineer(address user) public returns (uint256) {
        require(!AccessControl(address(token)).hasRole(PORTFOLIO_ENGINEER_ROLE, user), 'Role granted');
        return defaultPropose(abi.encodeWithSelector(AccessControl.grantRole.selector, PORTFOLIO_ENGINEER_ROLE, user));
    }

    function executeNewPortfolioEngineer(address user) public returns (uint256) {
        return defaultExecute(abi.encodeWithSelector(AccessControl.grantRole.selector, PORTFOLIO_ENGINEER_ROLE, user));
    }

    function proposeRemovePortfolioEngineer(address user) public returns (uint256) {
        require(AccessControl(address(token)).hasRole(PORTFOLIO_ENGINEER_ROLE, user), 'Role not granted');
        return defaultPropose(abi.encodeWithSelector(AccessControl.revokeRole.selector, PORTFOLIO_ENGINEER_ROLE, user));
    }

    function executeRemovePortfolioEngineer(address user) public returns (uint256) {
        return defaultExecute(abi.encodeWithSelector(AccessControl.revokeRole.selector, PORTFOLIO_ENGINEER_ROLE, user));
    }

    function proposeReconfigure(uint256[] memory _weights) public returns (uint256) {
        return defaultPropose(abi.encodeWithSelector(InzenFunds.reconfigure.selector, _weights));
    }

    function executeReconfigure(uint256[] memory _weights) public returns (uint256) {
        return defaultExecute(abi.encodeWithSelector(InzenFunds.reconfigure.selector, _weights));
    }

    function proposeNewAsset(ERC20 _token, AggregatorV3Interface _priceFeed) public returns (uint256) {
        return defaultPropose(abi.encodeWithSelector(InzenFunds.addAsset.selector, _token, _priceFeed));
    }

    function executeNewAsset(ERC20 _token, AggregatorV3Interface _priceFeed) public returns (uint256) {
        return defaultExecute(abi.encodeWithSelector(InzenFunds.addAsset.selector, _token, _priceFeed));
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
