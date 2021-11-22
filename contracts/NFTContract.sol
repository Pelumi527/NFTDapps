// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestGraffGremsEpisode1 is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public nftPerAddressLimit;
  mapping (address => bool) public whitelist;
  uint public reservedAmount;
  bool public paused; // default value == false
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  uint presaleStarttime;

  constructor() ERC721("--NameOfCollection--","--SymbolOfCollection--") {
    cost = 25 ether;
    maxSupply = 500;
    nftPerAddressLimit = 1; // limit for presale
    reservedAmount = 18; // giveaways + team
    setBaseURI("--prereveal uri--");
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(presaleStarttime>0, "presale has not started yet");
    require(!paused, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if ((block.timestamp - presaleStarttime) < 30 minutes ) {
      //presale is active - check for whitelist
      require(isWhitelisted(msg.sender),"You are not whitelisted | public sale starts 30 minutes after presale");
      require(addressMintedBalance[msg.sender] + _mintAmount <= nftPerAddressLimit, "Presale limit exceeded");
    }

    require(msg.value == cost * _mintAmount, "insufficient funds");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }


  function startPresale() external onlyOwner {
    require(presaleStarttime==0,"Cant start presale twice");
    for (uint256 i = 1; i <= reservedAmount; i++) {
      _safeMint(msg.sender,  i);
    }
    presaleStarttime = block.timestamp;
  }


  function isWhitelisted(address _user) public view returns (bool) {
    return whitelist[_user];
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );


    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }


  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }



  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function addToWhitelist(address[] calldata addresses) external onlyOwner {
    for (uint i=0;i<addresses.length;i++) {
      whitelist[addresses[i]]=true;
    }
  }

  function removeFromWhitelist(address[] calldata addresses) external onlyOwner {
    for (uint i=0;i<addresses.length;i++) {
      whitelist[addresses[i]]=false;
    }
  }

  function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}
