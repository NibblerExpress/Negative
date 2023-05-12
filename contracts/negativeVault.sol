// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "./INegativeVault.sol";
import "./INegativeNFT.sol";

contract NegativeVault is ERC20, INegativeVault {

    INegativeNFT private immutable _asset;
    uint8 constant DECIMALS = 18;
    
    /* Difference between units of asset and
    *  what would be expected by the vault */
    int8 underlyingUnits;
    
    uint256 lockedAssets;

    error NotApproved();
    error ExceededMaxWithdraw();

    /**
     * 
     */
    constructor(
        INegativeNFT asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;
        underlyingUnits = asset_.units();
    }

    /**
     * 
     */
    function decimals() public view virtual override (IERC20Metadata, ERC20) returns (uint8) {
        return DECIMALS;
    }

    /**  */
    function asset() public view returns (address) {
        return address(_asset);
    }

    /**  */
    function totalAssets() public view returns (uint256) {
        return lockedAssets;
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        return assets * 10**(uint8(int8(DECIMALS) - underlyingUnits));
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        return shares / 10**(uint8(int8(DECIMALS) - underlyingUnits));
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public pure returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(
        uint256[] memory ids,
        uint256[] memory amounts,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        if (owner!= _msgSender() && !_asset.isApprovedForAll(owner, _msgSender())) revert NotApproved();

        // slither-disable-next-line reentrancy-no-eth
        uint256 assets = _asset.lock(owner, ids, amounts);

        lockedAssets += assets;

        uint256 shares = previewDeposit(assets);
        _mint(receiver, shares);

        emit Deposit(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256[] memory ids,
        uint256[] memory amounts,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        uint256 assets = _asset.unlock(receiver, ids, amounts);
        
        if (assets > maxWithdraw(owner)) revert ExceededMaxWithdraw();
        
        uint256 shares = previewWithdraw(assets);

        if (_msgSender() != owner) {
            _spendAllowance(owner, _msgSender(), shares);
        }

        lockedAssets -= assets;
        _burn(owner, shares);

        emit Withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }
}