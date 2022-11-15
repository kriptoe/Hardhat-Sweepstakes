pragma solidity >=0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import './Base64.sol';

import './HexStrings.sol';

import "hardhat/console.sol";

//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract Predictoor is ERC721, Ownable {
   
/*   
    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }  */

  using Strings for uint256;
  using HexStrings for uint160;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  // TokenInfo[] public AllowedCrypto;  // holds tokens that can be used to pay  
  uint256 public prizepool;
  mapping(address => mapping(uint => uint256)) public betInfo;  // maps address to country  
  uint256[32] public countryTotals;      // keeps totals of bets on each pool
  uint8 public winner = 99;             // used to indicate pool is closed for claiming
  string[] public countryNames = ["Argentina", "Australia", "Belgium", "Brazil", "Cameroon", "Canada","Costa Rica","Croatia",
  "Denmark","Ecuador","England","France","Germany","Ghana","Iran","Japan","Korea Republic","Mexico","Morocco","Netherlands","Poland","Portugal","Qatar",
   "Saudi Arabia","Senegal","Serbia","Spain","Switzerland","Tunisia","Uruguay","USA","Wales"];

  bool public canClaim = false;
  uint256 public deadline = block.timestamp + 60 seconds; 
  mapping (uint256 => uint256) public betSize;
  mapping (uint256 => uint256) public country;  // maps country to mint id

  constructor() ERC721("Predictoor", "OOR") {
     winner = 0;
  }

/*
    function addCurrency(IERC20 _paytoken, uint256 _costvalue ) public {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    } */

/*
function changeTeam(uint8 _newTeam, uint8 _oldTeam, uint256 _amount, uint256 _mintID) public payable {
   require (getBalance(msg.sender, _oldTeam) > 0,"You have nothing to claim.");
   require(ownerOf(_mintID)==msg.sender, "You're not the owner of the supplied Bet ID" );
   betInfo[msg.sender][_oldTeam] =0;
   betInfo[msg.sender][_newTeam] =_amount;
   countryTotals[_newTeam] += _amount + countryTotals[_oldTeam];     
   countryTotals[_oldTeam] -= _amount;
   countryTotals[_newTeam] += _amount ;   
   country[_mintID] = _newTeam;  // change the country mapping to the new team
} */

  function mintItem(uint256 _country, uint256 _amount) public payable returns (uint256)
  {
     // require(deadline)
      _tokenIds.increment();
      uint256 id = _tokenIds.current();
      console.log("_country  ", _country); 
       console.log("_amount ", _amount);     
       console.log("Balance  ", balanceOf(msg.sender));          
      _mint(msg.sender, id);

      require (balanceOf(msg.sender)>=_amount, "You don't have enough Matic");            
       transferFrom(msg.sender, address(this), _amount);  // transfer money from better to the contract
      country[id] = _country;  // mint id is mapped to country, address is mapped to id
      betSize[id] = _amount;   // betsize is mapped to id
      setBalance( msg.sender, _country, _amount ); // set the balance for this address
      countryTotals[_country] += _amount;
      prizepool += _amount;
      return id;
  }

 
    function calculatePercentage (uint256 _amount, uint256 _top, uint256 _bottom) public pure returns (uint256){
        require (_bottom >0, "Can't divide by zero.");
         return _amount * 100000 * _top / _bottom / 100000; 
    }


  function claim() public payable returns (uint256)
  {
     require (winner != 99, "Claim period hasn't been activated");
     require (getBalance(msg.sender, winner) > 0,"You have nothing to claim.");
     console.log("prizepool ", prizepool);
     console.log("address amount ", getBalance(msg.sender, winner));
     console.log("country total ", countryTotals[winner]);      
     uint256 tempAmount = getBalance(msg.sender, winner);
     uint256 payout = calculatePercentage(prizepool, tempAmount, countryTotals[winner] );

     betInfo[msg.sender][winner] =0;             // update value of user address to 0
     countryTotals[winner] -= tempAmount;                       // update the country total
     prizepool -= payout ;                                    // update total prize pool - should be same as contract address balance 
     console.log ("payout : ", payout);
     console.log ("countrytotal ",countryTotals[winner]);

        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Failed to send balance");

     
  }

    // get the balance for the user address and country combination
     function getBalance(address _addr1, uint _countryID) public view returns (uint256) {
        return betInfo[_addr1][_countryID] ;
    }

   function getCountry(uint256 _betID) public view returns (uint256) {
       return country[_betID];
   }

    // adds the parameter to the current balance
    function setBalance( address _addr1, uint _countryID, uint256 _amount ) public {
        betInfo[_addr1][_countryID] += _amount;
    }

   function getID(address _addr1, uint _country) public returns (uint256){
    console.log ("Country ", _country);
    console.log ("mapping value ", betInfo[_addr1][_country]);    
     return betInfo[_addr1][_country];
   }

// sets the winning country  default value 99 indicates tournament hasnt finished
function setWinner(uint8 _country) public onlyOwner(){
  winner = _country;
}


  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory name = string(abi.encodePacked('Bet Number #',id.toString()));
      string memory description = string(abi.encodePacked('Predictoor: decentralised, gamified sports prediction. ID #', uint2str(id) ,' . Bet $',uint2str(betSize[id] / 1e18 )));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://burnyboys.com/token/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "country", "value": "#',
                              countryNames[country[id]],
                              '"},{"trait_type": "Bet size ", "value": ',
                              uint2str(betSize[id] / 1e18),
                              '}], "owner":"',
                              (uint160(ownerOf(id))).toHexString(20),
                              '", "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }



  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));
    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    string memory render = string(abi.encodePacked(
'<svg width="550" height="550">',
'<rect width="400" height="240" stroke="green" stroke-width="2" fill="#fff"></rect>',
'<text x="200" y="100" alignment-baseline="middle" font-size="30" stroke-width="0" stroke="#000" text-anchor="middle">',
countryNames[country[id]],
'</text><text x="200" y="145" style="font-size:25px;">',
' $',uint2str(betSize[id] / 1e18),
'</text><text x="100" y="40" style="font-size:30px;">'
' Predictoor ',
'</text><text x="100" y="65" style="font-size:16px;" stroke="blue">2022 FIFA World Cup Sweepstakes</text>',
'<text x="190" y="180" style="font-size:20px;">ID #',
uint2str(id),
'</text></svg>'
      ));

    return render;
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }

 // this function can be called by anyone, the winner has to have been set
 // function can onlybe called once
 // sends 2% of the losing pools money to the fee

   function execute() public payable returns(bool _result){

     require(canClaim==false, "This function can only be executed once.");
     require((winner >=0 && winner <= 31), "Winner hasn't been determined.");
     uint256 amount= calculatePercentage ( prizepool, 2, 100);
     prizepool = prizepool - amount;
     console.log("prizepool ", prizepool);
      console.log("amount ", amount);
     console.log("countryTotals ", countryTotals[winner]);

        (bool sent, ) = 0xE90Eee57653633E7558838b98F543079649c9C2F.call{value: amount}("");  // send 2% to fees wallet
        require(sent, "Failed to send balance");

 }
        function withdrawOwner() public payable onlyOwner{
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has no balance to withdraw");

        (bool sent, ) = msg.sender.call{value: ownerBalance}("");
        require(sent, "Failed to send balance");
        }

 function getWinner() public view returns(uint256){
     return winner;
 }
      receive() external payable{
       }

        // Fallback function must be declared as external.
    fallback() external payable {
        // send / transfer (forwards 2300 gas to this fallback function)
        // call (forwards all of the gas)
        emit Log("fallback", gasleft());
    }   
   event Log(string func, uint gas);  
}