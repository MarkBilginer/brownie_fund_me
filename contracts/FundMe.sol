// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// Brownie cant directly import from npm, we will use github links and remapping
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

// we want this contract to be able to receive payment
contract FundMe {
    // we use SafeMathChainlink for our uint256. so no overflow happens.
    using SafeMathChainlink for uint256;

    //msg.sender & msg.value
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        // ever we add here will be immediatly executed when we deploy the contract.
        // the sender of this message will be us, whoever deploys this smart contract.
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // a function that can pay with ether
    //whenever we call fund, someboady can send a value because its payable
    // and we are going to save everything in this address to amount funded mapping
    function fund() public payable {
        // $50 we can check whether the value send is greater or less than
        uint256 minimumUSD = 50 * 10**18; // since we calculate all in gwei we raise to the power = 10^18
        //if(msg.value < minimumUSD) {
        //    revert
        //}
        // 1gwei < $50
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        //lets keep track of all the address which send us money, some value
        addressToAmountFunded[msg.sender] += msg.value;
        // what the ETH -> USD conversion rate is

        // for now we ignore the redundancy which occurs when the same funder funds more than one time.
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        //if its true the following line will be executed.
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // 0,000000001 Ether == 1 Gwei == 1000000000 Wei
    // 1 Ether == 1000000000 Gwei == 1000000000000000000 Wei
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; // cause both ethPrice and ethAmount have 10^18
        return ethAmountInUsd;
        //0.00000299392000000
        //0.00000299392000000*1000000000 Gwei == 2,993.92 USD Price of 1 ether at the time of calculation
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // the code of the modified function will come here automatically
    }

    function withdraw() public payable onlyOwner {
        //we want to send all the money that has been funded
        msg.sender.transfer(address(this).balance); // before execution of this line the modifier will be called

        // the loop will finish when funderIndex is greater or equal to array length
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex]; // we use funder address as a key in our mapping
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // we reset the funders array by assigning in a new blank address array
    }

    // my own function not included in the course
    //returning a stringyfied array would be more readerfriendly
    function display_funders() public view returns (address[] memory) {
        return funders;
    }
}
