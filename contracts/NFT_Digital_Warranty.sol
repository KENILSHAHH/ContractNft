//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT_Digital_Warranty is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    Counters.Counter private _itemsSold;

    address payable owner;

    // uint256 listPrice = 0.01 ether;

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        // uint256 price;
        // bool currentlyListed;
        uint256 expiry;
        string serialNo;
    }

    event TokenListedSuccess(
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed,
        uint256 expiry,
        string serialNo
    );

    mapping(uint256 => ListedToken) private idToListedToken;

    constructor() ERC721("NFT_Digital_Warranty", "NFTDW") {
        owner = payable(msg.sender);
    }

    // function updateListPrice(uint256 _listPrice) public payable {
    //     require(owner == msg.sender, "Only owner can update listing price");
    //     listPrice = _listPrice;
    // }

    // function getListPrice() public view returns (uint256) {
    //     return listPrice;
    // }

    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }
    function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }
    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }
    function createToken(string memory tokenURI, string memory serialNo)
        public
        payable
        returns (uint256)
    { 
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createListedToken(newTokenId, serialNo);
        return newTokenId;
    }
    function createListedToken(uint256 tokenId, string memory serialNo) private {
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            0,
            serialNo
        );

        _transfer(msg.sender, address(this), tokenId);
        emit TokenListedSuccess(tokenId, address(this), msg.sender, 0, true, 0, serialNo);
    }

    // function getAllNFTs() public view returns (ListedToken[] memory) {
    //     uint nftCount = _tokenIds.current();
    //     ListedToken[] memory tokens = new ListedToken[](nftCount);
    //     uint currentIndex = 0;

    //     //filter out currentlyListed == false over here
    //     for(uint i=0;i<nftCount;i++)
    //     {
    //         uint currentId = i + 1;
    //         ListedToken storage currentItem = idToListedToken[currentId];
    //         tokens[currentIndex] = currentItem;
    //         currentIndex += 1;
    //     }
    //     //the array 'tokens' has the list of all NFTs in the marketplace
    //     return tokens;
    // }
    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                idToListedToken[i + 1].owner == msg.sender ||
                idToListedToken[i + 1].seller == msg.sender
            ) {
                itemCount += 1;
            }
        }

        ListedToken[] memory items = new ListedToken[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                idToListedToken[i + 1].owner == msg.sender ||
                idToListedToken[i + 1].seller == msg.sender
            ) {
                uint256 currentId = i + 1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 tokenId, uint256 expTime) public payable {
        require(expTime > 0, "Please enter a valid expiry time");

        // uint price = idToListedToken[tokenId].price;
        // address seller = idToListedToken[tokenId].seller;

       
        if (idToListedToken[tokenId].expiry == 0) {
            idToListedToken[tokenId].expiry = block.timestamp + expTime;
        }

        // require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        // idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].seller = payable(msg.sender);

        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);

        approve(address(this), tokenId);
    }

    function BurnNFT(uint256 tokenId) public payable {
        require(idToListedToken[tokenId].expiry != 0, "warranty is yet to be issued");
        require(
            owner == msg.sender || idToListedToken[tokenId].seller == payable(msg.sender),
            "you need to own this warranty"
        );
        require(block.timestamp > idToListedToken[tokenId].expiry, "warranty is yet to expire");

        _burn(tokenId);
    }
}
