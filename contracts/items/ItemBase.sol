// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./libs/ComplexId.sol";

abstract contract ItemBase is ERC1155Upgradeable {
    using ComplexId for uint256;

    function getItemType(uint256 item) public pure returns (uint64) {
        return item.getPart(1);
    }

    function getItemSubtype(uint256 item) public pure returns (uint64) {
        return item.getPart(2);
    }

    function getItemId(uint256 item) public pure returns (uint64) {
        return item.getPart(3);
    }

    function getItemExtra(uint256 item) public pure returns (uint64) {
        return item.getPart(4);
    }

    function _mintItem(
        address to,
        uint64 type_,
        uint64 subtype,
        uint64 itemId,
        uint64 extra
    ) internal {
        uint complexId = ComplexId.fromParts(type_, subtype, itemId, extra);

        _mint(to, complexId, 1, "");
    }

    function _mintItems(
        address to,
        uint amount,
        uint64 type_,
        uint64 subtype,
        uint64 itemId,
        uint64 extra
    ) internal {
        uint complexId = ComplexId.fromParts(type_, subtype, itemId, extra);

        _mint(to, complexId, amount, "");
    }
}