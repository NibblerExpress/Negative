// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./INegativeVault.sol";
import "./INegativeNFT.sol";

contract NegativeNFT is INegativeNFT, ERC1155, Ownable2Step {

    INegativeVault public vault;
    int8 public immutable units;
    uint256 public totalSupply;
    mapping(uint256 => mapping(address => uint256)) public locked;

    error InsufficientUnlocked();
    error InsufficientLocked();
    error OnlyVault();
    error TransferFailed();
    
    modifier onlyVault () {
        if (_msgSender() != address(vault)) {
            revert OnlyVault();
        }
        _;
    }

    constructor(int8 units_, string memory uri_) ERC1155(uri_) {
        units = units_;
    }

    function setVault(INegativeVault vault_) external onlyOwner {
        vault = vault_;
    }
    
    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(INegativeNFT).interfaceId || super.supportsInterface(interfaceId);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {    
        totalSupply += amount;
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external { 
        totalSupply -= amount;
        _burn(from, id, amount);
    }    

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        _burnBatch(from, ids, amounts);
    }

    function lock (
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyVault returns (uint256) {
        uint256 totalLocked;
        
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 previousLock = locked[id][account];
            uint256 amount = amounts[i];
            
            if (amount > _balances[id][account] - previousLock) revert InsufficientUnlocked();

            totalLocked += amount;
            locked[id][account] = previousLock + amount;
        }

        return totalLocked;
    }

    function unlock (
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyVault returns (uint256) {
        uint256 totalUnlocked;
        
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 previousLock = locked[id][account];
            uint256 amount = amounts[i];
            
            if (amount > previousLock) revert InsufficientLocked();

            totalUnlocked += amount;
            locked[id][account] = previousLock - amount;
        }

        return totalUnlocked;
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    )
        internal view
        override(ERC1155)
    {
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                                
               if (amounts[i] > _balances[id][from] - locked[id][from]) revert InsufficientUnlocked();
            }
        }
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 amount = amounts[i];
            
            _balances[ids[i]][to] += amount;
            totalSupply += amount;
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            totalSupply -= amount;
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }
    
    function sweep(IERC20 token, address recipient) external onlyOwner {
        if (!token.transfer(recipient, token.balanceOf(address(this)))) revert TransferFailed();
    }
}