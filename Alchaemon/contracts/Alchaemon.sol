// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AlchemonNft is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    uint256 public constant PRICE = 0.0005 ether;

    event AlchemonMinted(address indexed owner, uint256 indexed tokenId, uint256 generation);
    event AlchemonBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed offspringId);

    constructor() ERC721("Alchemon", "ALCH") Ownable(msg.sender) {}

    function mintGenesis(uint256 _count) public payable {
        require(msg.value >= PRICE * _count, "Not enough ether to purchase NFTs");
        require(_count > 0, "Must mint at least one NFT");
        require(_count <= 10, "Cannot mint more than 10 NFTs at once");

        for (uint256 i = 0; i < _count; i++) {
            uint256 tokenId = _nextTokenId++;
            string memory metadata = generateMetadata(tokenId, 0);
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, metadata);
            emit AlchemonMinted(msg.sender, tokenId, 0);
        }
    }

    function generateMetadata(uint256 tokenId, uint256 generation) public pure returns (string memory) {
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            '<style>.base { fill: white; font-family: serif; font-size: 25px; }</style>',
            '<rect width="100%" height="100%" fill="blue" />',
            '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">',
            '<tspan y="40%" x="50%">Alchemon #',
            Strings.toString(tokenId),
            '</tspan>',
            '<tspan y="50%" x="50%">Generation ',
            Strings.toString(generation),
            '</tspan></text></svg>'
        );

        return string.concat(
            'data:application/json;base64,',
            _toBase64(
                bytes(
                    string.concat(
                        '{"name": "Alchemon #',
                        Strings.toString(tokenId),
                        '", "description": "An in-game monster", "image": "data:image/svg+xml;base64,',
                        _toBase64(bytes(svg)),
                        '", "attributes": [{"trait_type": "Generation", "value": "',
                        Strings.toString(generation),
                        '"}]}'
                    )
                )
            )
        );
    }

    function breed(uint256 parent1Id, uint256 parent2Id) public {
        require(parent1Id != parent2Id, "Parents must be different");
        require(ownerOf(parent1Id) == msg.sender && ownerOf(parent2Id) == msg.sender, 
                "Must own both parents");

        uint256 parent1Gen = _getGeneration(parent1Id);
        uint256 parent2Gen = _getGeneration(parent2Id);
        uint256 newGen = parent1Gen > parent2Gen ? parent1Gen + 1 : parent2Gen + 1;

        uint256 tokenId = _nextTokenId++;
        string memory metadata = generateMetadata(tokenId, newGen);
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadata);

        emit AlchemonBred(parent1Id, parent2Id, tokenId);
        emit AlchemonMinted(msg.sender, tokenId, newGen);
    }

    function _getGeneration(uint256 tokenId) internal view returns (uint256) {
        // Simplified version - in production implement proper JSON parsing
        return tokenId;
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");
    }

    function _toBase64(bytes memory data) internal pure returns (string memory) {
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen);

        assembly {
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return string(result);
    }

    // The following functions are overrides required by Solidity
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}