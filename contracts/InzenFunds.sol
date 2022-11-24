// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/AggregatorV3Interface.sol';
import './interfaces/AggregationRouterV5Interface.sol';

contract InzenFunds is AccessControlEnumerable, ERC20Permit, ReentrancyGuard {
    using SafeERC20 for ERC20;

    bytes32 public constant PORTFOLIO_ENGINEER_ROLE = keccak256('PORTFOLIO_ENGINEER_ROLE');

    struct Assets {
        ERC20 token;
        AggregatorV3Interface priceFeed;
        uint256 amount;
        uint256 weight;
    }

    Assets[] public portfolio;
    mapping(ERC20 => uint256) private tokenIdx;
    AggregationRouterV5Interface public router;
    ERC20 public baseToken;

    event Deposit(address indexed user, uint256 baseAmount, uint256 mintAmount);
    event Withdraw(address indexed user, uint256 burnAmount);
    event Rebalance(ERC20 indexed fromToken, ERC20 indexed toToken, uint256 fromAmount, uint256 toAmount);
    event Reconfigure(uint256[] weights);
    event AddAsset(ERC20 indexed token, AggregatorV3Interface priceFeed);

    constructor(
        string memory _name,
        ERC20 _baseToken,
        AggregationRouterV5Interface _router,
        Assets[] memory _portfolio
    ) public ERC20(_name, 'IZF') ERC20Permit(_name) {
        baseToken = _baseToken;
        router = _router;

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < _portfolio.length; i++) {
            require(tokenIdx[_portfolio[i].token] == 0, 'Duplicated asset');
            require(baseToken != _portfolio[i].token && _portfolio[i].amount == 0, 'Invalid asset');
            portfolio.push(_portfolio[i]);
            tokenIdx[_portfolio[i].token] = portfolio.length;
            totalWeight += _portfolio[i].weight;
        }
        require(totalWeight == 100, 'Invalid asset weights');

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PORTFOLIO_ENGINEER_ROLE, _msgSender());
    }

    function deposit(uint256 _amount, bytes[] calldata _swapdata) external nonReentrant {
        require(_swapdata.length == portfolio.length, 'Invalid swap data');

        uint256 oldValue = totalValue();
        baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        baseToken.safeApprove(address(router), _amount);

        uint256 totalSpent = 0;
        address executor;
        AggregationRouterV5Interface.SwapDescription memory desc;
        bytes memory permit;
        bytes memory data;
        for (uint256 i = 0; i < _swapdata.length; i++) {
            (executor, desc, permit, data) = abi.decode(
                _swapdata[i][4:],
                (address, AggregationRouterV5Interface.SwapDescription, bytes, bytes)
            );
            require(desc.dstReceiver == address(this), 'Invalid receiver');
            require(desc.srcToken == baseToken && desc.dstToken == portfolio[i].token, 'Invalid swap token');
            require(desc.amount == (portfolio[i].weight * _amount) / 100, 'Invalid swap amount');
            (uint256 returnAmount, uint256 spentAmount) = router.swap(executor, desc, permit, data);
            portfolio[i].amount += returnAmount;
            totalSpent += spentAmount;
        }

        require(totalSpent <= _amount, 'Spent more than deposit');
        if (totalSpent < _amount) {
            baseToken.safeTransfer(msg.sender, _amount - totalSpent);
        }

        uint256 newValue = totalValue();
        require(oldValue < newValue, 'New value can not less than old value');
        uint256 mintAmount = newValue * 10**12;
        if (oldValue > 0) {
            mintAmount = ((newValue - oldValue) * totalSupply()) / oldValue;
        }
        _mint(msg.sender, mintAmount);
        emit Deposit(msg.sender, totalSpent, mintAmount);
    }

    function withdraw(uint256 _burnAmount) external nonReentrant {
        for (uint256 i = 0; i < portfolio.length; i++) {
            uint256 returnAmount = (portfolio[i].amount * _burnAmount) / totalSupply();
            portfolio[i].amount -= returnAmount;
            portfolio[i].token.safeTransfer(msg.sender, returnAmount);
        }
        _burn(msg.sender, _burnAmount);
        emit Withdraw(msg.sender, _burnAmount);
    }

    function rebalance(bytes[] calldata _swapdata) external onlyRole(PORTFOLIO_ENGINEER_ROLE) nonReentrant {
        address executor;
        AggregationRouterV5Interface.SwapDescription memory desc;
        bytes memory permit;
        bytes memory data;
        for (uint256 i = 0; i < _swapdata.length; i++) {
            (executor, desc, permit, data) = abi.decode(
                _swapdata[i][4:],
                (address, AggregationRouterV5Interface.SwapDescription, bytes, bytes)
            );
            require(desc.dstReceiver == address(this), 'Invalid receiver');
            require(tokenIdx[desc.srcToken] != 0 && tokenIdx[desc.dstToken] != 0, 'Invalid swap token');
            desc.srcToken.safeApprove(address(router), desc.amount);
            (uint256 returnAmount, uint256 spentAmount) = router.swap(executor, desc, permit, data);
            portfolio[tokenIdx[desc.srcToken] - 1].amount -= spentAmount;
            portfolio[tokenIdx[desc.dstToken] - 1].amount += returnAmount;
            emit Rebalance(desc.srcToken, desc.dstToken, spentAmount, returnAmount);
        }
    }

    function reconfigure(uint256[] memory _weights) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_weights.length == portfolio.length, 'Invalid length');
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < _weights.length; i++) {
            portfolio[i].weight = _weights[i];
            totalWeight += _weights[i];
        }
        require(totalWeight == 100, 'Invalid asset weights');
        emit Reconfigure(_weights);
    }

    function addAsset(ERC20 _token, AggregatorV3Interface _priceFeed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenIdx[_token] == 0, 'Duplicated asset');
        portfolio.push(Assets(_token, _priceFeed, 0, 0));
        tokenIdx[_token] = portfolio.length;
        emit AddAsset(_token, _priceFeed);
    }

    function overview()
        external
        view
        returns (
            string memory fundName,
            uint256 usdValue,
            uint256 tokenSupply,
            Assets[] memory assets
        )
    {
        fundName = name();
        usdValue = totalValue();
        tokenSupply = totalSupply();
        assets = new Assets[](portfolio.length);
        for (uint256 i = 0; i < portfolio.length; i++) {
            assets[i] = portfolio[i];
        }
    }

    function userInfo(address user)
        external
        view
        returns (
            uint256 usdValue,
            uint256 tokenBalance,
            bool isPorfolioEngineer
        )
    {
        tokenBalance = balanceOf(user);
        if (tokenBalance > 0) {
            usdValue = (totalValue() * tokenBalance) / totalSupply();
        }
        isPorfolioEngineer = hasRole(PORTFOLIO_ENGINEER_ROLE, user);
    }

    function withdrawToken(ERC20 _token, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _token.safeTransfer(msg.sender, _amount);
    }

    function totalValue() public view returns (uint256 total) {
        for (uint256 i = 0; i < portfolio.length; i++) {
            if (portfolio[i].amount == 0) continue;
            (, int256 answer, , , ) = portfolio[i].priceFeed.latestRoundData();
            uint8 priceDecimals = portfolio[i].priceFeed.decimals();
            uint8 tokenDecimals = portfolio[i].token.decimals();
            total += (uint256(answer) * portfolio[i].amount) / 10**(priceDecimals + tokenDecimals - 6);
        }
    }
}
