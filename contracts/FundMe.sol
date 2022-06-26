// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; // whoever deploys the contract becomes the owner
    }

    function fund() public payable 
    {
        // $50
        uint256 minimumUSD = 50 * 10**18; //msg value is in wei instead of ether which is 10^18 times smaller than eth, therefore everything needs to be multiplied by 10^18
        require(gerConversionRate(msg.value) >= minimumUSD, "More ETH motherfucker");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) 
    {
        uint256 minimumUSD = 50 * 10**18; //50 dolcow to je moje entrance fee
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price); // + 1;
    }

    function gerVersion() public view returns (uint256) 
    {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface( //these 3 lines will not work on ganache local blockchain because they are using interface from real blockchain
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e // we are using mock design pattern - we will use a fake interface (model) which we create by ourselves
        // );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) 
    {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface( //these 3 lines will not work on ganache local blockchain because they are using interface from real blockchain
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        
        return uint256(answer * 10000000000);
    }

    function gerConversionRate(uint256 ethAmount) public view returns (uint256)
    {
        uint256 ethPrice;
        uint256 ethPriceInUSD;
        ethPrice = getPrice();
        ethPriceInUSD = (ethPrice * ethAmount) / 100000000;

        return ethPriceInUSD;
    }

    modifier onlyOwner() 
    {
        require(msg.sender == owner, "You can't steal my money motherfucker!"); // this will be checked if a function has ownerOnly modifier, look at withdraw()
        _; // a function with onlyOwner modifier will be executed here if statement above is true
    }

    function withdraw() public payable onlyOwner 
    {
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++ ) 
        {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // przypisujemy tabeli funders wartosci z nowej (pustej) tabeli, w ten sposob resetujemy tabele funders
    }
}
