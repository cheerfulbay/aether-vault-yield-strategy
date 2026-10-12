// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title AetherYieldStrategyVault
 * @author cheerfulbay
 * @notice ERC-4626 Tokenized Yield Strategy Vault for EVM-compatible ecosystems.
 *         Allows users to deposit underlying assets and receive yield-bearing shares.
 */
contract AetherYieldStrategyVault {
    IERC20 public immutable asset;
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    uint256 public performanceFeeBps = 100; // 1.00%
    uint256 public constant MAX_FEE_BPS = 1000; // 10.00%

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    error ZeroAssets();
    error ZeroShares();
    error Unauthorized();
    error FeeTooHigh();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _asset, string memory _name, string memory _symbol) {
        asset = IERC20(_asset);
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        if (assets == 0) revert ZeroAssets();
        shares = convertToShares(assets);
        if (shares == 0) revert ZeroShares();

        _mint(receiver, shares);
        bool success = asset.transferFrom(msg.sender, address(this), assets);
        require(success, "Asset transfer failed");

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address _owner) external returns (uint256 assets) {
        if (shares == 0) revert ZeroShares();
        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= shares, "Insufficient allowance");
                allowance[_owner][msg.sender] = allowed - shares;
            }
        }

        assets = convertToAssets(shares);
        if (assets == 0) revert ZeroAssets();

        _burn(_owner, shares);
        bool success = asset.transfer(receiver, assets);
        require(success, "Asset transfer failed");

        emit Withdraw(msg.sender, receiver, _owner, assets, shares);
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
