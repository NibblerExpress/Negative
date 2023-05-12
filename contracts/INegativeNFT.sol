// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface INegativeNFT is IERC1155 {
    function units() external view returns (int8);

    function totalSupply() external view returns (uint256);

    function setURI(string memory uri_) external;
    
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

        function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;   

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function lock (
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external returns (uint256);

    function unlock (
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external returns (uint256);
}