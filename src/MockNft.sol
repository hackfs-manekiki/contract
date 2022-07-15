//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockNFT is ERC721, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        address _admin
    ) ERC721(_name, _symbol) {
        _transferOwnership(_admin);
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
}
